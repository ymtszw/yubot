module Actions.View exposing (..)

import Set exposing (Set)
import Html exposing (Html, text)
import Html.Utils exposing (atext, mx2Button, toggleSortOnClick, toDateString)
import Bootstrap.Table as Table exposing (table, th, tr, td, cellAttr)
import Bootstrap.Modal as Modal
import Bootstrap.Button as Button
import Resource exposing (Resource)
import Resource.Messages exposing (Msg(..))
import Actions exposing (Action)
import Poller.Styles exposing (sorting)


listView : Set String -> Resource Action -> Html (Msg Action)
listView usedActionIds actionRs =
    table
        { options = [ Table.striped ]
        , thead =
            Table.simpleThead
                [ th [] [ text "Method" ]
                , th [] [ text "URL" ]
                , th (List.map cellAttr [ sorting, toggleSortOnClick .updatedAt actionRs.listSort ]) [ text "Updated At" ]
                , th [] [ text "Actions" ]
                ]
        , tbody =
            actionRs
                |> rows usedActionIds
                |> Table.tbody []
        }


rows : Set String -> Resource Action -> List (Table.Row (Msg Action))
rows usedActionIds actionRs =
    actionRs.list |> List.map (actionRow usedActionIds)


editActionButton : Action -> List (Button.Option (Msg Action)) -> String -> Html (Msg Action)
editActionButton action options string =
    mx2Button (OnEditModal Modal.visibleState action) options string


actionRow : Set String -> Action -> Table.Row (Msg Action)
actionRow usedActionIds action =
    let
        ( deleteButtonOptions, deleteButtonString ) =
            if Set.member action.id usedActionIds then
                ( [ Button.disabled True, Button.small ], "Used" )
            else
                ( [ Button.danger, Button.small ], "Delete" )
    in
        tr []
            [ td [] [ text (String.toUpper action.method) ]
            , td [] (atext action.url)
            , td [] [ text (toDateString action.updatedAt) ]
            , td []
                [ editActionButton action [ Button.primary, Button.small ] "Update"
                , mx2Button (OnDeleteModal Modal.visibleState action) deleteButtonOptions deleteButtonString
                ]
            ]
