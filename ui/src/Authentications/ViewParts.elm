module Authentications.ViewParts exposing (authCheck, authSelect)

import Html exposing (Html, text)
import Html.Attributes as Attr exposing (class)
import Html.Events
import Utils
import Repo
import Repo.Messages exposing (Msg(OnEditValid))
import Repo.ViewParts
import Authentications exposing (Authentication)
import ViewParts exposing (none)


type alias Authy x =
    { x | authId : Maybe Repo.EntityId }


authCheck : List (Repo.Entity Authentication) -> Repo.EntityId -> Authy x -> Maybe Repo.EntityId -> Html (Msg (Authy x))
authCheck authList dirtyId dataToUpdate maybeAuthId =
    let
        headAuthId =
            authList |> List.head |> Maybe.map .id |> Maybe.withDefault ""
    in
        Html.div [ class "form-check small" ]
            [ Html.label [ class "form-check-label", Attr.disabled (List.isEmpty authList) ]
                [ Html.input
                    [ Attr.type_ "checkbox"
                    , class "form-check-input"
                    , Attr.checked (Utils.isJust maybeAuthId)
                    , Attr.disabled (List.isEmpty authList)
                    , Html.Events.onCheck (\checked -> OnEditValid dirtyId { dataToUpdate | authId = Utils.ite checked (Just headAuthId) Nothing })
                    ]
                    []
                , text " Require authentication?"
                ]
            ]


authSelect : String -> String -> List (Repo.Entity Authentication) -> Repo.EntityId -> Authy x -> Maybe Repo.EntityId -> Html (Msg (Authy x))
authSelect formId label authList dirtyId dataToUpdate maybeAuthId =
    let
        select =
            authList
                |> List.map (\{ id, data } -> ( id, (data.name ++ " (" ++ id ++ ")"), maybeAuthId == Just id ))
                |> Repo.ViewParts.select formId label False dirtyId (\x -> { dataToUpdate | authId = Just x })
    in
        Html.div []
            [ authCheck authList dirtyId dataToUpdate maybeAuthId
            , Utils.ite (Utils.isJust maybeAuthId) select none
            ]
