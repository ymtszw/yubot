module Error exposing (Error, Kind(..), one)

{-
   Purposefully avoiding "Type" or "Message",
   since they are too generic and used everywhere
-}


type alias Error =
    ( Kind, Desc )


type Kind
    = APIError
    | NetworkError
    | ValidationError
    | UnexpectedError


type alias Label =
    String


type alias Desc =
    List ( Label, String )


{-| Shorthand for generating one elemet error.
-}
one : Kind -> String -> String -> Error
one kind label1 text1 =
    ( kind, [ ( label1, text1 ) ] )
