module Repo
    exposing
        ( Repo
        , Entity
        , EntityId
        , EntityDict
        , Sorter
        , Ord(..)
        , ModalState
        , dummyEntity
        , initialize
        , populate
        , toggleOrder
        , listToDict
        , dictToSortedList
        )

import Dict exposing (Dict)
import Utils
import Error


type alias Repo x =
    { dict : EntityDict x
    , sort : Sorter x
    , deleteModal : ModalState x
    , dirtyDict : EntityDict x
    , errors : List Error.Error
    }


type alias Entity x =
    { id : EntityId
    , updatedAt : Utils.Timestamp
    , data : x
    }


{-| EntityId can be "new", in cases of creating new objects.
-}
type alias EntityId =
    String


type alias EntityDict x =
    Dict EntityId (Entity x)


type alias Sorter x =
    { property : Entity x -> String
    , order : Ord
    }


type Ord
    = Asc
    | Desc


type alias ModalState x =
    { isShown : Bool
    , target : Entity x
    }


dummyEntity : x -> Entity x
dummyEntity data =
    Entity "" "2015-01-01T00:00:00+00:00" data


initialize : x -> Repo x
initialize =
    populate []


populate : List (Entity x) -> x -> Repo x
populate entities dummyData =
    Repo
        (listToDict entities)
        (Sorter .id Asc)
        (ModalState False (dummyEntity dummyData))
        (Dict.singleton "new" (dummyEntity dummyData))
        []


toggleOrder : Ord -> Ord
toggleOrder oldOrder =
    case oldOrder of
        Asc ->
            Desc

        Desc ->
            Asc


listToDict : List (Entity x) -> EntityDict x
listToDict entities =
    entities
        |> List.map (\e -> ( e.id, e ))
        |> Dict.fromList


dictToSortedList : Sorter x -> EntityDict x -> List (Entity x)
dictToSortedList { property, order } dict =
    let
        list =
            Dict.values dict
    in
        case order of
            Asc ->
                List.sortBy property list

            Desc ->
                list
                    |> List.sortBy property
                    |> List.reverse
