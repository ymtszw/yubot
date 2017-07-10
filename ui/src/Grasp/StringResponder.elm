module Grasp.StringResponder
    exposing
        ( StringResponder
        , HighOrder(..)
        , StringMaker(..)
        , stringResponder
        , stringToHo
        , stringToOp
        , highOrders
        , stringMakers
        , isValid
        , newWithStringMaker
        )

import Utils
import Grasp


type alias StringResponder =
    Grasp.Responder HighOrder StringMaker


type HighOrder
    = First
    | JoinAll


type StringMaker
    = Join
    | At


stringResponder : HighOrder -> StringMaker -> List String -> StringResponder
stringResponder ho op args =
    Grasp.responder "string" ho (Grasp.firstOrder op args)


stringToHo : String -> HighOrder
stringToHo string =
    case string of
        "First" ->
            First

        _ ->
            JoinAll


stringToOp : String -> StringMaker
stringToOp string =
    case string of
        "Join" ->
            Join

        _ ->
            At


highOrders : List HighOrder
highOrders =
    [ First, JoinAll ]


stringMakers : List StringMaker
stringMakers =
    [ Join, At ]


defaultArgs : StringMaker -> List String
defaultArgs op =
    case op of
        Join ->
            [ "," ]

        At ->
            [ "1" ]


isValid : StringResponder -> Bool
isValid { highOrder, firstOrder } =
    (List.member highOrder highOrders)
        && isValidFirstOrder firstOrder


isValidFirstOrder : Grasp.FirstOrder StringMaker -> Bool
isValidFirstOrder { operator, arguments } =
    case ( operator, arguments ) of
        ( Join, [ _ ] ) ->
            True

        ( At, [ index ] ) ->
            index |> String.toInt |> Utils.isOk

        _ ->
            False


newWithStringMaker : StringMaker -> Grasp.FirstOrder StringMaker
newWithStringMaker op =
    Grasp.firstOrder op (defaultArgs op)
