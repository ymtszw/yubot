module Actions.ViewParts exposing (variableList, target, preview, renderBodyTemplate)

import Dict
import Regex exposing (HowMany(..))
import Html exposing (Html, text)
import Html.Attributes exposing (class)
import Utils exposing (ite)
import StringTemplate exposing (StringTemplate)
import Actions exposing (Action, ActionType(..))
import Actions.Hipchat exposing (UserParams, fetchParams)
import ViewParts exposing (none, autoLink)
import Styles


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
    Html.p [] [ text "Target: ", ViewParts.httpRequest method url ]


preview : Action -> Html msg
preview ({ type_ } as action) =
    case type_ of
        Http ->
            httpPreview action

        Hipchat ->
            hipchatPreview <| fetchParams <| action


httpPreview : Action -> Html msg
httpPreview ({ method, url, bodyTemplate } as action) =
    Html.dl [ class "action-preview" ]
        [ Html.dt [] [ text "Target" ]
        , Html.dd [] [ ViewParts.httpRequest method url ]
        , Html.dt [] [ text "BodyTemplate" ]
        , Html.dd [ class "small" ] (templatePreviewWithVariables bodyTemplate)
        ]


templatePreviewWithVariables : StringTemplate -> List (Html msg)
templatePreviewWithVariables { body, variables } =
    [ ViewParts.codeBlock [] (highlightVariables body)
    , variableList variables
    ]


hipchatPreview : UserParams -> Html msg
hipchatPreview { roomId, color, notify, messageTemplate } =
    Html.dl [ class "action-preview" ]
        [ Html.dt [] [ text "Room ID" ]
        , Html.dd [] [ text roomId ]
        , Html.dt [] [ text "Color" ]
        , Html.dd [ Styles.hipchatColor color ] [ text (toString color) ]
        , Html.dt [] [ text "Notify" ]
        , Html.dd [] [ text (ite notify "Yes" "No") ]
        , Html.dt [] [ text "MessageTemplate" ]
        , Html.dd [ class "small" ] <| templatePreviewWithVariables <| StringTemplate.parse <| messageTemplate
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
