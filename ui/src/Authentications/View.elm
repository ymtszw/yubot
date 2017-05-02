module Authentications.View exposing (listView)

import Html exposing (Html, text)
import Html.Utils exposing (toggleSortOnClick, mx2Button)
import Bootstrap.Table as Table exposing (th, tr, td, cellAttr)
import Bootstrap.Modal as Modal
import Bootstrap.Button as Button
import Utils exposing (timestampToString)
import Resource exposing (Resource)
import Resource.Messages exposing (Msg(..))
import Authentications exposing (Authentication)
import Poller.Styles exposing (sorting)


listView : Resource Authentication -> Html (Msg Authentication)
listView authRs =
    Table.table
        { options = [ Table.striped ]
        , thead =
            Table.simpleThead
                [ th [] [ text "Name" ]
                , th [] [ text "Type" ]
                , th (List.map cellAttr [ sorting, toggleSortOnClick .updatedAt authRs.listSort ]) [ text "Updated At" ]
                , th [] [ text "Actions" ]
                ]
        , tbody =
            Table.tbody [] (List.map authRow authRs.list)
        }


authRow : Authentication -> Table.Row (Msg Authentication)
authRow authentication =
    tr []
        [ td [] [ text authentication.name ]
        , td [] [ text authentication.type_ ]
        , td [] [ text (timestampToString authentication.updatedAt) ]
        , td []
            [ mx2Button (OnEditModal Modal.visibleState authentication) [ Button.disabled True, Button.small ] "Update"
            , mx2Button (OnDeleteModal Modal.visibleState authentication) [ Button.disabled True, Button.small ] "Delete"
            ]
        ]
