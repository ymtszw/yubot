module Poller.Styles exposing (..)

import Html exposing (Attribute)
import Html.Attributes exposing (style, class)


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


hidden : Attribute msg
hidden =
    style [ ( "display", "none" ) ]
