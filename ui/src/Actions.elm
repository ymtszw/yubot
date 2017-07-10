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
import Json.Decode as JD
import Json.Decode.Extra as JDE exposing ((|:))
import Json.Encode as JE
import Json.Encode.Extra as JEE
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


dataDecoder : JD.Decoder Action
dataDecoder =
    JD.succeed Action
        |: (JD.field "label" JD.string)
        |: (JD.field "method" (JD.map Utils.stringToMethod JD.string))
        |: (JD.field "url" JD.string)
        |: (JD.field "auth_id" (JD.maybe JD.string))
        |: (JD.field "body_template" bodyTemplateDecoder)
        |: (JD.field "type" (JD.map stringToType JD.string))


bodyTemplateDecoder : JD.Decoder StringTemplate
bodyTemplateDecoder =
    JD.map2 StringTemplate
        (JD.field "body" JD.string)
        (JD.field "variables" (JD.list JD.string))


dataEncoder : Action -> JE.Value
dataEncoder { label, method, url, authId, bodyTemplate, type_ } =
    JE.object
        [ ( "label", JE.string label )
        , ( "method", JE.string (Utils.toLowerString method) )
        , ( "url", JE.string url )
        , ( "auth_id", JEE.maybe JE.string authId )
        , ( "body_template", bodyTemplateEncoder bodyTemplate )
        , ( "type", JE.string (Utils.toLowerString type_) )
        ]


bodyTemplateEncoder : StringTemplate -> JE.Value
bodyTemplateEncoder { body, variables } =
    JE.object
        [ ( "body", JE.string body )
        , ( "variables", variables |> List.map JE.string |> JE.list )
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


trialRequestEncoder : Action -> TrialValues -> JE.Value
trialRequestEncoder data trialValues =
    JE.object
        [ ( "data", dataEncoder data )
        , ( "trial_values", trialValues |> Dict.toList |> List.map (Tuple.mapSecond JE.string) |> JE.object )
        ]


updateIndex : IndexMsg -> Repo Aux Action -> ( Repo Aux Action, Cmd IndexMsg, Repo.Update.StackCmd )
updateIndex msg ({ indexFilter } as repo) =
    case msg of
        Filter actionType ->
            ( { repo | indexFilter = ListSet.toggle actionType indexFilter }, Cmd.none, Repo.Update.Keep )
