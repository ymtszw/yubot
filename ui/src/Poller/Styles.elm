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
    style [ ( "background-color", "rgba(242, 242, 238, 0.67)" ) ]

introGap : Attribute msg
introGap =
    style
        [ ( "padding-top", "30px" )
        , ( "padding-bottom", "30px" )
        , ( "color", "rgb(255, 255, 255)" )
        ]

whiteBack : Attribute msg
whiteBack =
    style [ ("background-color", "rgb(255, 255, 255)" ) ]

-- Bootstrap styled class wrappers

rounded : Attribute msg
rounded =
    class "rounded"

display1 : Attribute msg
display1 =
    class "display-1"

py3 : Attribute msg
py3 =
    class "py-3"

p3 : Attribute msg
p3 =
    class "p-3"
