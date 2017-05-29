module Actions.Hipchat exposing (Color(..), default, fromParams, fetchParams)

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


type alias UserParams =
    { roomId : String
    , authId : Repo.EntityId
    , color : Color
    , notify : Bool
    , messageTemplate : MessageTemplate
    }


validateMessageTemplate : String -> Result Utils.ErrorMessage MessageTemplate
validateMessageTemplate string =
    if String.contains "\"" string then
        Err ( "Hipchat message template", "Double quotations are not allowed." )
    else
        Ok string


default : Action
default =
    let
        body =
            bodyBase
                |> StringTemplate.render "color" "yellow"
                |> StringTemplate.render "notify" "false"
    in
        Action Nothing "post" "" Nothing (StringTemplate body [ "message" ]) Actions.Hipchat


defaultParams : UserParams
defaultParams =
    UserParams "" "" Yellow False ""


fromParams : UserParams -> Result Utils.ErrorMessage Action
fromParams { roomId, authId, color, notify, messageTemplate } =
    let
        body =
            bodyBase
                |> StringTemplate.render "color" (color |> toString |> String.toLower)
                |> StringTemplate.render "notify" (notify |> toString |> String.toLower)

        action bodyTemplate =
            Action
                (Just ("Hipchat [RoomID: " ++ roomId ++ "]"))
                "post"
                (roomIdToUrl roomId)
                (Just authId)
                bodyTemplate
                Actions.Hipchat
    in
        case messageTemplate of
            "" ->
                Ok (action (StringTemplate body [ "message" ]))

            mt0 ->
                mt0
                    |> validateMessageTemplate
                    |> Result.map (\mt1 -> StringTemplate.render "message" mt1 body)
                    |> Result.andThen
                        (\bt ->
                            StringTemplate.validate bt
                                |> Result.map (StringTemplate bt >> action)
                        )


fetchParams : Action -> UserParams
fetchParams action =
    let
        roomId =
            action.url |> String.dropLeft 32 |> String.dropRight 13

        color =
            fetchValueFromBody
                stringToColor
                (Regex.regex "\"color\":\"(yellow|green|red|purple|gray)\"")
                action.bodyTemplate.body

        notify =
            fetchValueFromBody
                Utils.stringToBool
                (Regex.regex "\"notify\":\"(true|false)\"")
                action.bodyTemplate.body

        messageTemplate =
            fetchValueFromBody
                identity
                (Regex.regex "\"message\":\"(.+)\"")
                action.bodyTemplate.body
    in
        UserParams
            roomId
            (Maybe.withDefault "" action.auth)
            color
            notify
            messageTemplate


stringToColor : String -> Color
stringToColor string =
    case string of
        "green" ->
            Green

        "red" ->
            Red

        "purple" ->
            Purple

        "gray" ->
            Gray

        _ ->
            Yellow


{-| `stringToValue` must take empty string and emit default value.
-}
fetchValueFromBody : (String -> x) -> Regex.Regex -> StringTemplate.Body -> x
fetchValueFromBody stringToValue pattern body =
    case Regex.find (Regex.AtMost 1) pattern body of
        [ { submatches } ] ->
            case submatches of
                [ Just string ] ->
                    stringToValue string

                _ ->
                    stringToValue ""

        _ ->
            stringToValue ""


roomIdToUrl : String -> Utils.Url
roomIdToUrl roomId =
    "https://api.hipchat.com/v2/room/" ++ roomId ++ "/notification"


bodyBase : StringTemplate.Body
bodyBase =
    """
    {
        "message":"#{message}",
        "color":"#{color}",
        "notify":#{notify},
        "message_format":"text"
    }
    """
