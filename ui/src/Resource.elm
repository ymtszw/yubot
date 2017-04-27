module Resource exposing (..)

import Bootstrap.Modal as Modal exposing (hiddenState)
import Utils exposing (Sorter, flattenNestedKey)


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
        (ModalState hiddenState dummyResource)
        (ModalState hiddenState dummyResource)


flatten : Resource r -> Resource r -> List ( String, ( String, String ) )
flatten r1 r2 =
    List.concat
        [ [ ( "list", ( toString r1.list, toString r2.list ) )
          , ( "listSort", ( toString r1.listSort, toString r2.listSort ) )
          ]
        , List.map (flattenNestedKey "deleteModal") (flattenModalState r1.deleteModal r2.deleteModal)
        , List.map (flattenNestedKey "editModal") (flattenModalState r1.editModal r2.editModal)
        ]


flattenModalState : ModalState r -> ModalState r -> List ( String, ( String, String ) )
flattenModalState ms1 ms2 =
    [ ( "modalState", ( toString ms1.modalState, toString ms2.modalState ) )
    , ( "target", ( toString ms1.target, toString ms2.target ) )
    ]
