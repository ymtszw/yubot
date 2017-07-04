module Grasp.StringResponder exposing (StringResponder, HighOrder, StringMaker, stringToHo, stringToOp)

import Grasp


type alias StringResponder =
    Grasp.Responder HighOrder StringMaker


type HighOrder
    = First
    | JoinAll


type StringMaker
    = Join
    | At


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
