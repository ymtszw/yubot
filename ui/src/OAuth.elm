module OAuth exposing (Provider(..), stringToProvider)


type Provider
    = Google
    | GitHub


stringToProvider : String -> Maybe Provider
stringToProvider string =
    case string of
        "google" ->
            Just Google

        "github" ->
            Just GitHub

        _ ->
            Nothing
