module Repo.Messages exposing (Msg(..))

import Http
import Utils
import Repo
import Error


type Msg x
    = OnFetchOne (Result Http.Error (Repo.Entity x))
    | OnNavigateAndFetchOne (Result Http.Error (Repo.Entity x))
    | OnFetchAll (Result Http.Error (List (Repo.Entity x)))
    | Sort (Repo.Sorter x)
    | ConfirmDelete (Repo.Entity x)
    | CancelDelete
    | Delete Repo.EntityId
    | OnDelete (Result Http.Error ())
    | StartEdit Repo.EntityId (Repo.Entity x)
    | OnEdit Repo.EntityId ( String, Maybe String ) x
    | OnValidate Repo.EntityId ( String, Maybe String ) -- Shorthand to set audit entry
    | OnEditValid Repo.EntityId x -- Shorthand used for fields without validations
    | CancelEdit Repo.EntityId
    | Create Repo.EntityId x -- Takes ID in order to accept both "new" and "newHipchat" in Authentication
    | OnCreate Repo.EntityId (Result Http.Error (Repo.Entity x))
    | Update Repo.EntityId x
    | OnUpdate (Result Http.Error (Repo.Entity x))
    | SetErrors (List Error.Error)
    | NoOp
    | ChangeLocation Utils.Url -- Should be handled by root Update
