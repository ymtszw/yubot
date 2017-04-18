module Poller.Styles exposing (..)

import Html exposing (Attribute)
import Html.Attributes exposing (style, class)

background : Attribute msg
background =
    style
        [ ( "background-image", "url('static/img/polar_bear.jpg')" )
        , ( "background-size", "cover" )
        , ( "height", "100vh" )
        ]

greyBack : Attribute msg
greyBack =
    style [ ( "background-color", "rgb(242, 242, 238)" ) ]

introGap : Attribute msg
introGap =
    style
        [ ( "padding-top", "30px" )
        , ( "padding-bottom", "30px" )
        , ( "color", "rgb(255, 255, 255)" )
        ]

-- Bootstrap styled class wrappers

rounded : Attribute msg
rounded =
    class "rounded"

display1 : Attribute msg
display1 =
    class "display-1"
