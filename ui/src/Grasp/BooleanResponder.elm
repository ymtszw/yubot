module Grasp.BooleanResponder
    exposing
        ( BooleanResponder
        , HighOrder(..)
        , Predicate(..)
        , booleanResponder
        , isValid
        , stringToHo
        , stringToOp
        , highOrders
        , predicates
        , toOperator
        , defaultArgs
        , updatePredicate
        )

import Utils
import Grasp


type alias BooleanResponder =
    Grasp.Responder HighOrder Predicate


type HighOrder
    = First
    | Any
    | All


type Predicate
    = Truth
    | Contains
    | EqAt
    | NeAt
    | LtAt
    | LteAt
    | GtAt
    | GteAt


booleanResponder : HighOrder -> Predicate -> List String -> BooleanResponder
booleanResponder ho op args =
    Grasp.responder "boolean" ho (Grasp.firstOrder op args)


isValid : BooleanResponder -> Bool
isValid { highOrder, firstOrder } =
    List.member highOrder highOrders && isValidFirstOrder firstOrder


isValidFirstOrder : Grasp.FirstOrder Predicate -> Bool
isValidFirstOrder { operator, arguments } =
    case ( operator, arguments ) of
        ( Truth, args ) ->
            args == []

        ( Contains, args ) ->
            case args of
                [ rightValue ] ->
                    rightValue /= ""

                _ ->
                    False

        ( _, [ captureIndex, rightValue ] ) ->
            (captureIndex |> String.toInt |> Utils.isOk)
                && (rightValue /= "")

        _ ->
            False


stringToHo : String -> HighOrder
stringToHo string =
    case string of
        "First" ->
            First

        "Any" ->
            Any

        _ ->
            All


stringToOp : String -> Predicate
stringToOp string =
    case string of
        "Truth" ->
            Truth

        "Contains" ->
            Contains

        "NeAt" ->
            NeAt

        "LtAt" ->
            LtAt

        "LteAt" ->
            LteAt

        "GtAt" ->
            GtAt

        "GteAt" ->
            GteAt

        _ ->
            EqAt


highOrders : List HighOrder
highOrders =
    [ First, Any, All ]


predicates : List Predicate
predicates =
    [ Truth, Contains, EqAt, NeAt, LtAt, LteAt, GtAt, GteAt ]


toOperator : Predicate -> String
toOperator op =
    case op of
        Truth ->
            "always true"

        Contains ->
            "contains"

        EqAt ->
            "＝"

        NeAt ->
            "≠"

        LtAt ->
            "＜"

        LteAt ->
            "≦"

        GtAt ->
            "＞"

        GteAt ->
            "≧"


defaultArgs : Predicate -> List String
defaultArgs op =
    case op of
        Truth ->
            []

        Contains ->
            [ "true" ]

        EqAt ->
            [ "1", "true" ]

        NeAt ->
            [ "1", "true" ]

        LtAt ->
            [ "1", "true" ]

        LteAt ->
            [ "1", "true" ]

        GtAt ->
            [ "1", "true" ]

        GteAt ->
            [ "1", "true" ]


{-| Returns (firstOrder, numOfArgumentsLikelyChanged).
-}
updatePredicate : Grasp.FirstOrder Predicate -> Predicate -> ( Grasp.FirstOrder Predicate, Bool )
updatePredicate ({ operator, arguments } as oldFo) newOp =
    case ( operator, newOp ) of
        ( _, Truth ) ->
            ( { operator = Truth, arguments = [] }, True )

        ( _, Contains ) ->
            ( { operator = Contains, arguments = defaultArgs Contains }, True )

        ( Truth, twoArgsOp ) ->
            ( { operator = twoArgsOp, arguments = defaultArgs twoArgsOp }, True )

        ( Contains, twoArgsOp ) ->
            ( { operator = twoArgsOp, arguments = defaultArgs twoArgsOp }, True )

        ( _, _ ) ->
            -- Old value can be useful for new op
            ( { oldFo | operator = newOp }, False )
