module Error exposing (Error, Kind(..), one, singleton)

{-
   Purposefully avoiding "Type" or "Message",
   since they are too generic and used everywhere
-}


type alias Error =
    ( Kind, Desc )


type Kind
    = APIError
    | NetworkError
    | UnexpectedError


type alias Label =
    String


type alias Desc =
    List ( Label, String )


{-| Shorthand for generating one elemet error.
-}
one : Kind -> Label -> String -> Error
one kind label1 text1 =
    ( kind, [ ( label1, text1 ) ] )


{-| Shorthand for generating one element error wrapped in list.
-}
singleton : Kind -> Label -> String -> List Error
singleton kind label1 text1 =
    [ one kind label1 text1 ]
