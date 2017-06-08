module Polls.View exposing (cardsView)

import Html exposing (Html, text)
import Html.Attributes exposing (class)
import Bootstrap.Button as Button
import Utils
import Repo exposing (Repo)
import Repo.Messages exposing (Msg(..))
import Polls exposing (Poll)
import Styles


cardsView : Repo Poll -> Html (Msg Poll)
cardsView pollRepo =
    let
        card poll =
            Html.div [ class "card text-center btn-secondary" ]
                [ Html.div [ class "card-header" ] [ Html.h4 [] [ text (Utils.shortenUrl poll.data.url) ] ]
                , Html.div [ class "card-block alert-success" ]
                    [ Html.h4 [ class "card-title" ] [ text "Status: OK" ]
                    , Html.p [ class "card-text" ] [ text ("Run: " ++ (Polls.intervalToString poll.data.interval)) ]
                    ]
                , Html.div [ class "card-footer" ]
                    [ Html.small [ Styles.xSmall ] [ text ("Last run at: " ++ (Utils.timestampToString poll.updatedAt)) ] ]
                ]

        createCard =
            Html.div [ class "card text-center h-100" ]
                [ Html.div [ class "card-header" ] [ Html.h4 [] [ text "New Poll" ] ]
                , Html.div [ class "card-block" ] [ Button.button [ Button.primary ] [ text "Create" ] ]
                , Html.div [ class "card-footer" ] []
                ]

        wrapCol html =
            Html.div [ class "col-lg-3 col-md-4 col-sm-6 my-2" ] [ html ]
    in
        pollRepo.dict
            |> Repo.dictToSortedList pollRepo.sort
            |> List.map card
            |> (::) createCard
            |> List.map wrapCol
            |> Html.div [ class "row" ]
