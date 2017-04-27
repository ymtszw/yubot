module Actions.View exposing (..)

import Html exposing (Html, text)
import Html.Utils exposing (atext, mx2Button)
import Bootstrap.Table as Table exposing (table, th, tr, td, cellAttr)
import Bootstrap.Modal as Modal
import Bootstrap.Button as Button
import Resource exposing (Resource)
import Resource.Messages exposing (Msg(..))
import Actions exposing (Action)


listView : Resource Action -> Html (Msg Action)
listView actions =
    table
        { options = [ Table.striped ]
        , thead =
            Table.simpleThead
                [ th [] [ text "Method" ]
                , th [] [ text "URL" ]
                , th [] [ text "Body Template" ]
                , th [] [ text "Actions" ]
                ]
        , tbody = Table.tbody [] <| rows actions
        }


rows : Resource Action -> List (Table.Row (Msg Action))
rows actions =
    actions.list |> List.map actionRow


editActionButton : Action -> Button.Option (Msg Action) -> String -> Html (Msg Action)
editActionButton action option string =
    mx2Button (OnEditModal Modal.visibleState action) option string


actionRow : Action -> Table.Row (Msg Action)
actionRow action =
    tr []
        [ td [] [ text action.method ]
        , td [] (atext action.url)
        , td [] [ text action.bodyTemplate.body ]
        , td []
            [ editActionButton action Button.primary "Update"
            , mx2Button (OnDeleteModal Modal.visibleState action) Button.danger "Delete"
            ]
        ]
