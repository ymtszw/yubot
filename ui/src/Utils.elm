module Utils
    exposing
        ( Timestamp
        , Url
        , Milliseconds
        , DropdownState(..)
        , Method(..)
        , methods
        , stringToMethod
        , listShuffle
        , boolToMaybe
        , dictGetWithDefault
        , dictUpsert
        , ite
        , stringIndexedMap
        , stringMapWithDefault
        , timestampToString
        , dateToString
        , dateToFineString
        , shortenUrl
        , stringToBool
        , toLowerString
        , emit
        , emitIn
        , randomLowerAlphaGen
        , isOk
        , isErr
        )

import Char
import Date
import Dict exposing (Dict)
import Process
import Random
import Task
import Time


type alias Timestamp =
    String


type alias Url =
    String


type alias Milliseconds =
    Time.Time


type DropdownState
    = Shown
    | Fading
    | Hidden


{-| HTTP method available for Polls/Actions.
-}
type Method
    = POST
    | GET
    | PUT
    | DELETE


methods : List Method
methods =
    [ POST, GET, PUT, DELETE ]


stringToMethod : String -> Method
stringToMethod methodStr =
    case methodStr of
        "post" ->
            POST

        "put" ->
            PUT

        "delete" ->
            DELETE

        _ ->
            GET


{-| Shuffle an element of list with its neighbor.
If isAsc, shuffle with neighbor of index-ascending direction.
Otherwise index-descending direction.
If either base index or neighbor index are out-of-bound,
it returns unchanged list.

Similar to List.Extra.swapAt, but slightly different behavior.

-}
listShuffle : Int -> Bool -> List a -> List a
listShuffle index isAsc list =
    listShuffleImpl index isAsc ( 0, [] ) list


listShuffleImpl : Int -> Bool -> ( Int, List a ) -> List a -> List a
listShuffleImpl index isAsc ( currentIndex, acc ) tail =
    case ( tail, acc ) of
        ( [], _ ) ->
            List.reverse acc

        ( x :: xs, y :: ys ) ->
            if (isAsc && currentIndex == index + 1) || (not isAsc && index == currentIndex) then
                (List.reverse (y :: x :: ys)) ++ xs
            else
                listShuffleImpl index isAsc ( currentIndex + 1, x :: acc ) xs

        ( x :: xs, [] ) ->
            if (not isAsc && index == currentIndex) then
                -- out-of-bound
                tail
            else
                listShuffleImpl index isAsc ( currentIndex + 1, [ x ] ) xs


boolToMaybe : x -> Bool -> Maybe x
boolToMaybe something bool =
    ite bool (Just something) Nothing


dictGetWithDefault : comparable -> v -> Dict comparable v -> v
dictGetWithDefault key default dict =
    dict |> Dict.get key |> Maybe.withDefault default


{-| Mostly similar to Dict.Extra.insertDedupe.
-}
dictUpsert : comparable -> (v -> v) -> v -> Dict comparable v -> Dict comparable v
dictUpsert key mapper default dict =
    let
        updateFun maybeValue =
            case maybeValue of
                Just value ->
                    Just (mapper value)

                Nothing ->
                    Just default
    in
        Dict.update key updateFun dict


{-| Stands for If-Then-Else, can be written in oneline without being elm-formatted.
-}
ite : Bool -> x -> x -> x
ite predicate a b =
    if predicate then
        a
    else
        b


stringIndexedMap : (Int -> Char -> Char) -> String -> String
stringIndexedMap mapper =
    String.toList >> (List.indexedMap mapper) >> String.fromList


{-| Actually is `stringMapNonemptyWithDefault`, though shorthanded.
If `string` is nonempty, `mapNonempty` is applied. Otherwise `defaultForEmpty` is used.
-}
stringMapWithDefault : (String -> a) -> a -> String -> a
stringMapWithDefault mapNonempty defaultForEmpty string =
    case string of
        "" ->
            defaultForEmpty

        nonempty ->
            mapNonempty nonempty


{-| Times are automatically converted to Local time.
-}
timestampToString : Timestamp -> String
timestampToString string =
    case Date.fromString string of
        Ok date ->
            dateToString date

        Err _ ->
            "Invalid timestamp!"


dateToString : Date.Date -> String
dateToString date =
    let
        toPaddedString =
            toString >> String.padLeft 2 '0'

        toIntMonth date =
            case Date.month date of
                Date.Jan ->
                    1

                Date.Feb ->
                    2

                Date.Mar ->
                    3

                Date.Apr ->
                    4

                Date.May ->
                    5

                Date.Jun ->
                    6

                Date.Jul ->
                    7

                Date.Aug ->
                    8

                Date.Sep ->
                    9

                Date.Oct ->
                    10

                Date.Nov ->
                    11

                Date.Dec ->
                    12
    in
        [ toString (Date.year date) ++ "/"
        , toPaddedString (toIntMonth date) ++ "/"
        , toPaddedString (Date.day date) ++ " "
        , toPaddedString (Date.hour date) ++ ":"
        , toPaddedString (Date.minute date) ++ ":"
        , toPaddedString (Date.second date)
        ]
            |> String.join ""


dateToFineString : Date.Date -> String
dateToFineString date =
    let
        milliseconds =
            date
                |> Date.millisecond
                |> toString
                |> String.padLeft 3 '0'
    in
        String.join "."
            [ dateToString date
            , milliseconds
            ]


shortenUrl : Url -> String
shortenUrl url =
    case String.split "://" url of
        [ "http", rest ] ->
            rest

        [ "https", rest ] ->
            rest

        _ ->
            url


stringToBool : String -> Bool
stringToBool string =
    case string of
        "true" ->
            True

        _ ->
            False


{-| Stringify any value into lowercased string.
Usually applied to Union Types to String conversions.
-}
toLowerString : x -> String
toLowerString x =
    x |> toString |> String.toLower


{-| Generate Cmd to just emit given `message`
-}
emit : msg -> Cmd msg
emit message =
    message |> Task.succeed |> Task.perform identity


emitIn : Milliseconds -> msg -> Cmd msg
emitIn ms message =
    Process.sleep ms
        |> Task.perform (always message)


randomLowerAlphaGen : Int -> Random.Generator String
randomLowerAlphaGen length =
    Random.int 0 25
        |> Random.map (\n -> Char.fromCode (n + 97))
        |> Random.list length
        |> Random.map String.fromList


isOk : Result a b -> Bool
isOk result =
    case result of
        Ok _ ->
            True

        Err _ ->
            False


isErr : Result a b -> Bool
isErr =
    not << isOk
