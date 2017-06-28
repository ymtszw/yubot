port module Document
    exposing
        ( setTitle
        , receiveTitle
        , defaultTitle
        , concatSubtitles
        , setBackgroundClickListener
        , removeBackgroundClickListener
        , listenBackgroundClick
        , backgroundClickSub
        )

{-
   Port module for communicating with document interface.
-}

import Utils exposing (DropdownState(..))
import Poller.Messages exposing (Msg(UserDropdownMsg))


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


port setBackgroundClickListener : () -> Cmd msg


port removeBackgroundClickListener : () -> Cmd msg


port listenBackgroundClick : (Bool -> msg) -> Sub msg


backgroundClickSub : DropdownState -> List (Sub Msg)
backgroundClickSub userDropdownState =
    if userDropdownState == Shown then
        [ listenBackgroundClick (always (UserDropdownMsg Fading)) ]
    else
        []
