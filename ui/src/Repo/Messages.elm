module Repo.Messages exposing (Msg(..))

import Http
import Utils
import Repo
import Error


type Msg x
    = OnFetchAll (Result Http.Error (List (Repo.Entity x)))
    | OnSort (Repo.Sorter x)
    | OnDeleteModal (Repo.Entity x) Bool
    | OnDeleteConfirmed Repo.EntityId
    | OnDelete (Result Http.Error ())
    | OnEdit Repo.EntityId (Repo.Entity x) (List Error.Error)
    | OnEditCancel Repo.EntityId
    | OnSubmitNew x
    | OnCreate (Result Http.Error (Repo.Entity x))
    | SetErrors (List Error.Error)
    | ChangeLocation Utils.Url -- Should be handled by root Update
