module Resource.Messages exposing (Msg(..))

import Http
import Bootstrap.Modal
import Utils exposing (EntityId, ErrorMessage)
import Resource exposing (Sorter)


type Msg resource
    = OnFetchAll (Result Http.Error (List resource))
    | OnSort (Sorter resource)
    | OnDeleteModal Bootstrap.Modal.State resource
    | OnDeleteConfirmed EntityId
    | OnDelete (Result Http.Error ())
    | OnEditModal Bootstrap.Modal.State resource
    | OnEditInput resource
    | OnEditInputWithError resource ErrorMessage
