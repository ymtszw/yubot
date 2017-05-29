module Authentications.View exposing (listView)

import Html exposing (Html, text)
import Html.Utils exposing (toggleSortOnClick, mx2Button)
import Bootstrap.Table as Table
import Bootstrap.Modal as Modal
import Bootstrap.Button as Button
import Repo exposing (Repo)
import Repo.Messages exposing (Msg(..))
import Authentications exposing (Authentication)


listView : Repo Authentication -> Html (Msg Authentication)
listView authRepo =
    Html.div []
        [ Table.table
            { options =
                [ Table.striped
                , Table.hover
                , Table.responsive
                , Table.small
                ]
            , thead =
                Table.simpleThead
                    [ Table.th [] [ text "Label" ]
                    , Table.th [] [ text "Type" ]
                    , Table.th [] [ text "Token" ]
                    , Table.th [] [ text "Actions" ]
                    ]
            , tbody =
                authRepo.dict
                    |> Repo.dictToSortedList authRepo.sort
                    |> List.map authRow
                    |> Table.tbody []
            }
        ]


authRow : Repo.Entity Authentication -> Table.Row (Msg Authentication)
authRow authentication =
    let
        maskedToken =
            authentication.data.token
                |> String.toList
                |> List.indexedMap
                    (\i x ->
                        if i < 5 then
                            x
                        else
                            '*'
                    )
                |> String.fromList
    in
        Table.tr []
            [ Table.td [] [ text authentication.data.name ]
            , Table.td [] [ text (toString authentication.data.type_) ]
            , Table.td [] [ Html.pre [] [ text (maskedToken) ] ]
            , Table.td []
                [ mx2Button (OnDeleteModal Modal.visibleState authentication) [ Button.disabled True, Button.small ] "Delete"
                ]
            ]
