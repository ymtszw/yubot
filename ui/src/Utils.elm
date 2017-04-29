module Utils
    exposing
        ( EntityId
        , Timestamp
        , Url
        , timestampToString
        )

import Date


type alias EntityId =
    String


type alias Timestamp =
    String


type alias Url =
    String


timestampToString : Timestamp -> String
timestampToString string =
    case Date.fromString string of
        Ok date ->
            toString date

        Err x ->
            "Invalid updatedAt!"
