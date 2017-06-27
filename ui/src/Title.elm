port module Title exposing (set, receive, default, concat)


port set : String -> Cmd msg


port receive : (String -> msg) -> Sub msg


default : String
default =
    "Poller the Bear"


concat : List String -> Cmd msg
concat subTitles =
    subTitles
        |> (::) default
        |> String.join " | "
        |> set
