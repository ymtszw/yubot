module Actions.Hipchat
    exposing
        ( Color(..)
        , MessageTemplate
        , UserParams
        , colors
        , stringToColor
        , validateMessageTemplate
        , isValid
        , default
        , roomIdToUrl
        , applyParams
        , fetchParams
        , fetchMessageTemplateFromBody
        )

import Regex
import Utils
import StringTemplate exposing (StringTemplate)
import Repo
import Actions exposing (Action)


type Color
    = Yellow
    | Green
    | Red
    | Purple
    | Gray


type alias MessageTemplate =
    String


type alias RoomId =
    String


type alias UserParams =
    { label : Actions.Label
    , authId : Maybe Repo.EntityId
    , roomId : RoomId
    , color : Color
    , notify : Bool
    , messageTemplate : MessageTemplate
    }


colors : List Color
colors =
    [ Yellow, Green, Red, Purple, Gray ]


stringToColor : String -> Color
stringToColor string =
    case string of
        "yellow" ->
            Yellow

        "green" ->
            Green

        "red" ->
            Red

        "purple" ->
            Purple

        _ ->
            Gray


validateMessageTemplate : MessageTemplate -> Result String MessageTemplate
validateMessageTemplate string =
    let
        newlineEscapedString =
            string |> String.lines |> String.join "\\\\\n"

        assertProperlyEscaped =
            newlineEscapedString
                |> Regex.replace Regex.All (Regex.regex "\\\\[\\\"\\\\]") (always "R")
                |> (not << Regex.contains (Regex.regex "[\\\"\\\\]"))
    in
        if assertProperlyEscaped then
            Ok newlineEscapedString
        else
            Err "You must properly escape special charactors like \" or \\"


isValid : ( Repo.Entity Action, Repo.Audit ) -> Bool
isValid (( { data }, audit ) as dirtyEntity) =
    let
        { authId, roomId } =
            fetchParams data
    in
        Actions.isValid dirtyEntity && Utils.isJust authId && roomId /= ""


default : Action
default =
    let
        bodyTemplate =
            bodyBase
                |> StringTemplate.render "color" "yellow"
                |> StringTemplate.render "notify" "false"
                |> flip StringTemplate [ "message" ]
    in
        Action "hipchat action" Utils.POST (roomIdToUrl "") Nothing bodyTemplate Actions.Hipchat


{-| Apply new UserParams to `data`, validating MessageTemplate on the way.
Even if the template is invalidated, it returns new BodyTemplate with invalid `body` inserted.
-}
applyParams : Action -> UserParams -> Result ( String, Action ) Action
applyParams ({ bodyTemplate } as data) { label, authId, roomId, color, notify, messageTemplate } =
    let
        body =
            bodyBase
                |> StringTemplate.render "color" (Utils.toLowerString color)
                |> StringTemplate.render "notify" (Utils.toLowerString notify)
                |> StringTemplate.render "message" messageTemplate

        action newBodyTemplate =
            { data
                | label = label
                , method = Utils.POST
                , url = roomIdToUrl roomId
                , authId = authId
                , bodyTemplate = newBodyTemplate
                , type_ = Actions.Hipchat
            }
    in
        case validateMessageTemplate messageTemplate of
            Ok _ ->
                body
                    |> StringTemplate.validate
                    |> Result.map (action << StringTemplate body)
                    |> Result.mapError (\e -> ( e, action { bodyTemplate | body = body } ))

            Err error ->
                Err ( error, action { bodyTemplate | body = body } )


fetchParams : Action -> UserParams
fetchParams { label, authId, url, bodyTemplate } =
    let
        roomId =
            url |> String.dropLeft 32 |> String.dropRight 13

        color =
            fetchValueFromBody
                stringToColor
                "\"color\":\"(yellow|green|red|purple|gray)\""
                bodyTemplate.body

        notify =
            fetchValueFromBody
                Utils.stringToBool
                "\"notify\":(true|false)"
                bodyTemplate.body

        messageTemplate =
            fetchMessageTemplateFromBody bodyTemplate.body
    in
        UserParams
            label
            authId
            roomId
            color
            notify
            messageTemplate


{-| `stringToValue` must take empty string and emit default value.
-}
fetchValueFromBody : (String -> x) -> String -> StringTemplate.Body -> x
fetchValueFromBody stringToValue pattern body =
    case Regex.find (Regex.AtMost 1) (Regex.regex pattern) body of
        [ { submatches } ] ->
            case submatches of
                [ Just string ] ->
                    stringToValue string

                _ ->
                    stringToValue ""

        _ ->
            stringToValue ""


fetchMessageTemplateFromBody : StringTemplate.Body -> MessageTemplate
fetchMessageTemplateFromBody body =
    let
        takeMessagePart string =
            case String.indices "\",\n    \"color\":\"" string of
                i :: _ ->
                    String.left i string

                _ ->
                    -- Should not happen
                    string
    in
        body |> String.dropLeft 17 |> takeMessagePart


roomIdToUrl : String -> Utils.Url
roomIdToUrl roomId =
    "https://api.hipchat.com/v2/room/" ++ roomId ++ "/notification"


bodyBase : StringTemplate.Body
bodyBase =
    """{
    "message":"#{message}",
    "color":"#{color}",
    "notify":#{notify},
    "message_format":"text"
}"""
