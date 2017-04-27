module Utils exposing (..)


type Ord
    = Asc
    | Desc


{-| Currently, only string field can be sorted
-}
type alias Sorter resource =
    ( resource -> String, Ord )


{-| Used for destructuring and dumping nested Model into console
-}
flattenNestedKey : String -> ( String, ( String, String ) ) -> ( String, ( String, String ) )
flattenNestedKey parentKey ( childKey, valueTuple ) =
    ( parentKey ++ "." ++ childKey, valueTuple )
