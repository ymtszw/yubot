module Actions.View exposing (..)

import Html exposing (Html, text)
import Html.Utils exposing (atext)
import Bootstrap.Table as Table exposing (table, th, tr, td, cellAttr)
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


actionRow : Action -> Table.Row (Msg Action)
actionRow action =
    tr []
        [ td [] [ text action.method ]
        , td [] (atext action.url)
        , td [] [ text action.bodyTemplate.body ]
        , td [] []
        ]
