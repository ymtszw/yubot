module Authentications.View exposing (listView)

import Html exposing (Html, text)
import Html.Utils exposing (toggleSortOnClick, mx2Button)
import Bootstrap.Table as Table
import Bootstrap.Modal as Modal
import Bootstrap.Button as Button
import Utils
import Repo exposing (Repo)
import Repo.Messages exposing (Msg(..))
import Authentications exposing (Authentication)
import Poller.Styles as Styles


listView : Repo Authentication -> Html (Msg Authentication)
listView authRepo =
    Html.div []
        [ Table.table
            { options = [ Table.striped ]
            , thead =
                Table.simpleThead
                    [ Table.th [] [ text "Name" ]
                    , Table.th [] [ text "Type" ]
                    , Table.th (List.map Table.cellAttr [ Styles.sorting, toggleSortOnClick .updatedAt authRepo.sort ]) [ text "Updated At" ]
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
    Table.tr []
        [ Table.td [] [ text authentication.data.name ]
        , Table.td [] [ text (toString authentication.data.type_) ]
        , Table.td [] [ text (Utils.timestampToString authentication.updatedAt) ]
        , Table.td []
            [ mx2Button (OnDeleteModal Modal.visibleState authentication) [ Button.disabled True, Button.small ] "Delete"
            ]
        ]
