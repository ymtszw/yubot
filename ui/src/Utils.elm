module Utils
    exposing
        ( Timestamp
        , Url
        , Method(..)
        , methods
        , stringToMethod
        , isJust
        , isNothing
        , listDeleteAt
        , listConsIf
        , listAppendIf
        , encodeMaybe
        , boolToMaybe
        , dictGetWithDefault
        , dictUpsert
        , ite
        , stringIndexedMap
        , stringCountChar
        , stringMapWithDefault
        , stringSplitAt
        , timestampToString
        , dateToString
        , dateToFineString
        , shortenUrl
        , stringToBool
        , toLowerString
        , emit
        )

import Date
import Dict exposing (Dict)
import Json.Encode
import Task


type alias Timestamp =
    String


type alias Url =
    String


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


isJust : Maybe x -> Bool
isJust maybe =
    case maybe of
        Just _ ->
            True

        Nothing ->
            False


isNothing : Maybe x -> Bool
isNothing =
    not << isJust


{-| Produces a new list by removing an element at the targetIndex.
Negative targetIndex indicates an offset from the end of the list.
If targetIndex is out of bounds, the original list is returned.
-}
listDeleteAt : Int -> List x -> List x
listDeleteAt targetIndex list =
    let
        folder proceed elem ( index, accList ) =
            if index == targetIndex then
                ( proceed index 1, accList )
            else
                ( proceed index 1, elem :: accList )
    in
        if targetIndex >= 0 then
            list
                |> List.foldl (folder (+)) ( 0, [] )
                |> Tuple.second
                |> List.reverse
        else
            list
                |> List.foldr (folder (-)) ( -1, [] )
                |> Tuple.second


listConsIf : Bool -> a -> List a -> List a
listConsIf shouldCons toCons list =
    if shouldCons then
        toCons :: list
    else
        list


listAppendIf : Bool -> List a -> List a -> List a
listAppendIf shouldAppend toAppend list =
    if shouldAppend then
        list ++ toAppend
    else
        list


encodeMaybe : (x -> Json.Encode.Value) -> Maybe x -> Json.Encode.Value
encodeMaybe encoder maybeValue =
    case maybeValue of
        Nothing ->
            Json.Encode.null

        Just value ->
            encoder value


boolToMaybe : x -> Bool -> Maybe x
boolToMaybe something bool =
    ite bool (Just something) Nothing


dictGetWithDefault : comparable -> v -> Dict comparable v -> v
dictGetWithDefault key default dict =
    dict |> Dict.get key |> Maybe.withDefault default


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


stringCountChar : Char -> String -> Int
stringCountChar char string =
    String.foldl (\x -> ite (x == char) ((+) 1) identity) 0 string


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


stringSplitAt : Int -> String -> ( String, String )
stringSplitAt index string =
    ( String.left index string, String.dropLeft index string )


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
