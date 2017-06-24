module Actions.ViewParts exposing (variableList, target, preview, renderBodyTemplate)

import Dict
import Regex exposing (HowMany(..))
import Html exposing (Html, text)
import Html.Attributes exposing (class)
import StringTemplate exposing (StringTemplate)
import Actions exposing (Action)
import ViewParts exposing (none, autoLink)


variableList : List String -> Html msg
variableList variables =
    let
        varCodes =
            variables
                |> List.map (\var -> Html.code [] [ text var ])
                |> List.intersperse (text ", ")
    in
        case variables of
            [] ->
                none

            _ ->
                varCodes
                    |> (::) (text "Variables: ")
                    |> Html.p []


target : Action -> Html msg
target { method, url } =
    Html.p []
        [ text "Target: "
        , Html.code [] (autoLink ((toString method) ++ " " ++ url))
        ]


preview : Action -> Html msg
preview ({ bodyTemplate } as action) =
    Html.div [ class "action-preview" ]
        [ target action
        , ViewParts.codeBlock [] (highlightVariables bodyTemplate.body)
        , variableList bodyTemplate.variables
        ]


highlightVariables : StringTemplate.Body -> List (Html msg)
highlightVariables body =
    let
        findFirst =
            Regex.find (AtMost 1) (Regex.regex "#\\{(.*?)\\}")

        leftToHtml string matchedVar index =
            case index of
                0 ->
                    ( [ Html.strong [ class "text-danger" ] [ text matchedVar ] ]
                    , String.dropLeft (String.length matchedVar) string
                    )

                _ ->
                    ( [ text (String.left index string), Html.strong [ class "text-danger" ] [ text matchedVar ] ]
                    , String.dropLeft (index + String.length matchedVar) string
                    )

        highlightVariablesImpl bodyTail htmls =
            case bodyTail of
                "" ->
                    htmls

                _ ->
                    case findFirst bodyTail of
                        [] ->
                            htmls ++ [ text bodyTail ]

                        { match, index } :: _ ->
                            -- Expect only one at most
                            let
                                ( newHtmls, newTail ) =
                                    leftToHtml bodyTail match index
                            in
                                highlightVariablesImpl newTail (htmls ++ newHtmls)
    in
        highlightVariablesImpl body []


renderBodyTemplate : StringTemplate -> Actions.TrialValues -> Html msg
renderBodyTemplate { body, variables } values =
    let
        renderOrKeep variable body =
            case Dict.get variable values of
                Just "" ->
                    body

                Nothing ->
                    body

                Just value ->
                    StringTemplate.render variable value body

        renderedHtmls =
            case body of
                "" ->
                    [ Html.span [ class "text-muted" ] [ text "(no body)" ] ]

                _ ->
                    variables |> List.foldl renderOrKeep body |> highlightVariables
    in
        ViewParts.codeBlock [] renderedHtmls
