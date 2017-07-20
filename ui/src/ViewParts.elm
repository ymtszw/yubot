module ViewParts exposing (..)

import Json.Decode
import Regex exposing (HowMany(..))
import Html exposing (Html, text)
import Html.Attributes as Attr exposing (class)
import Html.Events
import Html.Lazy as Z
import Maybe.Extra as ME
import Markdown
import Bootstrap.Button as Button
import Utils exposing (ite)
import Styles


type BreakPoint
    = XS
    | SM
    | MD
    | LG
    | XL


prevBreakPoints : BreakPoint -> BreakPoint
prevBreakPoints bp =
    case bp of
        XS ->
            XS

        SM ->
            XS

        MD ->
            SM

        LG ->
            MD

        XL ->
            LG


responsiveBlock : BreakPoint -> Maybe (List (Html msg)) -> List (Html msg) -> Html msg
responsiveBlock breakpoint maybeHtmlsForSmall htmlsForLarge =
    Html.div []
        [ maybeHtmlsForSmall |> ME.unwrap none (Html.div [ class ("hidden-" ++ Utils.toLowerString breakpoint ++ "-up") ])
        , Html.div [ class ("hidden-" ++ (breakpoint |> prevBreakPoints |> Utils.toLowerString) ++ "-down") ] htmlsForLarge
        ]


httpRequest : Utils.Method -> Utils.Url -> Html msg
httpRequest method url =
    Html.code [] (autoLink ((toString method) ++ " " ++ url))


none : Html msg
none =
    Z.lazy text ""


fa : List (Html.Attribute msg) -> Int -> String -> Html msg
fa attrs factor iconClass =
    let
        factorClass =
            if List.member factor [ 2, 3, 4, 5 ] then
                "fa-" ++ (toString factor) ++ "x "
            else
                ""
    in
        Html.i ([ class ("fa fa-fw " ++ factorClass ++ iconClass) ] ++ attrs) []


{-| 3-pane view with upper-left, lower-left and right panes.
-}
triPaneView : List (Html msg) -> List (Html msg) -> List (Html msg) -> List (Html msg) -> Html msg
triPaneView title upperLeftPane lowerLeftPane rightPane =
    Html.div [ class "row" ]
        [ Html.div [ class "col-md-12" ] title
        , Html.div [ class "col-md-6 px-3" ]
            [ Html.div [ class "row p-0" ]
                [ Html.div [ class "col-md-12" ] upperLeftPane
                , Html.div [ class "col-md-12" ] lowerLeftPane
                ]
            ]
        , Html.div [ class "col-md-6 px-3" ] rightPane
        ]


{-| Generic Card block wrapper
-}
cardBlock : List (Html msg) -> String -> Maybe (Html msg) -> Html msg -> Html msg
cardBlock titleHtmls subtitleRawMD maybeDescriptionHtml contentsHtml =
    Html.div [ class "card my-3" ]
        [ Html.div [ class "card-block" ]
            [ htmlIf (titleHtmls /= []) (Html.h4 [ class "card-title" ] titleHtmls)
            , htmlIf (subtitleRawMD /= "")
                (Html.p [ class "card-subtitle text-muted" ]
                    [ Markdown.toHtml [] subtitleRawMD ]
                )
            , htmlMaybe (Html.div [ class "card-text" ] << List.singleton) maybeDescriptionHtml
            , contentsHtml
            ]
        ]


codeBlock : List (Html.Attribute msg) -> List (Html msg) -> Html msg
codeBlock attrs htmls =
    Html.pre ([ Styles.greyBack, class "rounded", class "p-3" ] ++ attrs) htmls


stdBtn : Button.Option msg -> List (Button.Option msg) -> Bool -> String -> Html msg
stdBtn activatedStyle baseOptions0 isDisabled label =
    let
        baseOptions1 =
            [ Button.attrs [ class "mx-2 my-1", Attr.type_ "button" ] ] ++ baseOptions0

        options =
            if isDisabled then
                [ Button.disabled True ] ++ baseOptions1
            else
                [ activatedStyle, Button.attrs [ Styles.fakeLink ] ] ++ baseOptions1
    in
        Button.button options [ text label ]


{-| `text` with autolinking whitespace-splitted URLs.
Return list-wrapped `Html msg`s.
-}
autoLink : String -> List (Html msg)
autoLink =
    autoLinkImpl []


autoLinkImpl : List (Html msg) -> String -> List (Html msg)
autoLinkImpl htmls string =
    let
        findFirstUrl =
            Regex.find (AtMost 1) (Regex.regex "http(s)?://[a-zA-Z0-9_./#?&%=~+-]+")

        convertAndConcat htmls string { match, index } =
            case index of
                0 ->
                    ( (Html.a [ Attr.href match ] [ text match ]) :: htmls
                    , String.dropLeft (String.length match) string
                    )

                _ ->
                    ( (Html.a [ Attr.href match ] [ text match ]) :: (text (String.left index string)) :: htmls
                    , String.dropLeft (index + String.length match) string
                    )

        findAndConvert nonemptyString =
            case findFirstUrl nonemptyString of
                [] ->
                    (text nonemptyString) :: htmls

                match :: _ ->
                    -- Expect only one at most
                    match |> convertAndConcat htmls nonemptyString |> uncurry autoLinkImpl
    in
        Utils.stringMapWithDefault findAndConvert (List.reverse htmls) string


{-| Somewhat straightforward modal generator.
Can close modal on click-elsewhere.
-}
modal : (Bool -> msg) -> Bool -> List (Html.Attribute msg) -> List (Html msg) -> List (Html msg) -> List (Html msg) -> Html msg
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


pillNav : List (Html.Attribute msg) -> (navValue -> msg) -> Maybe (navValue -> msg) -> List ( navValue, Bool, List (Html msg) ) -> Html msg
pillNav activatedAttrs onClickInactive maybeOnClickActive navItems =
    let
        itemOption navValue isActive =
            if isActive then
                case maybeOnClickActive of
                    Just onClickActive ->
                        (onClickNoDefault (onClickActive navValue)) :: activatedAttrs

                    Nothing ->
                        activatedAttrs
            else
                [ class "btn-secondary"
                , Styles.invisibleBordered
                , Styles.fakeLink
                , onClickNoDefault (onClickInactive navValue)
                ]

        navItem ( navValue, isActive, itemHtmls ) =
            itemHtmls
                |> Html.span ((class "nav-link btn") :: (itemOption navValue isActive))
                |> List.singleton
                |> Html.li [ class "nav-item mb-2 mr-2" ]
    in
        navItems
            |> List.map navItem
            |> Html.ul [ class "nav nav-pills flex-wrap" ]


anchoredText : String -> Html msg
anchoredText string =
    let
        anchorName =
            string
                |> String.toLower
                |> Utils.stringIndexedMap (\_ x -> ite (x == ' ') '-' x)
    in
        Html.a [ Attr.name anchorName ] [ text string ]


{-| Pretends to be an ordinary link, but steals click event with preventDefault: True,
then navigating with Navigation.newUrl
-}
navigate : (Utils.Url -> msg) -> Utils.Url -> List (Html.Attribute msg)
navigate changeLocationMsg url =
    [ Attr.href ("/poller" ++ url)
    , onClickNoDefault (changeLocationMsg url)
    ]


{-| FakeLink styled clickable attributes.
-}
onFakeLinkClick : Bool -> Bool -> msg -> List (Html.Attribute msg)
onFakeLinkClick stopPropagation preventDefault msg =
    [ Styles.fakeLink
    , Html.Events.onWithOptions
        "click"
        (Html.Events.Options stopPropagation preventDefault)
        (Json.Decode.succeed msg)
    ]


{-| Same as Html.Events.onClick but with `preventDefault: True`
-}
onClickNoDefault : msg -> Html.Attribute msg
onClickNoDefault msg =
    Html.Events.onWithOptions
        "click"
        (Html.Events.Options False True)
        (Json.Decode.succeed msg)


{-| Same as Html.Events.onClick but with `stopPropagation: True, preventDefault: True`
-}
onClickNoPropagate : msg -> Html.Attribute msg
onClickNoPropagate msg =
    Html.Events.onWithOptions
        "click"
        (Html.Events.Options True True)
        (Json.Decode.succeed msg)


htmlIf : Bool -> Html msg -> Html msg
htmlIf predicate html =
    ite predicate html none


htmlMaybe : (x -> Html msg) -> Maybe x -> Html msg
htmlMaybe htmlFun =
    ME.unwrap none htmlFun
