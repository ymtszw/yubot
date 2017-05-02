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


mx2 : Attribute msg
mx2 =
    class "mx-2"


my1 : Attribute msg
my1 =
    class "my-1"
