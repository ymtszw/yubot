module StringTemplate exposing (StringTemplate, Body, validate)

import Result exposing (Result(Ok, Err))
import Regex
import List.Extra
import Utils


type alias StringTemplate =
    { body : Body
    , variables : List String
    }


type alias Body =
    String


validate : String -> Result Utils.ErrorMessage (List String)
validate body =
    let
        placeholderPattern =
            Regex.regex "#\\{(.*?)\\}"

        variablePattern =
            Regex.regex "^[a-z0-9_]+$"

        validateMatch { submatches } =
            case submatches of
                [ Just "" ] ->
                    Err ( "StringTemplate", "Variable name must not be empty" )

                [ Just varName ] ->
                    if Regex.contains variablePattern varName then
                        Ok varName
                    else
                        Err ( "StringTemplate", "Variable name may only contain a-z, 0-9 and underscore `_`" )

                _ ->
                    -- Should not happen?
                    Err ( "StringTemplate", "Variable name must not be empty" )

        folder validateResult acc =
            case acc of
                Err _ ->
                    acc

                Ok vars ->
                    case validateResult of
                        Ok var ->
                            Ok (var :: vars)

                        Err err ->
                            Err err

        dedup validateResult =
            case validateResult of
                Ok vars ->
                    Ok (List.Extra.unique vars)

                Err _ ->
                    validateResult
    in
        body
            |> Regex.find Regex.All placeholderPattern
            |> List.map validateMatch
            |> List.foldr folder (Ok [])
            |> dedup
