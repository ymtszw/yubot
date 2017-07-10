module Repo
    exposing
        ( Repo
        , Entity
        , EntityId
        , EntityDict
        , DirtyDict
        , Audit
        , AuditId
        , AuditEntry(..)
        , Sorter
        , Ord(..)
        , ModalState
        , dummyEntity
        , populate
        , dummyAudit
        , genAuditId
        , getAuditIn
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
import Random
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
    Dict AuditId AuditEntry


{-| Client-side tracking ID of validatable fields.
For uniquely identifiable fields, just use field name variants should suffice. (e.g. "Method" in Action)
For non-unique fields (listed fields; e.g. Polls.trigger), some random yet session-consistent ID is required.
-}
type alias AuditId =
    String


type AuditEntry
    = Complaint String
    | Nested Audit


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


{-| Generate random lowercase string as `AuditId`s.
It generates `count` number of `AuditId` in list.
-}
genAuditId : (List AuditId -> msg) -> Int -> Cmd msg
genAuditId msg count =
    Utils.randomLowerAlphaGen 12
        |> Random.list count
        |> Random.generate msg


put : Entity x -> Repo a x -> Repo a x
put ({ id } as newEntity) ({ dict } as repo) =
    { repo | dict = (Dict.insert id newEntity dict) }


get : EntityId -> Repo a x -> Maybe (Entity x)
get id { dict } =
    Dict.get id dict


onEdit : DirtyDict x -> EntityId -> List ( List AuditId, Maybe String ) -> x -> DirtyDict x
onEdit dirtyDict entityId auditUpdates dirtyData =
    let
        updateAudit ( auditIdPath, maybeComplaint ) audit =
            updateAuditIn auditIdPath maybeComplaint audit

        updateFun ( dirtyEntity, audit ) =
            ( { dirtyEntity | data = dirtyData }, auditUpdates |> List.foldl updateAudit audit )

        new =
            ( dummyEntity dirtyData, auditUpdates |> List.foldl updateAudit Dict.empty )
    in
        Utils.dictUpsert entityId updateFun new dirtyDict


getAuditIn : List AuditId -> Audit -> Maybe AuditEntry
getAuditIn idPath audit =
    case idPath of
        [] ->
            -- Empty path; meanlingless call
            Nothing

        [ id ] ->
            Dict.get id audit

        id :: ids ->
            case Dict.get id audit of
                Nothing ->
                    Nothing

                Just (Complaint _) ->
                    Nothing

                Just (Nested nestedAudit) ->
                    getAuditIn ids nestedAudit


updateAuditIn : List AuditId -> Maybe String -> Audit -> Audit
updateAuditIn idPath maybeComplaint audit =
    updateAuditInImpl idPath maybeComplaint identity audit


updateAuditInImpl : List AuditId -> Maybe String -> (Audit -> Audit) -> Audit -> Audit
updateAuditInImpl idPathTail maybeComplaint updateFun audit =
    case idPathTail of
        [] ->
            -- Empty path; meanlingless call, just returning audit
            audit

        [ id ] ->
            updateFun (updateAuditLeaf id maybeComplaint audit)

        id :: ids ->
            makeNextUpdateFunAndRecurse id ids maybeComplaint updateFun audit


updateAuditLeaf : AuditId -> Maybe String -> Audit -> Audit
updateAuditLeaf id maybeComplaint audit =
    case maybeComplaint of
        Nothing ->
            Dict.remove id audit

        Just message ->
            Dict.insert id (Complaint message) audit


makeNextUpdateFunAndRecurse : AuditId -> List AuditId -> Maybe String -> (Audit -> Audit) -> Audit -> Audit
makeNextUpdateFunAndRecurse id ids maybeComplaint updateFun audit =
    case Dict.get id audit of
        Nothing ->
            updateAuditInImpl ids maybeComplaint (updateFun << updateOrRemoveNestedAudit id audit) Dict.empty

        Just (Complaint _) ->
            -- idPath stops at leaf; path is somewhat incorrect
            updateFun audit

        Just (Nested nestedAudit) ->
            updateAuditInImpl ids maybeComplaint (updateFun << updateOrRemoveNestedAudit id audit) nestedAudit


updateOrRemoveNestedAudit : AuditId -> Audit -> Audit -> Audit
updateOrRemoveNestedAudit id audit nestedAudit =
    if Dict.isEmpty nestedAudit then
        Dict.remove id audit
    else
        Dict.insert id (Nested nestedAudit) audit


{-| Set audit entry for `entityId`. You must first put dirty entity for `entityId` in `dirtyDict`.
If the entry for `entityId` does not exist, it does nothing.
-}
onValidate : DirtyDict x -> EntityId -> List AuditId -> Maybe String -> DirtyDict x
onValidate dirtyDict entityId auditIdPath maybeComplaint =
    Dict.update entityId (Maybe.map (Tuple.mapSecond (updateAuditIn auditIdPath maybeComplaint))) dirtyDict


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
