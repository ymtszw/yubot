module Utils exposing (..)


type Ord
    = Asc
    | Desc


{-| Currently, only string field can be sorted
-}
type alias Sorter resource =
    ( resource -> String, Ord )
