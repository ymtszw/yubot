module Poller.Assets exposing (url)

import Dict exposing (Dict)
import Utils


url : Bool -> Dict String Utils.Url -> String -> Utils.Url
url isDev assetInventory assetPath =
    let
        localPath =
            "/static/assets/" ++ assetPath

        cdnUrl =
            Utils.dictGetWithDefault assetPath "" assetInventory
    in
        Utils.ite isDev localPath cdnUrl
