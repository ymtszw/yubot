module Polls.View exposing (cardsView)

import Html exposing (Html, text)
import Html.Attributes exposing (class)
import Bootstrap.Button as Button
import Utils
import Repo exposing (Repo)
import Repo.Messages exposing (Msg(..))
import Polls exposing (Poll)
import Poller.Styles as Styles


cardsView : Repo Poll -> Html (Msg Poll)
cardsView pollRepo =
    let
        card poll =
            Html.div [ class "card text-center btn-secondary" ]
                [ Html.div [ class "card-header" ] [ Html.h4 [] [ text (Utils.shortenUrl poll.data.url) ] ]
                , Html.div [ class "card-block alert-success" ]
                    [ Html.h4 [ class "card-title" ] [ text "Status: OK" ]
                    , Html.p [ class "card-text" ] [ text ("Run: " ++ (Polls.intervalToString poll.data.interval)) ]
                    , Html.p [ class "card-text" ] [ text ("Action: " ++ poll.data.action) ]
                    ]
                , Html.div [ class "card-footer" ]
                    [ Html.small [ Styles.xSmall ] [ text ("Last run at: " ++ (Utils.timestampToString poll.updatedAt)) ] ]
                ]

        cardWithWrap poll =
            Html.div [ class "col-lg-3 col-md-4 col-sm-6 my-2" ] [ card poll ]
    in
        pollRepo.dict
            |> Repo.dictToSortedList pollRepo.sort
            |> List.map cardWithWrap
            |> (::) createPollCard
            |> Html.div [ class "row" ]


createPollCard : Html (Msg Poll)
createPollCard =
    Html.div [ class "col-lg-3 col-md-4 col-sm-6 my-2" ]
        [ Html.div [ class "card text-center h-100" ]
            [ Html.div [ class "card-header" ] [ Html.h4 [] [ text "New Poll" ] ]
            , Html.div [ class "card-block" ] [ Button.button [ Button.primary ] [ text "Create" ] ]
            , Html.div [ class "card-footer" ] []
            ]
        ]
