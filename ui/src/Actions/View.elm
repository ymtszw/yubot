module Actions.View exposing (listView)

import Set exposing (Set)
import Html exposing (Html, text)
import Html.Utils exposing (atext, highlightVariables, mx2Button, toggleSortOnClick)
import Bootstrap.Table as Table
import Bootstrap.Modal as Modal
import Bootstrap.Button as Button
import Bootstrap.Modal as Modal
import Repo exposing (Repo)
import Repo.Messages exposing (Msg(..))
import Actions exposing (Action)
import Actions.Hipchat
import Actions.ViewParts


deleteModalView : Repo.ModalState Action -> Html (Msg Action)
deleteModalView { target, modalState } =
    Modal.config (OnDeleteModal target)
        |> Modal.h4 [] [ text "Deleting Action" ]
        |> Modal.body []
            [ Html.p [] [ text ("ID: " ++ target.id) ]
            , Actions.ViewParts.preview target
            , Html.p [] [ text "Are you sure?" ]
            ]
        |> Modal.footer []
            [ mx2Button (OnDeleteConfirmed target.id) [ Button.danger ] "Yes, delete"
            , mx2Button (OnDeleteModal target Modal.hiddenState) [] "Cancel"
            ]
        |> Modal.view modalState


listView : Set Repo.EntityId -> Repo Action -> Html (Msg Action)
listView usedActionIds actionRepo =
    Html.div []
        [ Table.table
            { options = [ Table.striped ]
            , thead =
                Table.simpleThead
                    [ Table.th [] [ text "Label" ]
                    , Table.th [] [ text "Summary" ]
                    , Table.th [] [ text "Actions" ]
                    ]
            , tbody =
                actionRepo
                    |> rows usedActionIds
                    |> Table.tbody []
            }
        , deleteModalView actionRepo.deleteModal
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
            [ Table.td [] [ text (Maybe.withDefault "(no label)" action.data.label) ]
            , Table.td [] [ actionSummary action ]
            , Table.td []
                [ mx2Button (OnDeleteModal action Modal.visibleState) deleteButtonOptions deleteButtonString
                ]
            ]


actionSummary : Repo.Entity Action -> Html (Msg Action)
actionSummary action =
    let
        hipchatSummary =
            let
                { color, notify, messageTemplate } =
                    Actions.Hipchat.fetchParams action.data

                notifyText =
                    if notify then
                        "On"
                    else
                        "Off"

                messageTemplateText =
                    case messageTemplate of
                        "" ->
                            "#{message}"

                        mt ->
                            mt
            in
                [ ("Color: " ++ (toString color))
                , ("Notify: " ++ notifyText)
                , ("Message: " ++ messageTemplateText)
                ]
                    |> String.join ", "
                    |> text
                    |> List.singleton
                    |> Html.p []
    in
        case action.data.type_ of
            Actions.Hipchat ->
                hipchatSummary

            Actions.Http ->
                Actions.ViewParts.target action
