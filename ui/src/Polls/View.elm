module Polls.View exposing (index, new, show)

import Html exposing (Html, text)
import Html.Attributes as Attr exposing (class)
import Html.Lazy as Z
import Bootstrap.Button as Button
import Utils
import Repo exposing (Repo)
import Repo.Messages exposing (Msg(..))
import Repo.ViewParts exposing (navigate)
import Polls exposing (Poll, Aux)
import Actions exposing (Action)
import Authentications exposing (Authentication)
import Styles
import ViewParts exposing (stdBtn)


-- Index


index : Repo Aux Poll -> Html Polls.Msg
index { dict, sort } =
    dict
        |> Repo.dictToSortedList sort
        |> List.map (Z.lazy card)
        |> (::) createCard
        |> List.map (List.singleton >> Html.div [ class "col-lg-3 col-md-4 col-sm-6 my-2" ])
        |> Html.div [ class "row" ]


card : Repo.Entity Poll -> Html Polls.Msg
card { id, updatedAt, data } =
    Html.div
        (List.append
            (navigate ("/polls/" ++ id))
            [ class "card text-center btn-secondary"
            , Styles.fakeLink
            ]
        )
        [ Html.div [ class "card-header" ] [ Html.h4 [] [ text (Utils.shortenUrl data.url) ] ]
        , Html.div [ class "card-block alert-success" ]
            [ Html.h4 [ class "card-title" ] [ text "Status: OK" ]
            , Html.p [ class "card-text" ] [ text ("Run: " ++ (Polls.intervalToString data.interval)) ]
            ]
        , Html.div [ class "card-footer" ]
            [ Html.small [ Styles.xSmall ] [ text ("Last run at: " ++ (Utils.timestampToString updatedAt)) ] ]
        ]
        |> Html.map Polls.RepoMsg


createCard : Html msg
createCard =
    Html.div [ class "card text-center h-100" ]
        [ Html.div [ class "card-header" ] [ Html.h4 [] [ text "New Poll" ] ]
        , Html.div [ class "card-block" ] [ stdBtn Button.primary [] False "Create" ]
        , Html.div [ class "card-footer" ] []
        ]



-- New


new : Repo.EntityDict Action -> Repo.EntityDict Authentication -> Repo Aux Poll -> Html Polls.Msg
new actionDict authDict ({ dirtyDict } as repo) =
    let
        (( { data }, audit ) as dirtyEntity) =
            Repo.dirtyGetWithDefault "new" Polls.dummyPoll dirtyDict
    in
        ViewParts.triPaneView
            [ Z.lazy titleNew data ]
            [ text "Main" ]
            [ text "bottom left" ]
            [ text "right" ]


titleNew : Poll -> Html Polls.Msg
titleNew data =
    Html.div
        [ class "d-flex justify-content-between align-items-center pb-2"
        , Styles.bottomBordered
        ]
        [ Html.div []
            [ Html.h2 [ class "mb-2" ]
                [ ViewParts.fa [ class "align-bottom mr-2" ] 2 "fa-calendar"
                , text "New Poll"
                ]
            ]
        , Html.div [] [ stdBtn Button.info [ Button.small, Button.onClick (CancelEdit "new") ] (data == Polls.dummyPoll) "Reset" ]
        ]
        |> Html.map Polls.RepoMsg



-- Show


show : Repo.EntityDict Action -> Repo.EntityDict Authentication -> Repo Aux Poll -> Repo.Entity Poll -> Html Polls.Msg
show actionDict authDict pollRepo poll =
    poll |> Z.lazy showImpl |> Html.map Polls.RepoMsg


showImpl : Repo.Entity Poll -> Html msg
showImpl { id } =
    ViewParts.triPaneView
        [ Html.h2 [] [ text id ] ]
        [ text "Main Form" ]
        [ text "Trial Form" ]
        [ text "Trial result" ]
