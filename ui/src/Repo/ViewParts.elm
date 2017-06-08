module Repo.ViewParts exposing (errorToast)

import Html exposing (Html, text)
import Html.Attributes as Attr exposing (class)
import Html.Events as Events
import Utils
import Repo
import Repo.Messages exposing (Msg(..))
import Styles


errorToast : Repo.Repo x -> Html (Msg x)
errorToast { errors } =
    let
        dismiss index =
            SetErrors (Utils.listDeleteAt index errors)

        alert index ( kind, desc ) =
            Html.div [ class "alert alert-danger alert-dismissible", Styles.toast ]
                [ Html.button [ class "close", Events.onClick (dismiss index) ] [ Html.span [] [ text "×" ] ]
                , Html.h6 [ class "alert-heading" ] [ kind |> toString |> text ]
                , desc
                    |> List.map (\( label, string ) -> Html.li [] [ text (label ++ ": " ++ string) ])
                    |> Html.ul []
                ]
    in
        case errors of
            [] ->
                text ""

            _ ->
                errors
                    |> List.indexedMap alert
                    |> Html.div [ class "text-muted small" ]
