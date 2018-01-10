module Assets exposing (Assets, url)

import Dict
import Utils


type alias Assets =
    Dict.Dict String String


url : Assets -> String -> Utils.Url
url assets assetPath =
    case Dict.get assetPath assets of
        Just url ->
            url

        Nothing ->
            "/static/" ++ assetPath
