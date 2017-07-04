module Polls
    exposing
        ( Poll
        , Interval
        , Trigger
        , Material
        , Aux
        , Msg(..)
        , TrialMsg(..)
        , dummyPoll
        , populate
        , config
        , update
        , usedActionIds
        , usedAuthIds
        , intervalToString
        )

import Set exposing (Set)
import Dict exposing (Dict)
import Json.Decode as Decode
import Json.Encode as Encode
import Http
import HttpBuilder
import Utils
import Grasp
import Grasp.BooleanResponder as GBR exposing (BooleanResponder)
import Grasp.StringResponder as GSR exposing (StringResponder)
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
    }


type alias Interval =
    String


type alias Trigger =
    { actionId : Repo.EntityId
    , conditions : List (Grasp.Instruction BooleanResponder)
    , material : Material
    }


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
    -- Make it default isEnabled: True later
    Poll "https://example.com" "10" Nothing False []


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



-- Config


config : Config Poll
config =
    Config "/api/poll" "/polls" dataDecoder dataEncoder (always "/polls")


dataDecoder : Decode.Decoder Poll
dataDecoder =
    Decode.map5 Poll
        (Decode.field "url" Decode.string)
        (Decode.field "interval" Decode.string)
        (Decode.field "auth_id" (Decode.maybe Decode.string))
        (Decode.field "is_enabled" decodeIsEnabled)
        (Decode.field "triggers" (Decode.list decodeTrigger))


decodeIsEnabled : Decode.Decoder Bool
decodeIsEnabled =
    Decode.bool
        |> Decode.maybe
        |> Decode.map (Maybe.withDefault False)


decodeTrigger : Decode.Decoder Trigger
decodeTrigger =
    Decode.map3 Trigger
        (Decode.field "action_id" Decode.string)
        (Decode.field "conditions" (Decode.list (Grasp.decodeInstruction GBR.stringToHo GBR.stringToOp)))
        (Decode.field "material" (Decode.dict (Grasp.decodeInstruction GSR.stringToHo GSR.stringToOp)))


dataEncoder : Poll -> Encode.Value
dataEncoder { url, interval, authId, isEnabled, triggers } =
    Encode.object
        [ ( "url", Encode.string url )
        , ( "interval", Encode.string interval )
        , ( "auth_id", Utils.encodeMaybe Encode.string authId )
        , ( "is_enabled", Encode.bool isEnabled )
        , ( "triggers", Encode.list <| List.map encodeTrigger <| triggers )
        ]


encodeTrigger : Trigger -> Encode.Value
encodeTrigger { actionId, conditions, material } =
    Encode.object
        [ ( "action_id", Encode.string actionId )
        , ( "conditions", Encode.list <| List.map Grasp.encodeInstruction <| conditions )
        , ( "material", encodeMaterial material )
        ]


encodeMaterial : Material -> Encode.Value
encodeMaterial material =
    material
        |> Dict.map (\_ v -> Grasp.encodeInstruction v)
        |> Dict.toList
        |> Encode.object



-- Messages


type Msg
    = RepoMsg (Repo.Messages.Msg Poll)
    | Trial TrialMsg


type TrialMsg
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

            Trial trialMsg ->
                repo |> updateTrial trialMsg |> map Trial


updateTrial : TrialMsg -> Repo Aux Poll -> ( Repo Aux Poll, Cmd TrialMsg, Repo.Update.StackCmd )
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


shallowTry : Poll -> Cmd TrialMsg
shallowTry data =
    HttpBuilder.post (config.repoPath ++ "/shallow_try")
        |> HttpBuilder.withJsonBody (shallowTryRequestEncoder data)
        |> HttpBuilder.withExpect (Http.expectJson HttpTrial.responseDecoder)
        |> HttpBuilder.send OnShallowTry


shallowTryRequestEncoder : Poll -> Encode.Value
shallowTryRequestEncoder { url, authId } =
    Encode.object
        [ ( "url", Encode.string url )
        , ( "auth_id", Utils.encodeMaybe Encode.string authId )
        ]
