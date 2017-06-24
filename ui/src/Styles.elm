module Styles exposing (..)

import Html exposing (Attribute)
import Html.Attributes exposing (style, class)
import Utils
import Actions.Hipchat exposing (Color(..))


greyBack : Attribute msg
greyBack =
    style
        [ ( "background-color", lightGrey ) ]


toastBlock : Attribute msg
toastBlock =
    style
        [ ( "position", "fixed" )
        , ( "right", "10px" )
        , ( "left", "10px" )
        , ( "z-index", "1100" )
        ]


activeNavbarItem : Attribute msg
activeNavbarItem =
    style
        [ ( "border-bottom", "solid 2px " ++ darkGrey ) ]


toast : Attribute msg
toast =
    style
        [ ( "box-shadow", "5px 5px 12px 0px " ++ transparentBlack ) ]


sorting : Attribute msg
sorting =
    style
        [ ( "padding-left", "20px" )
        , ( "background-image", "url(data:image/gif;base64,R0lGODlhCwALAJEAAAAAAP///xUVFf///yH5BAEAAAMALAAAAAALAAsAAAIUnC2nKLnT4or00PvyrQwrPzUZshQAOw==)" )
        , ( "background-repeat", "no-repeat" )
        , ( "background-position", "6px center" )
        , ( "cursor", "pointer" )
        ]


monospace : Attribute msg
monospace =
    style [ ( "font-family", monospaceFonts ) ]


xSmall : Attribute msg
xSmall =
    style [ ( "font-size", "x-small" ) ]


display : Bool -> Attribute msg
display isShown =
    style
        [ ( "display", Utils.ite isShown "block" "none" ) ]


hidden : Attribute msg
hidden =
    style [ ( "display", "none" ) ]


shown : Attribute msg
shown =
    style [ ( "display", "block" ) ]


inline : Attribute msg
inline =
    style [ ( "display", "inline" ) ]


inlineBlock : Attribute msg
inlineBlock =
    style [ ( "display", "inline-block" ) ]


tableCell : Attribute msg
tableCell =
    style [ ( "display", "table-cell" ) ]


pointable : Attribute msg
pointable =
    style [ ( "pointer-events", "auto" ) ]


unpointable : Attribute msg
unpointable =
    style [ ( "pointer-events", "none" ) ]


fakeLink : Attribute msg
fakeLink =
    style [ ( "cursor", "pointer" ) ]


rounded : Attribute msg
rounded =
    style [ ( "border-radius", "1rem" ) ]


bordered : Attribute msg
bordered =
    style [ ( "border", "solid 1px " ++ mediumGrey ) ]


invisibleBordered : Attribute msg
invisibleBordered =
    style [ ( "border", "solid 1px " ++ fullyTransparent ) ]


nonBordered : Attribute msg
nonBordered =
    style [ ( "border", "none" ) ]


leftBordered : Attribute msg
leftBordered =
    style [ ( "border-left", "solid 1px " ++ mediumGrey ) ]


bottomBordered : Attribute msg
bottomBordered =
    style [ ( "border-bottom", "solid 1px " ++ mediumGrey ) ]


hipchatYellow : Attribute msg
hipchatYellow =
    style [ ( "background-color", "rgb(254, 247, 228)" ) ]


hipchatPurple : Attribute msg
hipchatPurple =
    style [ ( "background-color", "rgb(233, 229, 237)" ) ]


hipchatGreen : Attribute msg
hipchatGreen =
    style [ ( "background-color", "rgb(233, 243, 229)" ) ]


hipchatRed : Attribute msg
hipchatRed =
    style [ ( "background-color", "rgb(249, 228, 226)" ) ]


hipchatGray : Attribute msg
hipchatGray =
    style [ ( "background-color", "rgb(245, 245, 245)" ) ]


hipchatColor : Color -> Attribute msg
hipchatColor color =
    case color of
        Yellow ->
            hipchatYellow

        Purple ->
            hipchatPurple

        Green ->
            hipchatGreen

        Red ->
            hipchatRed

        Gray ->
            hipchatGray


editor : Attribute msg
editor =
    style
        [ ( "font-family", monospaceFonts )
        , ( "background", linedGradient fullyTransparent transparentBlack )
        ]


linedGradient : String -> String -> String
linedGradient bodyColor lineColor =
    String.join ""
        [ "repeating-linear-gradient("
        , String.join ","
            [ bodyColor
            , bodyColor ++ " 1.21rem"
            , lineColor
            , lineColor ++ " 1.25rem"
            ]
        , ")"
        ]


gutter : Attribute msg
gutter =
    style
        [ ( "text-align", "right" )
        , ( "min-width", "3rem" )
        , ( "line-height", "1.25rem" ) -- XXX: matching with threshold of linedGradient; officially we should use number-without-unit in "line-height"
        , ( "border", "solid 1px " ++ lightGrey )
        , ( "border-right", "none" )
        , ( "color", mediumGrey )
        , ( "background-color", transparentLightGrey )
        , ( "user-select", "none" )
        ]


gutterItem : Int -> Attribute msg
gutterItem index =
    if index == 1 then
        style [ ( "border", "none" ) ]
    else
        style [ ( "border-top", "none" ) ]


textarea : Attribute msg
textarea =
    style
        [ ( "padding", "0 0 0 .5rem" )
        , ( "line-height", "1.25rem" ) -- XXX: matching with threshold of linedGradient
        , ( "font-family", monospaceFonts )
        , ( "border-radius", "0" )
        , ( "resize", "none" )
        , ( "background-color", fullyTransparent )
        , ( "white-space", "pre" )
        ]



-- Help


lightGrey : String
lightGrey =
    "rgb(234, 234, 234)"


transparentLightGrey : String
transparentLightGrey =
    "rgba(234, 234, 234, 0.4)"


mediumGrey : String
mediumGrey =
    "rgb(185, 185, 185)"


darkGrey : String
darkGrey =
    "rgb(128, 128, 128)"


fullyTransparent : String
fullyTransparent =
    "rgba(0, 0, 0, 0)"


transparentBlack : String
transparentBlack =
    "rgba(0, 0, 0, 0.15)"


monospaceFonts : String
monospaceFonts =
    "Consolas,Monaco,Lucida Console,Liberation Mono,DejaVu Sans Mono,Bitstream Vera Sans Mono,Courier New, monospace"
