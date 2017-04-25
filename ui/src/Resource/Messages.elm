module Resource.Messages exposing (..)

import Http
import Bootstrap.Modal
import Utils exposing (Sorter)


type Msg resource
    = OnFetchAll (Result Http.Error (List resource))
    | OnSort (Sorter resource)
    | OnDeleteModal Bootstrap.Modal.State resource
    | OnDeleteConfirmed String
    | OnDelete (Result Http.Error ())
    | OnEditModal Bootstrap.Modal.State resource
