module Poller exposing (..)

import Html exposing (Html, div, text, program)
import Polls exposing (..)
import Polls.List exposing (..)

-- MODEL

type alias Model =
    { polls : List Poll
    }

initialModel : Model
initialModel =
    { polls = [ Poll "dummy_id" "2017-04-07T01:55:00+09:00" ]
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
    div []
        [ page model ]

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
