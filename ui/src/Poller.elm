module Poller exposing (..)

import Date exposing (Date)
import Html exposing (Html, div, h1, text, program)
import Bootstrap.Grid as Grid
import Polls exposing (..)
import Polls.List exposing (..)

-- MODEL

type alias Model =
    { polls : List Poll
    }

initialModel : Model
initialModel =
    { polls = [ Poll "dummy_id" (Date.fromTime 1491501715000) ]
    }



init : ( Model, Cmd Msg )
init =
    ( initialModel, Cmd.none )

-- MESSAGES

type Msg
    = PollsMsg Polls.Msg

-- UPDATE

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PollsMsg subMsg ->
            let
                ( updatedPolls, cmd ) =
                    Polls.update subMsg model.polls
            in
                ( { model | polls = updatedPolls}, Cmd.map PollsMsg cmd )

-- VIEW

view : Model -> Html Msg
view model =
    Grid.container []
        [ Grid.simpleRow
            [ Grid.col []
                [ h1 [] [ text "Poller the Bear" ]
                ]
            ]
        , Grid.simpleRow
            [ Grid.col [] [ page model ]
            ]
        ]

page : Model -> Html Msg
page model =
    Html.map PollsMsg (Polls.List.view model.polls)

-- SUBSCRIPTIONS

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none

-- MAIN

main : Program Never Model Msg
main =
    program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
