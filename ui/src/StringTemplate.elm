module StringTemplate exposing (StringTemplate, Body, isValid, validate, parse, render, renderAll)

import Dict exposing (Dict)
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


isValid : StringTemplate -> Bool
isValid { body, variables } =
    validate body == Ok variables


validate : String -> Result String (List String)
validate body =
    let
        placeholderPattern =
            Regex.regex "#\\{(.*?)\\}"

        variablePattern =
            Regex.regex "^[a-z0-9_]+$"

        validateMatch { submatches } =
            case submatches of
                [ Just "" ] ->
                    Err "Variable name must not be empty"

                [ Just varName ] ->
                    if Regex.contains variablePattern varName then
                        Ok varName
                    else
                        Err "Variable name may only contain a-z, 0-9 and underscore `_`"

                _ ->
                    -- Should not happen?
                    Err "Variable name must not be empty"

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


parse : Body -> StringTemplate
parse body =
    body |> validate |> Result.toMaybe |> Maybe.withDefault [] |> StringTemplate body


render : String -> String -> Body -> Body
render variable value body =
    let
        patternToFill =
            "#{" ++ variable ++ "}"
    in
        Regex.replace Regex.All (Regex.regex patternToFill) (\_ -> value) body


renderAll : Dict String String -> StringTemplate -> Body
renderAll values { body, variables } =
    variables
        |> List.foldl (\x -> render x (Utils.dictGetWithDefault x "" values)) body
