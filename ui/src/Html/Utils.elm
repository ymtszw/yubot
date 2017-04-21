module Html.Utils exposing (..)

import Regex exposing (Match, HowMany(AtMost), regex)
import Html exposing (Html, text, a)
import Html.Attributes exposing (href)
import Bootstrap.Button as Button exposing (Option)
import Poller.Styles exposing (mx2)

-- "text" with autolinking whitespace-splitted URLs
atext : String -> List (Html msg)
atext string =
    atextImpl string []

atextImpl : String -> List (Html msg) -> List (Html msg)
atextImpl string htmls =
    case string of
        "" ->
            htmls
        _ ->
            case findFirstUrl string of
                [] ->
                    htmls ++ [ text string ]
                { match, index } :: _ -> -- Expect only one at most
                    let
                        ( newHtmls, tailString ) =
                            leftToHtml string match index
                    in
                        atextImpl tailString newHtmls

findFirstUrl : String -> List Match
findFirstUrl string =
    Regex.find (AtMost 1) (regex "http(s)?://[a-zA-Z0-9_./#?&%=~+-]+") string

leftToHtml : String -> String -> Int -> ( List (Html msg), String )
leftToHtml string matchedUrl index =
    case index of
        0 ->
            ( [ a [ href matchedUrl ] [ text matchedUrl ] ]
            , String.dropLeft (String.length matchedUrl) string
            )
        _ ->
            ( [ text (String.left index string), a [ href matchedUrl ] [ text matchedUrl ] ]
            , String.dropLeft (index + String.length matchedUrl) string
            )

mx2Button : msg -> Option msg -> String -> Html msg
mx2Button clickMsg option string =
    Button.button
        [ option
        , Button.attrs [ mx2 ]
        , Button.onClick clickMsg
        ]
        [ text string ]
