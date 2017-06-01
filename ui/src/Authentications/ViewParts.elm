module Authentications.ViewParts exposing (authCheck, authSelect)

import Html exposing (Html, text)
import Html.Attributes as Attr
import Bootstrap.Form as Form
import Bootstrap.Form.Checkbox as Checkbox
import Bootstrap.Form.Select as Select
import Repo
import Authentications exposing (Authentication)


authCheck : List (Repo.Entity Authentication) -> Maybe Repo.EntityId -> (Repo.EntityId -> Bool -> msg) -> Html msg
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


authSelect : List (Repo.Entity Authentication) -> String -> Maybe Repo.EntityId -> (Repo.EntityId -> msg) -> Html msg
authSelect authList label maybeAuthId onSelect =
    let
        itemText auth =
            text (auth.data.name ++ " (" ++ auth.id ++ ")")

        item auth =
            if maybeAuthId == Just auth.id then
                Select.item [ Attr.value auth.id, Attr.selected True ] [ itemText auth ]
            else
                Select.item [ Attr.value auth.id ] [ itemText auth ]

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
                    [ Form.label [ Attr.for (label ++ "-auth") ] [ text "Credential for URL" ]
                    , select
                    ]
