module Authentications.ViewParts exposing (authCheck, authSelect)

import Html exposing (Html, text)
import Utils
import Repo
import Repo.Messages exposing (Msg(OnEditValid))
import Repo.ViewParts
import Authentications exposing (Authentication)
import ViewParts exposing (none)


type alias Authy x =
    { x | authId : Maybe Repo.EntityId }


authCheck : String -> List (Repo.Entity Authentication) -> Repo.EntityId -> Authy x -> Maybe Repo.EntityId -> Html (Msg (Authy x))
authCheck formId authList dirtyId dataToUpdate maybeAuthId =
    let
        ( isDisabled, onChecked ) =
            case authList of
                [] ->
                    ( True, Nothing )

                a :: _ ->
                    ( False, Just a.id )

        dataUpdate checked =
            { dataToUpdate | authId = Utils.ite checked onChecked Nothing }
    in
        Repo.ViewParts.checkbox formId "Require authentication?" isDisabled dirtyId dataUpdate (Utils.isJust maybeAuthId)


authSelect : String -> String -> List (Repo.Entity Authentication) -> Repo.EntityId -> Authy x -> Maybe Repo.EntityId -> Html (Msg (Authy x))
authSelect formId label authList dirtyId dataToUpdate maybeAuthId =
    let
        select =
            authList
                |> List.map (\{ id, data } -> ( id, (data.name ++ " (" ++ id ++ ")"), maybeAuthId == Just id ))
                |> Repo.ViewParts.select formId label False dirtyId (\x -> { dataToUpdate | authId = Just x })
    in
        Html.div []
            [ authCheck formId authList dirtyId dataToUpdate maybeAuthId
            , Utils.ite (Utils.isJust maybeAuthId) select none
            ]
