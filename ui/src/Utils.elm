module Utils
    exposing
        ( Timestamp
        , Url
        , listDeleteAt
        , encodeMaybe
        , dictGetWithDefault
        , ite
        , stringIndexedMap
        , timestampToString
        , dateToString
        , dateToFineString
        , shortenUrl
        , stringToBool
        )

import Date
import Dict exposing (Dict)
import Json.Encode


type alias Timestamp =
    String


type alias Url =
    String


listDeleteAt : Int -> List x -> List x
listDeleteAt nonNegIndex list =
    let
        folder elem ( index, accList ) =
            if index == nonNegIndex then
                ( index + 1, accList )
            else
                ( index + 1, elem :: accList )
    in
        list
            |> List.foldl folder ( 0, [] )
            |> Tuple.second
            |> List.reverse


encodeMaybe : (x -> Json.Encode.Value) -> Maybe x -> Json.Encode.Value
encodeMaybe encoder maybeValue =
    case maybeValue of
        Nothing ->
            Json.Encode.null

        Just value ->
            encoder value


dictGetWithDefault : comparable -> v -> Dict comparable v -> v
dictGetWithDefault key default dict =
    dict |> Dict.get key |> Maybe.withDefault default


{-| Stands for If-Then-Else, can be written inline.
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
