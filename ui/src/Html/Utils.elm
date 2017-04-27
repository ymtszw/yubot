module Html.Utils exposing (..)

import Date
import Regex exposing (Match, HowMany(AtMost), regex)
import Html exposing (Html, text, a)
import Html.Attributes exposing (href)
import Html.Events exposing (onClick)
import Bootstrap.Button as Button
import Utils exposing (Sorter, Ord(..))
import Resource.Messages exposing (Msg(OnSort))
import Poller.Styles exposing (mx2, my1)


-- Html helpers


{-| `text` with autolinking whitespace-splitted URLs.
Return list-wrapped `Html Msg`s.
-}
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

                { match, index } :: _ ->
                    -- Expect only one at most
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


mx2Button : msg -> List (Button.Option msg) -> String -> Html msg
mx2Button clickMsg options string =
    Button.button
        (List.append options
            [ Button.attrs [ mx2, my1 ]
            , Button.onClick clickMsg
            ]
        )
        [ text string ]



-- Event helpers


toggleSortOnClick : (resource -> String) -> Maybe (Sorter resource) -> Html.Attribute (Msg resource)
toggleSortOnClick newCompareBy maybeSorter =
    let
        order =
            case maybeSorter of
                Nothing ->
                    Asc

                Just ( oldCompareBy, oldOrder ) ->
                    case oldOrder of
                        Asc ->
                            Desc

                        Desc ->
                            Asc
    in
        onClick (OnSort ( newCompareBy, order ))



-- String helpers


toDateString : String -> String
toDateString string =
    case Date.fromString string of
        Ok date ->
            toString date

        Err x ->
            "Invalid updatedAt!"


intervalToString : String -> String
intervalToString interval =
    case String.toInt interval of
        Ok _ ->
            "every " ++ interval ++ " min."

        Err _ ->
            interval
