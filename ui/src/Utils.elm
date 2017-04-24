module Utils exposing (..)


type Ord
    = Asc
    | Desc


{-| Currently, only string field can be sorted
-}
type alias Sorter obj =
    ( obj -> String, Ord )
