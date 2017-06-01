module Actions.ViewParts exposing (variableList, target, preview)

import Html exposing (Html, text)
import Html.Attributes exposing (class)
import Html.Utils exposing (atext, highlightVariables)
import Repo
import Repo.Messages exposing (Msg(..))
import Actions exposing (Action)
import Poller.Styles as Styles


variableList : List String -> Html (Msg x)
variableList variables =
    let
        varCodes =
            variables
                |> List.map (\var -> Html.code [] [ text var ])
                |> List.intersperse (text ", ")
    in
        case variables of
            [] ->
                text ""

            _ ->
                varCodes
                    |> (::) (text "Variables: ")
                    |> Html.p []


target : Repo.Entity Action -> Html (Msg x)
target action =
    Html.p []
        [ text "Target: "
        , Html.code [] (atext ((String.toUpper action.data.method) ++ " " ++ action.data.url))
        ]


preview : Repo.Entity Action -> Html (Msg x)
preview action =
    Html.div [ class "action-preview" ]
        [ target action
        , Html.pre [ Styles.greyBack, class "rounded", class "p-3" ] (highlightVariables action.data.bodyTemplate.body)
        , variableList action.data.bodyTemplate.variables
        ]
