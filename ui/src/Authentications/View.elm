module Authentications.View exposing (listView)

import Set exposing (Set)
import Html exposing (Html, text)
import Html.Utils exposing (toggleSortOnClick, mx2Button)
import Bootstrap.Table as Table
import Bootstrap.Modal as Modal
import Bootstrap.Button as Button
import Repo exposing (Repo)
import Repo.Messages exposing (Msg(..))
import Authentications exposing (Authentication)


listView : Set Repo.EntityId -> Repo Authentication -> Html (Msg Authentication)
listView usedAuthIds authRepo =
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
                    |> List.map (authRow usedAuthIds)
                    |> Table.tbody []
            }
        , deleteModalView authRepo.deleteModal
        ]


authRow : Set Repo.EntityId -> Repo.Entity Authentication -> Table.Row (Msg Authentication)
authRow usedAuthIds authentication =
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

        ( deleteButtonOptions, deleteButtonString ) =
            if Set.member authentication.id usedAuthIds then
                ( [ Button.disabled True, Button.small ], "Used" )
            else
                ( [ Button.danger, Button.small ], "Delete" )
    in
        Table.tr []
            [ Table.td [] [ text authentication.data.name ]
            , Table.td [] [ text (toString authentication.data.type_) ]
            , Table.td [] [ Html.pre [] [ text (maskedToken) ] ]
            , Table.td []
                [ mx2Button (OnDeleteModal authentication Modal.visibleState) deleteButtonOptions deleteButtonString
                ]
            ]


deleteModalView : Repo.ModalState Authentication -> Html (Msg Authentication)
deleteModalView { target, modalState } =
    Modal.config (OnDeleteModal target)
        |> Modal.h4 [] [ text "Deleting Credential" ]
        |> Modal.body []
            [ Html.p [] [ text ("ID: " ++ target.id) ]
            , Html.pre [] [ text target.data.token ]
            , Html.p [] [ text "Are you sure?" ]
            ]
        |> Modal.footer []
            [ mx2Button (OnDeleteConfirmed target.id) [ Button.danger ] "Yes, delete"
            , mx2Button (OnDeleteModal target Modal.hiddenState) [] "Cancel"
            ]
        |> Modal.view modalState
