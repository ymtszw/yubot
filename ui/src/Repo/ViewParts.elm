module Repo.ViewParts
    exposing
        ( SelectItem
        , errorToast
        , navigate
        , toggleSortOnClick
        , textInputWithoutValidation
        , textInputWithValidation
        , textInputRequired
        , textInputImpl
        , editorInput
        , select
        , selectRequireable
        , selectWithAttrs
        )

import Dict
import Html exposing (Html, text)
import Html.Attributes as Attr exposing (class)
import Html.Events as Events
import List.Extra
import Utils exposing (ite)
import Repo exposing (Repo)
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


inputGroup : String -> String -> Bool -> Repo.Audit -> (String -> Html msg) -> Html msg
inputGroup formId label isInline audit inputHtmlFun =
    let
        inputId =
            formId ++ "-" ++ (String.toLower label)

        labelOptions =
            [ Attr.for inputId, class ("form-control-label" ++ (ite isInline " sr-only" "")) ]

        ( formClass, feedback ) =
            case Dict.get label audit of
                Just message ->
                    ( class "form-group has-danger", Html.div [ class "form-control-feedback small" ] [ text message ] )

                Nothing ->
                    ( class "form-group", none )
    in
        Html.div (formClass :: (ite isInline [ class "mb-0" ] []))
            [ Html.label labelOptions [ text label ]
            , inputHtmlFun inputId
            , feedback
            ]


textInputWithoutValidation : String -> String -> Bool -> Repo.EntityId -> (String -> x) -> String -> Html (Msg x)
textInputWithoutValidation formId label isInline dirtyId dataUpdate currntValue =
    textInputImpl formId label isInline Dict.empty (OnEditValid dirtyId << dataUpdate) currntValue


textInputWithValidation : String -> String -> Bool -> Repo.Audit -> Repo.EntityId -> (String -> Maybe String) -> (String -> x) -> String -> Html (Msg x)
textInputWithValidation formId label isInline audit dirtyId validate dataUpdate currntValue =
    let
        onInput input =
            OnEdit dirtyId ( label, validate input ) (dataUpdate input)
    in
        textInputImpl formId label isInline audit onInput currntValue


textInputRequired : String -> String -> Bool -> Repo.Audit -> Repo.EntityId -> (String -> x) -> String -> Html (Msg x)
textInputRequired formId label isInline audit dirtyId dataUpdate currntValue =
    textInputWithValidation formId label isInline audit dirtyId Repo.required dataUpdate currntValue


textInputImpl : String -> String -> Bool -> Repo.Audit -> (String -> msg) -> String -> Html msg
textInputImpl formId label isInline audit onInput currntValue =
    (\inputId ->
        Html.input
            [ class "form-control form-control-sm"
            , Attr.type_ "text"
            , Attr.id inputId
            , Attr.form formId
            , Attr.placeholder ("(" ++ label ++ ")")
            , Attr.value currntValue
            , Events.onInput onInput
            , Events.onBlur (onInput currntValue)
            ]
            []
    )
        |> inputGroup formId label isInline audit


{-| Generate Editor-styled textarea input. Only available in block (non-inline) style.
-}
editorInput : String -> String -> Repo.Audit -> (String -> Msg x) -> String -> Html (Msg x)
editorInput formId label audit onInput currentValue =
    let
        rowNum =
            (Utils.stringCountChar '\n' currentValue) + 2

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
            |> inputGroup formId label False audit


{-| ( value, optionLabel, isSelected )
-}
type alias SelectItem =
    ( String, String, Bool )


{-| Generate Bootstrap select. Always use `form-control-sm` (small) style. May be unselected.
-}
select : String -> String -> Bool -> Repo.EntityId -> (String -> x) -> List SelectItem -> Html (Msg x)
select =
    selectWithAttrs (always []) Dict.empty


{-| Same as `select` but with `isRequired` option.
If `True`, it binds onBlur callback to check whether any value is selected.
-}
selectRequireable : Bool -> Repo.Audit -> String -> String -> Bool -> Repo.EntityId -> (String -> x) -> List SelectItem -> Html (Msg x)
selectRequireable isRequired audit formId label isInline dirtyId dataUpdate selectItems =
    let
        required maybeSelectedValue =
            [ Events.onBlur (OnValidate dirtyId ( label, maybeSelectedValue |> Utils.isNothing |> Utils.boolToMaybe "This field is required" )) ]
    in
        selectWithAttrs (ite isRequired required (always [])) audit formId label isInline dirtyId dataUpdate selectItems


selectWithAttrs :
    (Maybe String -> List (Html.Attribute (Msg x)))
    -> Repo.Audit
    -> String
    -> String
    -> Bool
    -> Repo.EntityId
    -> (String -> x)
    -> List SelectItem
    -> Html (Msg x)
selectWithAttrs attrsFun audit formId label isInline dirtyId dataUpdate selectItems =
    let
        maybeSelectedValue =
            selectItems |> List.Extra.find (\( _, _, selected ) -> selected) |> Maybe.map (\( value, _, _ ) -> value)

        header =
            Html.option
                [ Attr.value ""
                , Attr.selected (Utils.isNothing maybeSelectedValue)
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
                     , Events.onInput (OnEdit dirtyId ( label, Nothing ) << dataUpdate)
                     ]
                        ++ attrsFun maybeSelectedValue
                    )
        )
            |> inputGroup formId label isInline audit
