module Repo.ViewParts exposing (..)

import Dict
import Regex
import Html exposing (Html, text)
import Html.Attributes as Attr exposing (class)
import Html.Events as Events
import Bootstrap.Button as Button
import Maybe.Extra exposing (isNothing)
import List.Extra
import Utils exposing (ite)
import Repo exposing (Repo, AuditEntry(..))
import Repo.Messages exposing (Msg(..))
import Styles
import ViewParts exposing (none)
import Error


errorToast : List Error.Error -> Html (Msg x)
errorToast errors =
    let
        errorText label string =
            case string of
                "" ->
                    label

                _ ->
                    label ++ ": " ++ string

        alert index ( kind, desc, dismissed ) =
            Html.div [ class ("alert alert-danger alert-dismissible fade" ++ ite dismissed "" " show"), Styles.toast ]
                [ Html.a [ class "close", Events.onClick (DismissError index) ] [ Html.span [] [ text "×" ] ]
                , Html.h6 [ class "alert-heading" ] [ kind |> toString |> text ]
                , desc
                    |> List.map (\( label, string ) -> Html.li [] [ text (errorText label string) ])
                    |> Html.ul []
                ]
    in
        case errors of
            [] ->
                none

            _ ->
                errors
                    |> List.indexedMap alert
                    |> Html.div [ class "text-muted small" ]


navigate : Utils.Url -> List (Html.Attribute (Msg x))
navigate =
    ViewParts.navigate ChangeLocation


toggleSortOnClick : (Repo.Entity x -> String) -> Repo.Sorter x -> Html.Attribute (Msg x)
toggleSortOnClick newProperty sorter =
    let
        newOrder =
            Repo.toggleOrder sorter.order
    in
        Events.onClick (Sort (Repo.Sorter newProperty newOrder))


inputGroup : String -> String -> Bool -> Repo.Audit -> List Repo.AuditId -> (String -> Html msg) -> Html msg
inputGroup formId label isInline audit auditIdPath inputHtmlFun =
    let
        inputId =
            makeInputId formId label

        labelOptions =
            [ Attr.for inputId, class ("form-control-label" ++ (ite isInline " sr-only" "")) ]

        ( formClass, feedback ) =
            case Repo.getAuditIn auditIdPath audit of
                Just (Complaint complaint) ->
                    ( class "form-group has-danger", Html.div [ class "form-control-feedback small" ] [ text complaint ] )

                Just (Nested _) ->
                    -- Put has-danger on higher level form-group, though actual message should be on the leaf
                    ( class "form-group has-danger", none )

                Nothing ->
                    ( class "form-group", none )
    in
        Html.div (formClass :: (ite isInline [ class "mb-0" ] []))
            [ Html.label labelOptions [ text label ]
            , inputHtmlFun inputId
            , feedback
            ]


makeInputId : String -> String -> String
makeInputId formId label =
    formId ++ "-" ++ (labelToId label)


labelToId : String -> String
labelToId label =
    label
        |> String.toLower
        |> Regex.replace Regex.All (Regex.regex "\\W") convertNonWords


convertNonWords : Regex.Match -> String
convertNonWords { match } =
    case match of
        " " ->
            "-"

        _ ->
            ""


textInputWithoutValidation : String -> String -> Bool -> Repo.EntityId -> (String -> x) -> String -> Html (Msg x)
textInputWithoutValidation formId label isInline dirtyId dataUpdate currntValue =
    textInputImpl formId label isInline Dict.empty [] (OnEditValid dirtyId << dataUpdate) currntValue


textInputWithValidation :
    String
    -> String
    -> Bool
    -> Repo.Audit
    -> Repo.EntityId
    -> List Repo.AuditId
    -> (String -> Maybe String)
    -> (String -> x)
    -> String
    -> Html (Msg x)
textInputWithValidation formId label isInline audit dirtyId auditIdPath validate dataUpdate currntValue =
    let
        onInput input =
            OnEdit dirtyId [ ( auditIdPath, validate input ) ] (dataUpdate input)
    in
        textInputImpl formId label isInline audit (auditIdPath) onInput currntValue


textInputRequired : String -> String -> Bool -> Repo.Audit -> Repo.EntityId -> List Repo.AuditId -> (String -> x) -> String -> Html (Msg x)
textInputRequired formId label isInline audit dirtyId auditIdPath dataUpdate currntValue =
    textInputWithValidation formId label isInline audit dirtyId auditIdPath Repo.required dataUpdate currntValue


textInputImpl : String -> String -> Bool -> Repo.Audit -> List Repo.AuditId -> (String -> msg) -> String -> Html msg
textInputImpl =
    inputImpl "text"


inputImpl : String -> String -> String -> Bool -> Repo.Audit -> List Repo.AuditId -> (String -> msg) -> String -> Html msg
inputImpl type_ formId label isInline audit auditIdPath onInput currntValue =
    inputGroup formId label isInline audit auditIdPath (\inputId -> rawInput [] type_ formId inputId label onInput currntValue)


rawInput : List (Html.Attribute msg) -> String -> String -> String -> String -> (String -> msg) -> String -> Html msg
rawInput attrs type_ formId inputId label onInput currntValue =
    Html.input
        ([ class "form-control form-control-sm"
         , Attr.type_ type_
         , Attr.id inputId
         , Attr.form formId
         , Attr.placeholder ("(" ++ label ++ ")")
         , Attr.value currntValue
         , Events.onInput onInput
         , Events.onBlur (onInput currntValue)
         ]
            ++ attrs
        )
        []


{-| Generate Editor-styled textarea input. Only available in block (non-inline) style.
Currently, using `label` as key to audit entry, since this function is only used for BodyTemplates.
-}
editorInput : String -> String -> Repo.Audit -> (String -> Msg x) -> String -> Html (Msg x)
editorInput formId label audit onInput currentValue =
    let
        rowNum =
            currentValue |> String.lines |> List.length |> (+) 2

        gutter =
            rowNum |> List.range 1 |> List.map (\i -> Html.div [ Styles.gutterItem i ] [ text (toString i) ])
    in
        (\inputId ->
            Html.div
                [ class "d-flex", Styles.editor ]
                [ Html.div [ Styles.gutter ] gutter
                , Html.textarea
                    [ class "form-control"
                    , Attr.id inputId
                    , Attr.form "action"
                    , Attr.rows rowNum
                    , Attr.value currentValue
                    , Events.onInput onInput
                    , Events.onBlur (onInput currentValue)
                    , Styles.textarea
                    ]
                    []
                ]
        )
            |> inputGroup formId label False audit [ label ]


{-| ( value, optionLabel, isSelected )
-}
type alias SelectItem =
    ( String, String, Bool )


selectItems : x -> List x -> List SelectItem
selectItems currentValue valueList =
    List.map (\x -> ( Utils.toLowerString x, toString x, currentValue == x )) valueList


{-| Generate Bootstrap select without validation.
Always use `form-control-sm` (small) style. May be unselected.
-}
select : String -> String -> Bool -> Repo.EntityId -> (String -> x) -> List SelectItem -> Html (Msg x)
select =
    selectWithAttrs (always []) Dict.empty []


{-| Same as `select` but with `isRequired` option.
If `True`, it binds onBlur callback to check whether any valid value is selected.
`auditId` can be empty string if targeted field is not in list.
-}
selectRequireable :
    Bool
    -> Repo.Audit
    -> String
    -> String
    -> Bool
    -> Repo.EntityId
    -> List Repo.AuditId
    -> (String -> x)
    -> List SelectItem
    -> Html (Msg x)
selectRequireable isRequired audit formId label isInline dirtyId auditIdPath dataUpdate selectItems =
    let
        required maybeSelectedValue =
            [ Events.onBlur
                (OnValidate dirtyId
                    ( auditIdPath
                    , maybeSelectedValue
                        |> isNothing
                        |> Utils.boolToMaybe "This field is required"
                    )
                )
            ]
    in
        selectWithAttrs (ite isRequired required (always [])) audit (auditIdPath) formId label isInline dirtyId dataUpdate selectItems


selectWithAttrs :
    (Maybe String -> List (Html.Attribute (Msg x)))
    -> Repo.Audit
    -> List Repo.AuditId
    -> String
    -> String
    -> Bool
    -> Repo.EntityId
    -> (String -> x)
    -> List SelectItem
    -> Html (Msg x)
selectWithAttrs attrsFun audit auditIdPath formId label isInline dirtyId dataUpdate selectItems =
    let
        maybeSelectedValue =
            selectItems |> List.Extra.find (\( _, _, selected ) -> selected) |> Maybe.map (\( value, _, _ ) -> value)

        header =
            Html.option
                [ Attr.value ""
                , Attr.selected (isNothing maybeSelectedValue)
                , Attr.disabled True -- Not selectable
                , Styles.hidden -- Not included in dropdown
                ]
                [ text ("-- " ++ label ++ " --") ]

        option ( value, optionLabel, isSelected ) =
            Html.option
                [ Attr.value value
                , Attr.selected isSelected
                ]
                [ text optionLabel ]
    in
        (\inputId ->
            selectItems
                |> List.map option
                |> (::) header
                |> Html.select
                    ([ class "form-control form-control-sm"
                     , Attr.id inputId
                     , Attr.form formId
                     , Events.onInput (OnEdit dirtyId [ ( auditIdPath, Nothing ) ] << dataUpdate)
                     ]
                        ++ attrsFun maybeSelectedValue
                    )
        )
            |> inputGroup formId label isInline audit auditIdPath


submitButton : String -> Bool -> String -> Html msg
submitButton formId enabled label =
    ViewParts.stdBtn
        Button.primary
        [ Button.attrs [ Attr.form formId, Attr.type_ "submit", class "float-right" ] ]
        (not enabled)
        label


checkbox : String -> String -> Bool -> Repo.EntityId -> (Bool -> x) -> Bool -> Html (Msg x)
checkbox formId inputLabel isDisabled dirtyId dataUpdate isChecked =
    Html.div [ class ("form-check small" ++ (ite isDisabled " disabled" "")) ]
        [ Html.label [ class "form-check-label", Attr.disabled isDisabled ]
            [ Html.input
                [ Attr.type_ "checkbox"
                , Attr.form formId
                , Attr.id (formId ++ (labelToId inputLabel))
                , class "form-check-input"
                , Attr.checked isChecked
                , Attr.disabled isDisabled
                , Events.onCheck (\checked -> OnEditValid dirtyId (dataUpdate checked))
                ]
                []
            , text (" " ++ inputLabel)
            ]
        ]
