module Styles exposing (..)

import Html exposing (Attribute)
import Html.Attributes exposing (style, class)
import Utils


greyBack : Attribute msg
greyBack =
    style [ ( "background-color", "rgba(242, 242, 238, 0.67)" ) ]


introGap : Attribute msg
introGap =
    style
        [ ( "padding-top", "30px" )
        , ( "padding-bottom", "30px" )
        , ( "margin-top", "20px" )
        , ( "color", "rgb(255, 255, 255)" )
        ]


toastBlock : Attribute msg
toastBlock =
    style
        [ ( "position", "fixed" )
        , ( "right", "10px" )
        , ( "left", "10px" )
        , ( "z-index", "1100" )
        ]


toast : Attribute msg
toast =
    style
        [ ( "box-shadow", "5px 5px 12px 0px rgba(0, 0, 0, 0.2)" ) ]


whiteBack : Attribute msg
whiteBack =
    style [ ( "background-color", "rgb(255, 255, 255)" ) ]


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
    style [ ( "font-family", "Consolas,Monaco,Lucida Console,Liberation Mono,DejaVu Sans Mono,Bitstream Vera Sans Mono,Courier New, monospace" ) ]


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


pointable : Attribute msg
pointable =
    style [ ( "pointer-events", "auto" ) ]


unpointable : Attribute msg
unpointable =
    style [ ( "pointer-events", "none" ) ]


fakeLink : Attribute msg
fakeLink =
    style [ ( "cursor", "pointer" ) ]
