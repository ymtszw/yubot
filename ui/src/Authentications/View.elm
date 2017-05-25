module Authentications.View exposing (listView, authCheck, authSelect)

import Html exposing (Html, text)
import Html.Attributes exposing (for, value, selected)
import Html.Utils exposing (toggleSortOnClick, mx2Button)
import Bootstrap.Table as Table
import Bootstrap.Modal as Modal
import Bootstrap.Button as Button
import Bootstrap.Form as Form
import Bootstrap.Form.Checkbox as Checkbox
import Bootstrap.Form.Select as Select
import Utils
import Repo exposing (Repo)
import Repo.Messages exposing (Msg(..))
import Authentications exposing (Authentication)
import Poller.Styles as Styles


listView : Repo Authentication -> Html (Msg Authentication)
listView authRepo =
    Table.table
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


authRow : Repo.Entity Authentication -> Table.Row (Msg Authentication)
authRow authentication =
    Table.tr []
        [ Table.td [] [ text authentication.data.name ]
        , Table.td [] [ text authentication.data.type_ ]
        , Table.td [] [ text (Utils.timestampToString authentication.updatedAt) ]
        , Table.td []
            [ mx2Button (OnDeleteModal Modal.visibleState authentication) [ Button.disabled True, Button.small ] "Delete"
            ]
        ]


authCheck : List (Repo.Entity Authentication) -> Maybe Repo.EntityId -> (Repo.EntityId -> Bool -> Msg x) -> Html (Msg x)
authCheck authList maybeAuthId onCheck =
    let
        ( disabled, headAuthId ) =
            case authList of
                [] ->
                    ( True, "" )

                hd :: _ ->
                    ( False, hd.id )

        checked =
            case maybeAuthId of
                Nothing ->
                    False

                Just _ ->
                    True
    in
        Html.small []
            [ Checkbox.checkbox
                [ Checkbox.checked checked
                , Checkbox.disabled disabled
                , Checkbox.onCheck (onCheck headAuthId)
                ]
                "Require authentication?"
            ]


authSelect : List (Repo.Entity Authentication) -> String -> Maybe Repo.EntityId -> (Repo.EntityId -> Msg x) -> Html (Msg x)
authSelect authList label maybeAuthId onSelect =
    let
        itemText auth =
            text (auth.data.name ++ " (" ++ auth.id ++ ")")

        item auth =
            if maybeAuthId == Just auth.id then
                Select.item [ value auth.id, selected True ] [ itemText auth ]
            else
                Select.item [ value auth.id ] [ itemText auth ]

        select =
            authList
                |> List.map item
                |> Select.select
                    [ Select.id (label ++ "-auth")
                    , Select.onInput onSelect
                    ]
    in
        case maybeAuthId of
            Nothing ->
                text ""

            Just _ ->
                Form.group []
                    [ Form.label [ for (label ++ "-auth") ] [ text "Credential for URL" ]
                    , select
                    ]
