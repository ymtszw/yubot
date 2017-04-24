module Polls.Messages exposing (..)

import Http
import Bootstrap.Modal
import Utils exposing (Sorter)
import Polls exposing (..)


type Msg
    = OnFetchAll (Result Http.Error (List Poll))
    | OnSort (Sorter Poll)
    | OnDeleteModal Bootstrap.Modal.State Poll
    | OnDeleteConfirmed String
    | OnDelete (Result Http.Error ())
    | OnEditModal Bootstrap.Modal.State Poll
