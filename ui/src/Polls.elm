module Polls
    exposing
        ( Poll
        , Interval
        , Trigger
        , Condition
        , Material
        , HistoryEntry
        , PollResult
        , TriggerResult
        , Aux
        , Msg(..)
        , AuxMsg(..)
        , dummyPoll
        , dummyTrigger
        , isValid
        , hasDiff
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
import Json.Encode.Extra as JEE
import Task exposing (Task)
import Http
import HttpBuilder
import List.Extra as LE
import Maybe.Extra as ME
import Utils
import Grasp
import Grasp.BooleanResponder as GBR exposing (BooleanResponder, booleanResponder)
import Grasp.StringResponder as GSR exposing (StringResponder, stringResponder)
import HttpTrial
import Repo exposing (Repo)
import Repo.Command exposing (Config)
import Repo.Messages
import Repo.Update exposing (StackCmd(..))


-- Model


type alias Poll =
    { url : Utils.Url
    , interval : Interval
    , authId : Maybe Repo.EntityId
    , isEnabled : Bool
    , triggers : List Trigger

    -- Readonly below; updates to these fields will be stripped by server
    , lastRunAt : Maybe Utils.Timestamp
    , nextRunAt : Maybe Utils.Timestamp
    , history : List HistoryEntry
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
    { pollTrialResponse : Maybe HttpTrial.Response
    , pollTrialResponseCollapsed : Bool
    , conditionTestResult : Maybe Grasp.TestResult
    , materialTestResult : Maybe ( String, Grasp.TestResult )
    , runResult : Maybe HistoryEntry
    }


type alias HistoryEntry =
    { collapsed : Bool -- Client-side only; UI state
    , runAt : Utils.Timestamp
    , pollResult : PollResult
    , triggerResult : Maybe TriggerResult
    }


type alias PollResult =
    { status : Int
    , bodyHash : String
    }


type alias TriggerResult =
    { actionId : Repo.EntityId
    , status : Int
    , variables : Dict String String
    }


dummyPoll : Poll
dummyPoll =
    Poll "https://example.com" "10" Nothing True [ dummyTrigger "newTrigger" "newCondition" ] Nothing Nothing []


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


hasDiff : Poll -> Poll -> Bool
hasDiff poll1 poll2 =
    (editableRootFields poll1 /= editableRootFields poll2)
        || (List.length poll1.triggers /= List.length poll2.triggers)
        || (List.any identity (List.map2 triggerHasDiff poll1.triggers poll2.triggers))


editableRootFields :
    Poll
    ->
        { url : Utils.Url
        , interval : Interval
        , authId : Maybe Repo.EntityId
        , isEnabled : Bool
        }
editableRootFields { url, interval, authId, isEnabled } =
    { url = url, interval = interval, authId = authId, isEnabled = isEnabled }


triggerHasDiff : Trigger -> Trigger -> Bool
triggerHasDiff t1 t2 =
    (editableTriggerFields t1 /= editableTriggerFields t2)
        || (List.length t1.conditions /= List.length t2.conditions)
        || (List.any identity (List.map2 (/=) t1.conditions t2.conditions))


editableTriggerFields : Trigger -> { actionId : Repo.EntityId, material : Material }
editableTriggerFields { actionId, material } =
    { actionId = actionId, material = material }


populate : List (Repo.Entity Poll) -> Repo Aux Poll
populate entities =
    { dict = Repo.listToDict entities
    , sort = Repo.Sorter .id Repo.Asc
    , deleteModal = Repo.ModalState False (Repo.dummyEntity dummyPoll)
    , dirtyDict = Dict.empty
    , errors = []
    , pollTrialResponse = Nothing
    , pollTrialResponseCollapsed = False
    , conditionTestResult = Nothing
    , materialTestResult = Nothing
    , runResult = Nothing
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


toggleHistoryEntry : Int -> Bool -> Repo.Entity Poll -> Repo.Entity Poll
toggleHistoryEntry index collapsed ({ data } as poll) =
    { poll | data = { data | history = data.history |> LE.updateIfIndex ((==) index) (\e -> { e | collapsed = collapsed }) } }



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
        |: JD.field "url" JD.string
        |: JD.field "interval" JD.string
        |: JD.field "auth_id" (JD.maybe JD.string)
        |: JD.field "is_enabled" decodeIsEnabled
        |: JD.field "triggers" (JDE.indexedList decodeTrigger)
        |: JD.field "last_run_at" (JD.maybe JD.string)
        |: JD.field "next_run_at" (JD.maybe JD.string)
        |: JD.field "history" (JD.list decodeHistoryEntry)


decodeIsEnabled : JD.Decoder Bool
decodeIsEnabled =
    JD.bool
        |> JD.maybe
        |> JD.map (Maybe.withDefault False)


decodeTrigger : Int -> JD.Decoder Trigger
decodeTrigger index =
    JD.succeed (Trigger True ("trigger" ++ toString index))
        |: JD.field "action_id" JD.string
        |: JD.field "conditions" (JDE.indexedList (Grasp.decodeInstruction GBR.stringToHo GBR.stringToOp "condition"))
        |: JD.field "material" (JD.dict (Grasp.decodeInstruction GSR.stringToHo GSR.stringToOp "material" 0))


decodeHistoryEntry : JD.Decoder HistoryEntry
decodeHistoryEntry =
    JD.succeed (HistoryEntry True)
        |: JD.field "run_at" JD.string
        |: JD.field "poll_result"
            (JD.succeed PollResult
                |: JD.field "status" JD.int
                |: JD.field "body_hash" JD.string
            )
        |: JD.field "trigger_result" (JD.maybe decodeTriggerResult)


decodeTriggerResult : JD.Decoder TriggerResult
decodeTriggerResult =
    JD.succeed TriggerResult
        |: JD.field "action_id" JD.string
        |: JD.field "status" JD.int
        |: JD.field "variables" (JD.dict JD.string)


dataEncoder : Poll -> JE.Value
dataEncoder { url, interval, authId, isEnabled, triggers, lastRunAt, nextRunAt } =
    JE.object
        [ ( "url", JE.string url )
        , ( "interval", JE.string interval )
        , ( "auth_id", JEE.maybe JE.string authId )
        , ( "is_enabled", JE.bool isEnabled )
        , ( "triggers", JE.list <| List.map encodeTrigger <| triggers )
        , ( "last_run_at", JEE.maybe JE.string lastRunAt )
        , ( "next_run_at", JEE.maybe JE.string nextRunAt )
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
    = TryPoll Poll
    | OnTryPoll (Result Http.Error HttpTrial.Response)
    | ToggleTryPollResult Bool
    | TestCondition Poll Condition
    | OnTestCondition (Result Http.Error ( HttpTrial.Response, Grasp.TestResult ))
    | TestMaterial Poll String (Grasp.Instruction StringResponder)
    | OnTestMaterial String (Result Http.Error ( HttpTrial.Response, Grasp.TestResult ))
    | RunPoll Poll
    | OnRunPoll (Result Http.Error HistoryEntry)
    | ToggleHistoryEntry Repo.EntityId Int Bool
    | Clear
    | PromptLogin
    | NoOp



-- Update


update : Msg -> Repo Aux Poll -> ( Repo Aux Poll, Cmd Msg, StackCmd )
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


updateTrial : AuxMsg -> Repo Aux Poll -> ( Repo Aux Poll, Cmd AuxMsg, StackCmd )
updateTrial msg ({ dict, pollTrialResponse } as repo) =
    case msg of
        TryPoll data ->
            ( repo, Task.attempt OnTryPoll <| tryPollTask <| data, Push )

        OnTryPoll (Ok response) ->
            ( { repo | pollTrialResponse = Just response, pollTrialResponseCollapsed = False }, Cmd.none, Pop )

        OnTryPoll (Err httpError) ->
            Repo.Update.onHttpError PromptLogin repo httpError

        ToggleTryPollResult bool ->
            ( { repo | pollTrialResponseCollapsed = bool }, Cmd.none, Keep )

        TestCondition data c ->
            ( repo, tryGraspWithTryPollIfRequired OnTestCondition pollTrialResponse data c, Push )

        OnTestCondition (Ok ( response, result )) ->
            ( { repo
                | conditionTestResult = Just result
                , pollTrialResponse = pollTrialResponse |> ME.orElse (Just response)
                , pollTrialResponseCollapsed = True
              }
            , Cmd.none
            , Pop
            )

        OnTestCondition (Err httpError) ->
            Repo.Update.onHttpError PromptLogin repo httpError

        TestMaterial data variable m ->
            ( repo, tryGraspWithTryPollIfRequired (OnTestMaterial variable) pollTrialResponse data m, Push )

        OnTestMaterial variable (Ok ( response, result )) ->
            ( { repo
                | materialTestResult = Just ( variable, result )
                , pollTrialResponse = pollTrialResponse |> ME.orElse (Just response)
                , pollTrialResponseCollapsed = True
              }
            , Cmd.none
            , Pop
            )

        OnTestMaterial _ (Err httpError) ->
            Repo.Update.onHttpError PromptLogin repo httpError

        RunPoll data ->
            ( repo, runPoll data, Push )

        OnRunPoll (Ok result) ->
            ( { repo | runResult = Just result }, Cmd.none, Pop )

        OnRunPoll (Err httpError) ->
            Repo.Update.onHttpError PromptLogin repo httpError

        ToggleHistoryEntry id index collapsed ->
            ( { repo | dict = Dict.update id (Maybe.map (toggleHistoryEntry index collapsed)) dict }, Cmd.none, Keep )

        Clear ->
            ( { repo
                | pollTrialResponse = Nothing
                , conditionTestResult = Nothing
                , materialTestResult = Nothing
                , runResult = Nothing
              }
            , Cmd.none
            , Keep
            )

        PromptLogin ->
            -- Handled by root update
            ( repo, Cmd.none, Keep )

        NoOp ->
            ( repo, Cmd.none, Keep )


tryPollTask : Poll -> Task Http.Error HttpTrial.Response
tryPollTask data =
    HttpBuilder.post (config.repoPath ++ "/try")
        |> HttpBuilder.withJsonBody (tryPollRequestEncoder data)
        |> HttpBuilder.withExpect (Http.expectJson HttpTrial.responseDecoder)
        |> HttpBuilder.toTask


tryPollRequestEncoder : Poll -> JE.Value
tryPollRequestEncoder { url, authId } =
    JE.object
        [ ( "url", JE.string url )
        , ( "auth_id", JEE.maybe JE.string authId )
        ]


tryGraspWithTryPollIfRequired :
    (Result Http.Error ( HttpTrial.Response, Grasp.TestResult ) -> AuxMsg)
    -> Maybe HttpTrial.Response
    -> Poll
    -> Grasp.Instruction (Grasp.Responder ho op)
    -> Cmd AuxMsg
tryGraspWithTryPollIfRequired msg ptr data instruction =
    ptr
        |> ME.unwrap (tryPollTask data) Task.succeed
        |> Task.andThen (\htr -> htr.body |> Grasp.tryTask instruction |> Task.map (\gtr -> ( htr, gtr )))
        |> Task.attempt msg


runPoll : Poll -> Cmd AuxMsg
runPoll data =
    HttpBuilder.post (config.repoPath ++ "/run")
        |> HttpBuilder.withJsonBody (dataEncoder data)
        |> HttpBuilder.withExpect (Http.expectJson decodeHistoryEntry)
        |> HttpBuilder.send OnRunPoll
