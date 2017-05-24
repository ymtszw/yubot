module Utils
    exposing
        ( EntityId
        , Timestamp
        , Url
        , ErrorMessage
        , timestampToString
        , shortenUrl
        )

import Date


type alias EntityId =
    String


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
    let
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
        case Date.fromString string of
            Ok date ->
                [ toString (Date.year date) ++ "/"
                , toString (toIntMonth date) ++ "/"
                , toString (Date.day date) ++ " "
                , toString (Date.hour date) ++ ":"
                , toString (Date.minute date) ++ ":"
                , toString (Date.second date)
                ]
                    |> String.join ""

            Err x ->
                "Invalid updatedAt!"


shortenUrl : Url -> String
shortenUrl url =
    case String.split "://" url of
        [ "http", rest ] ->
            rest

        [ "https", rest ] ->
            rest

        _ ->
            url
