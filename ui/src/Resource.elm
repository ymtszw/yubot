module Resource exposing (..)

import Bootstrap.Modal as Modal exposing (hiddenState)
import Utils exposing (Sorter)


type alias Resource resource =
    { list : List resource
    , listSort : Maybe (Sorter resource)
    , deleteModal : ModalState resource
    , editModal : ModalState resource
    }


type alias ModalState resource =
    { modalState : Modal.State
    , target : resource
    }


initialResource : resource -> Resource resource
initialResource dummyResource =
    Resource
        []
        Nothing
        (DeleteModal hiddenState dummyResource)
        (EditModal hiddenState dummyResource)
