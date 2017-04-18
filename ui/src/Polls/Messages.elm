module Polls.Messages exposing (..)

import Http
import Bootstrap.Modal
import Polls exposing (Poll)

type Msg
    = OnFetchAll (Result Http.Error (List Poll))
    | OnDeleteModal Bootstrap.Modal.State Poll
    | OnDeleteConfirmed String
    | OnDelete (Result Http.Error ())
