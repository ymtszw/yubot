module Repo
    exposing
        ( Repo
        , Entity
        , EntityId
        , EntityDict
        , DirtyDict
        , Audit
        , Sorter
        , Ord(..)
        , ModalState
        , dummyEntity
        , populate
        , dummyAudit
        , put
        , get
        , onEdit
        , onValidate
        , dirtyGetWithDefault
        , required
        , isValid
        , toggleOrder
        , listToDict
        , dictToList
        , dictToSortedList
        )

import Dict exposing (Dict)
import Utils
import Error


type alias Repo a x =
    { a
        | dict : EntityDict x
        , sort : Sorter x
        , deleteModal : ModalState x
        , dirtyDict : DirtyDict x
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


type alias Audit =
    Dict String String


type alias DirtyDict x =
    Dict EntityId ( Entity x, Audit )


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


initialize : x -> Repo {} x
initialize =
    populate []


populate : List (Entity x) -> x -> Repo {} x
populate entities dummyData =
    { dict = listToDict entities
    , sort = Sorter .id Asc
    , deleteModal = ModalState False (dummyEntity dummyData)
    , dirtyDict = Dict.empty
    , errors = []
    }


dummyAudit : Dict x y
dummyAudit =
    Dict.empty


put : Entity x -> Repo a x -> Repo a x
put ({ id } as newEntity) ({ dict } as repo) =
    { repo | dict = (Dict.insert id newEntity dict) }


get : EntityId -> Repo a x -> Maybe (Entity x)
get id { dict } =
    Dict.get id dict


onEdit : DirtyDict x -> EntityId -> String -> Maybe String -> x -> DirtyDict x
onEdit dirtyDict entityId label maybeMessage dirtyData =
    let
        updateFun ( dirtyEntity, audit ) =
            ( { dirtyEntity | data = dirtyData }, updateAudit label maybeMessage audit )

        new =
            ( dummyEntity dirtyData, updateAudit label maybeMessage Dict.empty )
    in
        Utils.dictUpsert entityId updateFun new dirtyDict


updateAudit : String -> Maybe String -> Audit -> Audit
updateAudit label maybeMessage audit =
    case maybeMessage of
        Nothing ->
            Dict.remove label audit

        Just message ->
            Dict.insert label message audit


{-| Set audit entry for `entityId`. You must first put dirty entity for `entityId` in `dirtyDict`.
If the entry for `entityId` does not exist, it does nothing.
-}
onValidate : DirtyDict x -> EntityId -> String -> Maybe String -> DirtyDict x
onValidate dirtyDict entityId label maybeMessage =
    Dict.update entityId (Maybe.map (Tuple.mapSecond (updateAudit label maybeMessage))) dirtyDict


dirtyGetWithDefault : EntityId -> x -> DirtyDict x -> ( Entity x, Audit )
dirtyGetWithDefault dirtyId defaultData dirtyDict =
    Utils.dictGetWithDefault dirtyId ( dummyEntity defaultData, Dict.empty ) dirtyDict


{-| Convenient validator which validates non-emptiness.
-}
required : String -> Maybe String
required =
    Utils.boolToMaybe "This field is required" << String.isEmpty


isValid : Audit -> Bool
isValid audit =
    Dict.isEmpty audit


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


dictToList : EntityDict x -> List (Entity x)
dictToList dict =
    Dict.values dict


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
