module Poller.Model exposing (..)

import Debug
import Bootstrap.Tab as Tab
import Bootstrap.Navbar as Navbar
import Utils exposing (flattenNestedKey)
import Resource exposing (Resource, initialResource)
import Polls exposing (Poll, dummyPoll)
import Actions exposing (Action, dummyAction)


type alias Model =
    { pollRs : Resource Poll
    , actionRs : Resource Action
    , tabState : Tab.State
    , navbarState : Navbar.State
    , verbose : Bool
    }


initialModel : Navbar.State -> Model
initialModel navbarState =
    { pollRs = initialResource dummyPoll
    , actionRs = initialResource dummyAction
    , tabState = Tab.initialState
    , navbarState = navbarState
    , verbose = False
    }


{-| Log diff of `model1` and `model2` and return `model2`.
Used for verbose logging.
-}
diffDump : Model -> Model -> Model
diffDump model1 model2 =
    let
        pairsAsString =
            List.concat
                [ List.map (flattenNestedKey "pollRs") (Resource.flatten model1.pollRs model2.pollRs)
                , List.map (flattenNestedKey "actionRs") (Resource.flatten model1.actionRs model2.actionRs)
                , [ ( "tabState", ( toString model1.tabState, toString model2.tabState ) )
                  , ( "navbarState", ( toString model1.navbarState, toString model2.navbarState ) )
                  , ( "verbose", ( toString model1.verbose, toString model2.verbose ) )
                  ]
                ]

        filterWithIdentity ( key, ( v1, v2 ) ) =
            v1 /= v2

        logNewValue ( key, ( v1, v2 ) ) =
            Debug.log key v2
    in
        pairsAsString
            |> List.filter filterWithIdentity
            |> List.map logNewValue
            |> always model2
