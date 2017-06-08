module Html.Utils
    exposing
        ( atext
        , highlightVariables
        , mx2Button
        , modal
        , toggleSortOnClick
        , navigate
        , anchoredText
        , onClickNoDefault
        )

import Json.Decode
import Regex exposing (Match, HowMany(AtMost), regex)
import Html exposing (Html, text)
import Html.Attributes as Attr exposing (class)
import Html.Events
import Bootstrap.Button as Button
import Utils exposing (ite)
import Repo exposing (Sorter, Ord(..))
import Repo.Messages exposing (Msg(OnSort))
import StringTemplate
import Styles


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
                    ( [ Html.a [ Attr.href matchedUrl ] [ text matchedUrl ] ]
                    , String.dropLeft (String.length matchedUrl) string
                    )

                _ ->
                    ( [ text (String.left index string), Html.a [ Attr.href matchedUrl ] [ text matchedUrl ] ]
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


{-| Somewhat straightforward modal generator.
Can close modal on click-elsewhere.
-}
modal : (Bool -> Msg x) -> Bool -> List (Html.Attribute (Msg x)) -> List (Html (Msg x)) -> List (Html (Msg x)) -> List (Html (Msg x)) -> Html (Msg x)
modal boolToMsg isShown dialogOptions titleContents bodyContents footerContents =
    let
        closeOnClick =
            Html.Events.onClick (boolToMsg False)

        content options =
            Html.div options
                [ Html.div ([ class "modal-dialog", Styles.pointable ] ++ dialogOptions)
                    [ Html.div [ class "modal-content" ]
                        [ Html.div [ class "modal-header" ]
                            [ Html.h6 [ class "modal-title" ] titleContents
                            , Html.button [ class "close", closeOnClick ] [ Html.span [] [ text "×" ] ]
                            ]
                        , Html.div [ class "modal-body" ] bodyContents
                        , Html.div [ class "modal-footer" ] footerContents
                        ]
                    ]
                ]
    in
        if isShown then
            Html.div []
                [ content [ Attr.tabindex -1, class "modal fade show", Styles.shown, Styles.unpointable ]
                , Html.div [ class "modal-backdrop fade show", closeOnClick ] []
                ]
        else
            Html.div [] [ content [ Attr.tabindex -1, class "modal fade", Styles.hidden, Styles.unpointable ] ]


toggleSortOnClick : (Repo.Entity x -> String) -> Sorter x -> Html.Attribute (Msg x)
toggleSortOnClick newProperty sorter =
    let
        newOrder =
            Repo.toggleOrder sorter.order
    in
        Html.Events.onClick (OnSort (Sorter newProperty newOrder))


{-| Pretends to be an ordinary link, but steals click event with preventDefault: True,
then navigating with Navigation.modifyUrl
-}
navigate : (Utils.Url -> msg) -> Utils.Url -> List (Html.Attribute msg)
navigate changeLocationMsg url =
    [ Attr.href url
    , onClickNoDefault (changeLocationMsg url)
    ]


anchoredText : String -> Html msg
anchoredText string =
    let
        anchorName =
            string
                |> String.toLower
                |> Utils.stringIndexedMap (\_ x -> ite (x == ' ') '-' x)
    in
        Html.a [ Attr.name anchorName ] [ text string ]


{-| Same as Html.Events.onClick but with `preventDefault: True`
-}
onClickNoDefault : msg -> Html.Attribute msg
onClickNoDefault msg =
    Html.Events.onWithOptions
        "click"
        (Html.Events.Options False True)
        (Json.Decode.succeed msg)
