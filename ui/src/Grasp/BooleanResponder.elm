module Grasp.BooleanResponder exposing (BooleanResponder, HighOrder, Predicate, stringToHo, stringToOp)

import Grasp


type alias BooleanResponder =
    Grasp.Responder HighOrder Predicate


type HighOrder
    = First
    | Any
    | All


type Predicate
    = Contains
    | EqAt
    | NeAt
    | LtAt
    | LteAt
    | GtAt
    | GteAt


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
