module Utils
    exposing
        ( EntityId
        , Timestamp
        , Url
        , ErrorMessage
        , timestampToString
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


timestampToString : Timestamp -> String
timestampToString string =
    case Date.fromString string of
        Ok date ->
            toString date

        Err x ->
            "Invalid updatedAt!"
