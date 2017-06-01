module Repo.Messages exposing (Msg(..))

import Http
import Bootstrap.Modal
import Utils
import Repo


type Msg x
    = OnFetchAll (Result Http.Error (List (Repo.Entity x)))
    | OnSort (Repo.Sorter x)
    | OnDeleteModal (Repo.Entity x) Bootstrap.Modal.State
    | OnDeleteConfirmed Repo.EntityId
    | OnDelete (Result Http.Error ())
    | OnEditInput x (List Utils.ErrorMessage)
    | OnEditStart (Repo.Entity x)
    | ChangeLocation Utils.Url -- Allow triggering ChangeLocation message from nested component; should be handled by root Update
