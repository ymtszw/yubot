module Utils
    exposing
        ( Timestamp
        , Url
        , ErrorMessage
        , timestampToString
        , dateToString
        , dateToFineString
        , shortenUrl
        , stringToBool
        )

import Date


type alias Timestamp =
    String


type alias Url =
    String


type alias Label =
    String


type alias ErrorMessage =
    ( Label, String )


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
