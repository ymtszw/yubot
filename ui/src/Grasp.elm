module Grasp
    exposing
        ( Instruction
        , Responder
        , Pattern
        , FirstOrder
        , TestResult
        , regexExtractor
        , responder
        , firstOrder
        , isValidInstruction
        , decodeInstruction
        , encodeInstruction
        , tryTask
        )

import Http
import Json.Decode as JD
import Json.Encode as JE
import Task exposing (Task)
import HttpBuilder
import Utils
import Repo


type alias Instruction r =
    { auditId : Repo.AuditId -- For action variable material, this field should not be used (use var name instead)
    , extractor : Extractor
    , responder : r
    }


type alias Extractor =
    { engine : Engine
    , pattern : Pattern
    }


type Engine
    = Regex


regexExtractor : Pattern -> Extractor
regexExtractor =
    Extractor Regex


{-| Pattern that can be compiled to Elixir's `Regex.t`.

Later it may also accept JSONPath, XPath and/or CSS selectors.
Obviously cannot be validated on client.

-}
type alias Pattern =
    String


type alias Responder ho op =
    { mode : String
    , highOrder : ho
    , firstOrder : FirstOrder op
    }


responder : String -> ho -> FirstOrder op -> Responder ho op
responder mode ho fo =
    { mode = mode, highOrder = ho, firstOrder = fo }


type alias FirstOrder op =
    { operator : op
    , arguments : List String
    }


firstOrder : op -> List String -> FirstOrder op
firstOrder op args =
    { operator = op, arguments = args }


isValidInstruction : (Responder ho op -> Bool) -> Instruction (Responder ho op) -> Bool
isValidInstruction isValidResponder { extractor, responder } =
    (extractor.pattern /= "")
        && (List.member responder.mode [ "boolean", "string" ])
        && isValidResponder responder



-- JSON


decodeInstruction : (String -> ho) -> (String -> op) -> String -> Int -> JD.Decoder (Instruction (Responder ho op))
decodeInstruction stringToHo stringToOp prefix index =
    JD.map2 (Instruction (prefix ++ toString index))
        (JD.field "extractor" decodeExtractor)
        (JD.field "responder" (decodeResponder stringToHo stringToOp))


decodeExtractor : JD.Decoder Extractor
decodeExtractor =
    JD.map (Extractor Regex)
        (JD.field "pattern" JD.string)


decodeResponder : (String -> ho) -> (String -> op) -> JD.Decoder (Responder ho op)
decodeResponder stringToHo stringToOp =
    JD.map3 responder
        (JD.field "mode" JD.string)
        (JD.field "high_order" (JD.map stringToHo JD.string))
        (JD.field "first_order" (decodeFirstOrder stringToOp))


decodeFirstOrder : (String -> op) -> JD.Decoder (FirstOrder op)
decodeFirstOrder stringToOp =
    JD.map2 firstOrder
        (JD.field "operator" (JD.map stringToOp JD.string))
        (JD.field "arguments" (JD.list JD.string))


encodeInstruction : Instruction (Responder ho op) -> JE.Value
encodeInstruction { extractor, responder } =
    JE.object
        [ ( "extractor", encodeExtractor extractor )
        , ( "responder", encodeResponder responder )
        ]


encodeExtractor : Extractor -> JE.Value
encodeExtractor { engine, pattern } =
    JE.object
        [ ( "engine", JE.string <| Utils.toLowerString <| engine )
        , ( "pattern", JE.string pattern ) -- Be extra careful about escaping
        ]


encodeResponder : Responder ho op -> JE.Value
encodeResponder { mode, highOrder, firstOrder } =
    JE.object
        [ ( "mode", JE.string mode )
        , ( "high_order", JE.string <| toString <| highOrder )
        , ( "first_order", encodeFirstOrder firstOrder )
        ]


encodeFirstOrder : FirstOrder op -> JE.Value
encodeFirstOrder { operator, arguments } =
    JE.object
        [ ( "operator", JE.string <| toString operator )
        , ( "arguments", JE.list <| List.map JE.string <| arguments )
        ]



-- Try API


type alias TestResult =
    { extractResultant : List (List String)
    , value : String
    }


{-| Flipped for chaining
-}
tryTask : Instruction (Responder ho op) -> String -> Task Http.Error TestResult
tryTask instruction source =
    HttpBuilder.post "/api/grasp/try"
        |> HttpBuilder.withJsonBody (tryRequestEncoder source instruction)
        |> HttpBuilder.withExpect (Http.expectJson tryResultDecoder)
        |> HttpBuilder.toTask


tryRequestEncoder : String -> Instruction (Responder ho op) -> JE.Value
tryRequestEncoder source instruction =
    JE.object
        [ ( "source", JE.string source )
        , ( "instruction", encodeInstruction instruction )
        ]


tryResultDecoder : JD.Decoder TestResult
tryResultDecoder =
    JD.map2 TestResult
        (JD.field "extract_resultant" (JD.list (JD.list JD.string)))
        (JD.field "value" JD.string)
