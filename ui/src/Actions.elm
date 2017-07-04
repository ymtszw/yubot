module Actions
    exposing
        ( Action
        , Label
        , ActionType(..)
        , Aux
        , TrialValues
        , Msg(..)
        , TrialMsg(..)
        , IndexMsg(..)
        , dummyAction
        , populate
        , isValid
        , usedAuthIds
        , stringToType
        , typeToLogo
        , typeToFa
        , trialReady
        , config
        , update
        )

import Dict exposing (Dict)
import Set exposing (Set)
import Json.Decode as Decode
import Json.Encode as Encode
import Http
import HttpBuilder exposing (RequestBuilder)
import ListSet exposing (ListSet)
import Utils exposing (Method(..))
import HttpTrial
import Repo exposing (Repo)
import Repo.Command exposing (Config)
import Repo.Messages
import Repo.Update
import StringTemplate exposing (StringTemplate)
import Assets


-- Model


type alias Label =
    String


type ActionType
    = Hipchat
    | Http


type alias Action =
    { label : Label
    , method : Method
    , url : Utils.Url
    , authId : Maybe Repo.EntityId
    , bodyTemplate : StringTemplate
    , type_ : ActionType
    }


type alias TrialValues =
    Dict String String


type alias Aux =
    { trialValues : TrialValues
    , trialResponse : Maybe HttpTrial.Response
    , indexFilter : ListSet ActionType
    }


dummyAction : Action
dummyAction =
    Action "http action" POST "https://example.com" Nothing (StringTemplate "" []) Http


populate : List (Repo.Entity Action) -> Repo Aux Action
populate entities =
    { dict = Repo.listToDict entities
    , sort = Repo.Sorter .id Repo.Asc
    , deleteModal = Repo.ModalState False (Repo.dummyEntity dummyAction)
    , dirtyDict = Dict.empty
    , errors = []
    , trialValues = Dict.empty
    , trialResponse = Nothing
    , indexFilter = []
    }


isValid : ( Repo.Entity Action, Repo.Audit ) -> Bool
isValid ( { data }, audit ) =
    Repo.isValid audit && data.label /= "" && data.url /= "" && StringTemplate.isValid data.bodyTemplate


usedAuthIds : Repo.EntityDict Action -> Set Repo.EntityId
usedAuthIds actions =
    actions
        |> Dict.values
        |> List.map (.data >> .authId >> Maybe.withDefault "")
        |> Set.fromList


stringToType : String -> ActionType
stringToType string =
    case string of
        "hipchat" ->
            Hipchat

        _ ->
            -- "http"
            Http


typeToLogo : Bool -> ActionType -> Utils.Url
typeToLogo isDev type_ =
    case type_ of
        Http ->
            Assets.url isDev "img/link_40.png"

        Hipchat ->
            Assets.url isDev "img/hipchat_square_40.png"


typeToFa : ActionType -> String
typeToFa type_ =
    case type_ of
        Http ->
            "fa-link"

        Hipchat ->
            "fa-weixin"


trialReady : List String -> TrialValues -> Bool
trialReady variables trialValues =
    let
        nonEmpty variable =
            trialValues |> Utils.dictGetWithDefault variable "" |> not << String.isEmpty
    in
        List.all nonEmpty variables



-- Config


config : Config Action
config =
    Config "/api/action" "/actions" dataDecoder dataEncoder ((++) "/actions/" << .id)


dataDecoder : Decode.Decoder Action
dataDecoder =
    Decode.map6 Action
        (Decode.field "label" Decode.string)
        (Decode.field "method" (Decode.map Utils.stringToMethod Decode.string))
        (Decode.field "url" Decode.string)
        (Decode.field "auth_id" (Decode.maybe Decode.string))
        (Decode.field "body_template" bodyTemplateDecoder)
        (Decode.field "type" (Decode.map stringToType Decode.string))


bodyTemplateDecoder : Decode.Decoder StringTemplate
bodyTemplateDecoder =
    Decode.map2 StringTemplate
        (Decode.field "body" Decode.string)
        (Decode.field "variables" (Decode.list Decode.string))


dataEncoder : Action -> Encode.Value
dataEncoder { label, method, url, authId, bodyTemplate, type_ } =
    Encode.object
        [ ( "label", Encode.string label )
        , ( "method", Encode.string (Utils.toLowerString method) )
        , ( "url", Encode.string url )
        , ( "auth_id", Utils.encodeMaybe Encode.string authId )
        , ( "body_template", bodyTemplateEncoder bodyTemplate )
        , ( "type", Encode.string (Utils.toLowerString type_) )
        ]


bodyTemplateEncoder : StringTemplate -> Encode.Value
bodyTemplateEncoder { body, variables } =
    Encode.object
        [ ( "body", Encode.string body )
        , ( "variables", variables |> List.map Encode.string |> Encode.list )
        ]



-- Messages


type Msg
    = RepoMsg (Repo.Messages.Msg Action)
    | Trial TrialMsg
    | Index IndexMsg


type TrialMsg
    = OnTrialEdit String String
    | Try Action TrialValues
    | OnResponse (Result Http.Error HttpTrial.Response)
    | PromptLogin
    | Clear
    | NoOp


type IndexMsg
    = Filter ActionType



-- Update


update : Msg -> Repo Aux Action -> ( Repo Aux Action, Cmd Msg, Repo.Update.StackCmd )
update msg repo =
    let
        map msgMapper ( repo, cmd, stackCmd ) =
            ( repo, Cmd.map msgMapper cmd, stackCmd )
    in
        case msg of
            RepoMsg repoMsg ->
                repo |> Repo.Update.update dummyAction config repoMsg |> map RepoMsg

            Trial trialMsg ->
                repo |> updateTrial trialMsg |> map Trial

            Index indexMsg ->
                repo |> updateIndex indexMsg |> map Index


updateTrial : TrialMsg -> Repo Aux Action -> ( Repo Aux Action, Cmd TrialMsg, Repo.Update.StackCmd )
updateTrial msg ({ trialValues } as repo) =
    case msg of
        OnTrialEdit variable value ->
            ( { repo | trialValues = Dict.insert variable value trialValues }, Cmd.none, Repo.Update.Keep )

        Try data trialValues ->
            ( repo, tryAction data trialValues, Repo.Update.Push )

        OnResponse (Ok response) ->
            ( { repo | trialResponse = Just response }, Cmd.none, Repo.Update.Pop )

        OnResponse (Err httpError) ->
            Repo.Update.onHttpError PromptLogin repo httpError

        Clear ->
            ( { repo | trialValues = Dict.empty, trialResponse = Nothing }, Cmd.none, Repo.Update.Keep )

        _ ->
            ( repo, Cmd.none, Repo.Update.Keep )


tryAction : Action -> TrialValues -> Cmd TrialMsg
tryAction data trialValues =
    HttpBuilder.post (config.repoPath ++ "/try")
        |> HttpBuilder.withJsonBody (trialRequestEncoder data trialValues)
        |> HttpBuilder.withExpect (Http.expectJson HttpTrial.responseDecoder)
        |> HttpBuilder.send OnResponse


trialRequestEncoder : Action -> TrialValues -> Encode.Value
trialRequestEncoder data trialValues =
    Encode.object
        [ ( "data", dataEncoder data )
        , ( "trial_values", trialValues |> Dict.toList |> List.map (Tuple.mapSecond Encode.string) |> Encode.object )
        ]


updateIndex : IndexMsg -> Repo Aux Action -> ( Repo Aux Action, Cmd IndexMsg, Repo.Update.StackCmd )
updateIndex msg ({ indexFilter } as repo) =
    case msg of
        Filter actionType ->
            ( { repo | indexFilter = ListSet.toggle actionType indexFilter }, Cmd.none, Repo.Update.Keep )
