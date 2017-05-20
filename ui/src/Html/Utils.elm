module Html.Utils
    exposing
        ( atext
        , highlightVariables
        , mx2Button
        , errorAlert
        , toggleSortOnClick
        , navigateOnClick
        )

import Regex exposing (Match, HowMany(AtMost), regex)
import Html exposing (Html, text, a)
import Html.Attributes exposing (href, class)
import Html.Events
import Bootstrap.Button as Button
import Bootstrap.Alert as Alert
import Utils
import Resource exposing (Sorter, Ord(..))
import Resource.Messages exposing (Msg(OnSort))
import StringTemplate
import Poller.Messages
import Poller.Styles


-- Html helpers


{-| `text` with autolinking whitespace-splitted URLs.
Return list-wrapped `Html Msg`s.
-}
atext : String -> List (Html msg)
atext string =
    atextImpl string []


atextImpl : String -> List (Html msg) -> List (Html msg)
atextImpl string htmls =
    let
        findFirst =
            Regex.find (AtMost 1) (regex "http(s)?://[a-zA-Z0-9_./#?&%=~+-]+")

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
    in
        case string of
            "" ->
                htmls

            _ ->
                case findFirst string of
                    [] ->
                        htmls ++ [ text string ]

                    { match, index } :: _ ->
                        -- Expect only one at most
                        let
                            ( newHtmls, tailString ) =
                                leftToHtml string match index
                        in
                            atextImpl tailString (htmls ++ newHtmls)


highlightVariables : StringTemplate.Body -> List (Html msg)
highlightVariables body =
    highlightVariablesImpl body []


highlightVariablesImpl : StringTemplate.Body -> List (Html msg) -> List (Html msg)
highlightVariablesImpl bodyTail htmls =
    let
        findFirst =
            Regex.find (AtMost 1) (regex "#\\{(.*?)\\}")

        leftToHtml string matchedVar index =
            case index of
                0 ->
                    ( [ Html.strong [ class "text-danger" ] [ text matchedVar ] ]
                    , String.dropLeft (String.length matchedVar) string
                    )

                _ ->
                    ( [ text (String.left index string), Html.strong [ class "text-danger" ] [ text matchedVar ] ]
                    , String.dropLeft (index + String.length matchedVar) string
                    )
    in
        case bodyTail of
            "" ->
                htmls

            _ ->
                case findFirst bodyTail of
                    [] ->
                        htmls ++ [ text bodyTail ]

                    { match, index } :: _ ->
                        -- Expect only one at most
                        let
                            ( newHtmls, newTail ) =
                                leftToHtml bodyTail match index
                        in
                            highlightVariablesImpl newTail (htmls ++ newHtmls)


mx2Button : msg -> List (Button.Option msg) -> String -> Html msg
mx2Button clickMsg options string =
    Button.button
        (List.append options
            [ Button.attrs [ class "mx-2", class "my-1" ]
            , Button.onClick clickMsg
            ]
        )
        [ text string ]


errorAlert : List Utils.ErrorMessage -> Html msg
errorAlert errors =
    let
        alert ( label, message ) =
            Alert.danger
                [ Html.strong [] [ text ("[" ++ label ++ "] ") ]
                , text message
                ]
    in
        case errors of
            [] ->
                text ""

            _ ->
                errors
                    |> List.map alert
                    |> Html.div []



-- Event helpers


toggleSortOnClick : (resource -> String) -> Maybe (Sorter resource) -> Html.Attribute (Msg resource)
toggleSortOnClick newProperty maybeSorter =
    let
        newOrder =
            case maybeSorter of
                Nothing ->
                    Asc

                Just { property, order } ->
                    case order of
                        Asc ->
                            Desc

                        Desc ->
                            Asc
    in
        Html.Events.onClick (OnSort (Sorter newProperty newOrder))


navigateOnClick : Utils.Url -> List (Html.Attribute Poller.Messages.Msg)
navigateOnClick url =
    [ Poller.Styles.fakeLink
    , Html.Events.onClick (Poller.Messages.ChangeLocation url)
    ]
