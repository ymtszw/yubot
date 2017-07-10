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
    | InitNew Repo.EntityId (Repo.Entity x)
    | StartEdit Repo.EntityId (Repo.Entity x)
    | OnEdit Repo.EntityId (List ( List Repo.AuditId, Maybe String )) x
    | OnValidate Repo.EntityId ( List Repo.AuditId, Maybe String ) -- Shorthand to set audit entry
    | OnEditValid Repo.EntityId x -- Shorthand used for fields without validations
    | CancelEdit Repo.EntityId
    | Create Repo.EntityId x -- Takes ID in order to accept both "new" and "newHipchat" in Authentication
    | OnCreate Repo.EntityId (Result Http.Error (Repo.Entity x))
    | Update Repo.EntityId x
    | OnUpdate (Result Http.Error (Repo.Entity x))
    | DismissError Int
    | SetErrors (List Error.Error)
    | GenAuditIds Int (List Repo.AuditId -> Msg x)
    | NoOp
    | PromptLogin -- Handled by root Update
    | ChangeLocation Utils.Url -- Handled by root Update
