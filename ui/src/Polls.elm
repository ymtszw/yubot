module Polls
    exposing
        ( Poll
        , Interval
        , Trigger
        , Condition
        , Material
        , Aux
        , Msg(..)
        , AuxMsg(..)
        , dummyPoll
        , dummyTrigger
        , isValid
        , populate
        , simpleMatchCondition
        , isSimpleMatch
        , functionalCondition
        , sampleFunctionalCondition
        , functionalMaterialItem
        , config
        , update
        , usedActionIds
        , usedAuthIds
        , intervalToString
        , intervals
        )

import Set exposing (Set)
import Dict exposing (Dict)
import Json.Decode as JD
import Json.Decode.Extra as JDE exposing ((|:))
import Json.Encode as JE
import Http
import HttpBuilder
import Utils
import Grasp
import Grasp.BooleanResponder as GBR exposing (BooleanResponder, booleanResponder)
import Grasp.StringResponder as GSR exposing (StringResponder, stringResponder)
import HttpTrial
import Repo exposing (Repo)
import Repo.Command exposing (Config)
import Repo.Messages
import Repo.Update


-- Model


type alias Poll =
    { url : Utils.Url
    , interval : Interval
    , authId : Maybe Repo.EntityId
    , isEnabled : Bool
    , triggers : List Trigger
    , lastRunAt : Maybe Utils.Timestamp -- Readonly
    , nextRunAt : Maybe Utils.Timestamp -- Readonly
    }


type alias Interval =
    String


type alias Trigger =
    { collapsed : Bool -- Client-side only; UI state
    , auditId : Repo.AuditId -- Client-side only
    , actionId : Repo.EntityId
    , conditions : List Condition
    , material : Material
    }


type alias Condition =
    Grasp.Instruction BooleanResponder


type alias Material =
    Dict String (Grasp.Instruction StringResponder)


type alias Aux =
    { shallowTrialResponse : Maybe HttpTrial.Response
    , triggerValidations : List TriggerValidation
    , fullTrialResponse : Maybe FullTrialResponse
    }


type alias TriggerValidation =
    {}


type alias FullTrialResponse =
    {}


dummyPoll : Poll
dummyPoll =
    Poll "https://example.com" "10" Nothing True [ dummyTrigger "newTrigger" "newCondition" ] Nothing Nothing


dummyTrigger : Repo.AuditId -> Repo.AuditId -> Trigger
dummyTrigger auditId1 auditId2 =
    Trigger True auditId1 "" [ simpleMatchCondition auditId2 "" ] Dict.empty


isValid : ( Repo.Entity Poll, Repo.Audit ) -> Bool
isValid ( { data }, audit ) =
    Repo.isValid audit
        && (data.url /= "")
        && (List.all isValidTrigger data.triggers)


isValidTrigger : Trigger -> Bool
isValidTrigger { actionId, conditions, material } =
    (actionId /= "")
        && (List.all (Grasp.isValidInstruction GBR.isValid) conditions)
        && (material |> Dict.values |> List.all (Grasp.isValidInstruction GSR.isValid))


populate : List (Repo.Entity Poll) -> Repo Aux Poll
populate entities =
    { dict = Repo.listToDict entities
    , sort = Repo.Sorter .id Repo.Asc
    , deleteModal = Repo.ModalState False (Repo.dummyEntity dummyPoll)
    , dirtyDict = Dict.empty
    , errors = []
    , shallowTrialResponse = Nothing
    , triggerValidations = []
    , fullTrialResponse = Nothing
    }


usedActionIds : Repo.EntityDict Poll -> Set Repo.EntityId
usedActionIds polls =
    polls
        |> Dict.values
        |> List.concatMap (.data >> .triggers >> (List.map .actionId))
        |> Set.fromList


usedAuthIds : Repo.EntityDict Poll -> Set Repo.EntityId
usedAuthIds polls =
    polls
        |> Dict.values
        |> List.map (.data >> .authId >> Maybe.withDefault "")
        |> Set.fromList


intervalToString : Interval -> String
intervalToString interval =
    case String.toInt interval of
        Ok _ ->
            "every " ++ interval ++ " min."

        Err _ ->
            interval


intervals : List Interval
intervals =
    [ "1", "3", "10", "30", "hourly", "daily" ]



-- Grasp templates


simpleMatchCondition : Repo.AuditId -> Grasp.Pattern -> Condition
simpleMatchCondition auditId patternStr =
    { auditId = auditId
    , extractor = Grasp.regexExtractor patternStr
    , responder = booleanResponder GBR.First GBR.Truth []
    }


isSimpleMatch : Grasp.Instruction BooleanResponder -> Bool
isSimpleMatch { responder } =
    responder.highOrder == GBR.First && responder.firstOrder.operator == GBR.Truth


functionalCondition : Repo.AuditId -> Grasp.Pattern -> GBR.HighOrder -> GBR.Predicate -> List String -> Condition
functionalCondition auditId patternStr ho op args =
    { auditId = auditId
    , extractor = Grasp.regexExtractor patternStr
    , responder = booleanResponder ho op args
    }


sampleFunctionalCondition : Repo.AuditId -> Grasp.Pattern -> Condition
sampleFunctionalCondition auditId patternStr =
    functionalCondition auditId patternStr GBR.First GBR.EqAt [ "1", "true" ]


functionalMaterialItem :
    Repo.AuditId
    -> Grasp.Pattern
    -> GSR.HighOrder
    -> GSR.StringMaker
    -> List String
    -> Grasp.Instruction StringResponder
functionalMaterialItem auditId patternStr ho op args =
    { auditId = auditId
    , extractor = Grasp.regexExtractor patternStr
    , responder = stringResponder ho op args
    }



-- Config


config : Config Poll
config =
    Config "/api/poll" "/polls" dataDecoder dataEncoder (always "/polls")


dataDecoder : JD.Decoder Poll
dataDecoder =
    JD.succeed Poll
        |: (JD.field "url" JD.string)
        |: (JD.field "interval" JD.string)
        |: (JD.field "auth_id" (JD.maybe JD.string))
        |: (JD.field "is_enabled" decodeIsEnabled)
        |: (JD.field "triggers" (JDE.indexedList decodeTrigger))
        |: (JD.field "last_run_at" (JD.maybe JD.string))
        |: (JD.field "next_run_at" (JD.maybe JD.string))


decodeIsEnabled : JD.Decoder Bool
decodeIsEnabled =
    JD.bool
        |> JD.maybe
        |> JD.map (Maybe.withDefault False)


decodeTrigger : Int -> JD.Decoder Trigger
decodeTrigger index =
    JD.succeed (Trigger True ("trigger" ++ toString index))
        |: (JD.field "action_id" JD.string)
        |: (JD.field "conditions" (JDE.indexedList (Grasp.decodeInstruction GBR.stringToHo GBR.stringToOp "condition")))
        |: (JD.field "material" (JD.dict (Grasp.decodeInstruction GSR.stringToHo GSR.stringToOp "material" 0)))


dataEncoder : Poll -> JE.Value
dataEncoder { url, interval, authId, isEnabled, triggers, lastRunAt, nextRunAt } =
    JE.object
        [ ( "url", JE.string url )
        , ( "interval", JE.string interval )
        , ( "auth_id", Utils.encodeMaybe JE.string authId )
        , ( "is_enabled", JE.bool isEnabled )
        , ( "triggers", JE.list <| List.map encodeTrigger <| triggers )
        , ( "last_run_at", Utils.encodeMaybe JE.string lastRunAt )
        , ( "next_run_at", Utils.encodeMaybe JE.string nextRunAt )
        ]


encodeTrigger : Trigger -> JE.Value
encodeTrigger { actionId, conditions, material } =
    JE.object
        [ ( "action_id", JE.string actionId )
        , ( "conditions", JE.list <| List.map Grasp.encodeInstruction <| conditions )
        , ( "material", encodeMaterial material )
        ]


encodeMaterial : Material -> JE.Value
encodeMaterial material =
    material
        |> Dict.map (\_ v -> Grasp.encodeInstruction v)
        |> Dict.toList
        |> JE.object



-- Messages


type Msg
    = RepoMsg (Repo.Messages.Msg Poll)
    | AuxMsg AuxMsg


type AuxMsg
    = ShallowTry Poll
    | OnShallowTry (Result Http.Error HttpTrial.Response)
    | PromptLogin
    | Clear
    | NoOp



-- Update


update : Msg -> Repo Aux Poll -> ( Repo Aux Poll, Cmd Msg, Repo.Update.StackCmd )
update msg repo =
    let
        map msgMapper ( repo, cmd, stackCmd ) =
            ( repo, Cmd.map msgMapper cmd, stackCmd )
    in
        case msg of
            RepoMsg repoMsg ->
                repo |> Repo.Update.update dummyPoll config repoMsg |> map RepoMsg

            AuxMsg trialMsg ->
                repo |> updateTrial trialMsg |> map AuxMsg


updateTrial : AuxMsg -> Repo Aux Poll -> ( Repo Aux Poll, Cmd AuxMsg, Repo.Update.StackCmd )
updateTrial msg repo =
    case msg of
        ShallowTry data ->
            ( repo, shallowTry data, Repo.Update.Push )

        OnShallowTry (Ok response) ->
            ( { repo | shallowTrialResponse = Just response }, Cmd.none, Repo.Update.Pop )

        OnShallowTry (Err httpError) ->
            Repo.Update.onHttpError PromptLogin repo httpError

        Clear ->
            ( { repo | shallowTrialResponse = Nothing }, Cmd.none, Repo.Update.Keep )

        _ ->
            ( repo, Cmd.none, Repo.Update.Keep )


shallowTry : Poll -> Cmd AuxMsg
shallowTry data =
    HttpBuilder.post (config.repoPath ++ "/shallow_try")
        |> HttpBuilder.withJsonBody (shallowTryRequestEncoder data)
        |> HttpBuilder.withExpect (Http.expectJson HttpTrial.responseDecoder)
        |> HttpBuilder.send OnShallowTry


shallowTryRequestEncoder : Poll -> JE.Value
shallowTryRequestEncoder { url, authId } =
    JE.object
        [ ( "url", JE.string url )
        , ( "auth_id", Utils.encodeMaybe JE.string authId )
        ]
