{-
   Port module for communicating with document interface.
-}


port module Document
    exposing
        ( setTitle
        , receiveTitle
        , defaultTitle
        , concatSubtitles
        , setBackgroundClickListener
        , removeBackgroundClickListener
        , listenBackgroundClick
        , addBodyClass
        , removeBodyClass
        )

-- Title


port setTitle : String -> Cmd msg


port receiveTitle : (String -> msg) -> Sub msg


defaultTitle : String
defaultTitle =
    "Poller the Bear"


concatSubtitles : List String -> Cmd msg
concatSubtitles subTitles =
    subTitles
        |> (::) defaultTitle
        |> String.join " | "
        |> setTitle



-- Background (document) Click


port setBackgroundClickListener : () -> Cmd msg


port removeBackgroundClickListener : () -> Cmd msg


port listenBackgroundClick : (Bool -> msg) -> Sub msg



-- Body Class
{-
   Using document.body.classList#add, #remove
-}


port addBodyClass : String -> Cmd msg


port removeBodyClass : String -> Cmd msg
