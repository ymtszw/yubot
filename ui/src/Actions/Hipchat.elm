module Actions.Hipchat exposing (Color(..), new)

import Utils
import StringTemplate
import Actions


type Color
    = Yellow
    | Green
    | Red
    | Purple
    | Gray


new : String -> Repo.EntityId -> Color -> Bool -> Actions.Action
new roomId authId color notifyBool =
    let
        notify =
            if notifyBool then
                "true"
            else
                "false"

        body =
            bodyBase
                |> StringTemplate.render "color" color
                |> StringTemplate.render "notify" notify
    in
        Action
            ("Hipchat [RoomID: " ++ roomId ++ "]")
            "post"
            (url roomId)
            (Just authId)
            (StringTemplate.StringTemplate body [ "message" ])
            Actions.Hipchat


url : String -> Utils.Url
url roomId =
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
