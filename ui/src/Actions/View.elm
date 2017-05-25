module Actions.View exposing (listView)

import Set exposing (Set)
import Html exposing (Html, text)
import Html.Utils exposing (atext, highlightVariables, mx2Button, toggleSortOnClick)
import Bootstrap.Table as Table
import Bootstrap.Modal as Modal
import Bootstrap.Button as Button
import Utils
import Repo exposing (Repo)
import Repo.Messages exposing (Msg(..))
import Actions exposing (Action)
import Actions.ModalView
import Poller.Styles as Styles


listView : Set Repo.EntityId -> Repo Action -> Html (Msg Action)
listView usedActionIds actionRepo =
    Html.div []
        [ Table.table
            { options = [ Table.striped ]
            , thead =
                Table.simpleThead
                    [ Table.th [] [ text "Method" ]
                    , Table.th [] [ text "URL" ]
                    , Table.th (List.map Table.cellAttr [ Styles.sorting, toggleSortOnClick .updatedAt actionRepo.sort ]) [ text "Updated At" ]
                    , Table.th [] [ text "Actions" ]
                    ]
            , tbody =
                actionRepo
                    |> rows usedActionIds
                    |> Table.tbody []
            }
        , Actions.ModalView.deleteModalView actionRepo
        ]


rows : Set Repo.EntityId -> Repo Action -> List (Table.Row (Msg Action))
rows usedActionIds actionRepo =
    actionRepo.dict
        |> Repo.dictToSortedList actionRepo.sort
        |> List.map (actionRow usedActionIds)



-- editActionButton : Action -> List (Button.Option (Msg Action)) -> String -> Html (Msg Action)
-- editActionButton action options string =
--     mx2Button (OnEditModal Modal.visibleState action) options string


actionRow : Set Repo.EntityId -> Repo.Entity Action -> Table.Row (Msg Action)
actionRow usedActionIds action =
    let
        ( deleteButtonOptions, deleteButtonString ) =
            if Set.member action.id usedActionIds then
                ( [ Button.disabled True, Button.small ], "Used" )
            else
                ( [ Button.danger, Button.small ], "Delete" )
    in
        Table.tr []
            [ Table.td [] [ text (String.toUpper action.data.method) ]
            , Table.td [] (atext action.data.url)
            , Table.td [] [ text (Utils.timestampToString action.updatedAt) ]
            , Table.td []
                [ mx2Button (OnDeleteModal Modal.visibleState action) deleteButtonOptions deleteButtonString
                ]
            ]
