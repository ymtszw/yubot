module Authentications.View exposing (listView, authCheck, authSelect)

import Html exposing (Html, text, small)
import Html.Attributes exposing (for, value, selected)
import Html.Utils exposing (toggleSortOnClick, mx2Button)
import Bootstrap.Table as Table exposing (th, tr, td, cellAttr)
import Bootstrap.Modal as Modal
import Bootstrap.Button as Button
import Bootstrap.Form as Form
import Bootstrap.Form.Checkbox as Checkbox
import Bootstrap.Form.Select as Select
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


authCheck : List Authentication -> Maybe Utils.EntityId -> (Utils.EntityId -> Bool -> Msg resourece) -> Html (Msg resourece)
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
        small []
            [ Checkbox.checkbox
                [ Checkbox.checked checked
                , Checkbox.disabled disabled
                , Checkbox.onCheck (onCheck headAuthId)
                ]
                "Require authentication?"
            ]


authSelect : List Authentication -> String -> Maybe Utils.EntityId -> (Utils.EntityId -> Msg resource) -> Html (Msg resource)
authSelect authList label maybeAuthId onSelect =
    let
        itemText auth =
            text (auth.name ++ " (" ++ auth.id ++ ")")

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
