module Poller.Model exposing (Model, initialModel)

import Json.Encode
import Json.Decode as Decode
import Dict exposing (Dict)
import Set exposing (Set)
import Bootstrap.Navbar as Navbar
import Utils
import Routing
import Repo
import Polls exposing (Poll)
import Actions exposing (Action)
import Authentications exposing (Authentication)


type alias Model =
    { pollRepo : Repo.Repo Poll
    , actionRepo : Repo.Repo Action
    , actionFilter : Set Actions.ActionType
    , authRepo : Repo.Repo Authentication
    , navbarState : Navbar.State
    , route : Routing.Route
    , isDev : Bool
    , assetInventory : Dict String Utils.Url
    }


initialModel : Bool -> Json.Encode.Value -> Routing.Route -> Navbar.State -> Model
initialModel isDev assetInventory route navbarState =
    let
        decodedInventory =
            assetInventory
                |> Decode.decodeValue (Decode.dict Decode.string)
                |> Result.withDefault Dict.empty
    in
        { pollRepo = Repo.initialize Polls.dummyPoll
        , actionRepo = Repo.initialize Actions.dummyAction
        , actionFilter = Set.empty
        , authRepo = Repo.initialize Authentications.dummyAuthentication
        , navbarState = navbarState
        , route = route
        , isDev = isDev
        , assetInventory = decodedInventory
        }
