module Resource
    exposing
        ( Resource
        , Ord(..)
        , Sorter
        , ModalState
        , initialResource
        , sortList
        )

import Bootstrap.Modal as Modal exposing (hiddenState)
import Utils


type alias Resource resource =
    { list : List resource
    , listSort : Maybe (Sorter resource)
    , deleteModal : ModalState resource
    , editModal : ModalState resource
    }


type Ord
    = Asc
    | Desc


type alias Sorter resource =
    { property : resource -> String
    , order : Ord
    }


type alias ModalState resource =
    { modalState : Modal.State
    , target : resource
    , errorMessages : List Utils.ErrorMessage
    }


initialResource : resource -> Resource resource
initialResource dummyResource =
    Resource
        []
        Nothing
        (ModalState hiddenState dummyResource [])
        (ModalState hiddenState dummyResource [])


sortList : Sorter resource -> List resource -> List resource
sortList { property, order } list =
    case order of
        Asc ->
            List.sortBy property list

        Desc ->
            list
                |> List.sortBy property
                |> List.reverse
