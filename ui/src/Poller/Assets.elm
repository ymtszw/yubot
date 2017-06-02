module Poller.Assets exposing (url)

import Dict
import Utils
import Poller.Model exposing (Model)


url : Model -> String -> Utils.Url
url { isDev, assetInventory } assetPath =
    let
        localPath =
            "/static/assets/" ++ assetPath

        cdnUrl =
            assetInventory
                |> Dict.get assetPath
                |> Maybe.withDefault ""
    in
        Utils.ite isDev localPath cdnUrl
