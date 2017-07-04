module Grasp
    exposing
        ( Instruction
        , Responder
        , decodeInstruction
        , encodeInstruction
        )

import Json.Decode as Decode
import Json.Encode as Encode
import Utils


type alias Instruction r =
    { extractor : Extractor
    , responder : r
    }


type alias Extractor =
    { engine : Engine
    , pattern : Pattern
    }


type Engine
    = Regex


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


decodeInstruction : (String -> ho) -> (String -> op) -> Decode.Decoder (Instruction (Responder ho op))
decodeInstruction stringToHo stringToOp =
    Decode.map2 Instruction
        (Decode.field "extractor" decodeExtractor)
        (Decode.field "responder" (decodeResponder stringToHo stringToOp))


decodeExtractor : Decode.Decoder Extractor
decodeExtractor =
    Decode.map (Extractor Regex)
        (Decode.field "pattern" Decode.string)


decodeResponder : (String -> ho) -> (String -> op) -> Decode.Decoder (Responder ho op)
decodeResponder stringToHo stringToOp =
    Decode.map3 responder
        (Decode.field "mode" Decode.string)
        (Decode.field "high_order" (Decode.map stringToHo Decode.string))
        (Decode.field "first_order" (decodeFirstOrder stringToOp))


decodeFirstOrder : (String -> op) -> Decode.Decoder (FirstOrder op)
decodeFirstOrder stringToOp =
    Decode.map2 firstOrder
        (Decode.field "operator" (Decode.map stringToOp Decode.string))
        (Decode.field "arguments" (Decode.list Decode.string))


encodeInstruction : Instruction (Responder ho op) -> Encode.Value
encodeInstruction { extractor, responder } =
    Encode.object
        [ ( "extractor", encodeExtractor extractor )
        , ( "responder", encodeResponder responder )
        ]


encodeExtractor : Extractor -> Encode.Value
encodeExtractor { engine, pattern } =
    Encode.object
        [ ( "engine", Encode.string <| Utils.toLowerString <| engine )
        , ( "pattern", Encode.string pattern ) -- Be extra careful about escaping
        ]


encodeResponder : Responder ho op -> Encode.Value
encodeResponder { mode, highOrder, firstOrder } =
    Encode.object
        [ ( "mode", Encode.string mode )
        , ( "highOrder", Encode.string <| toString <| highOrder )
        , ( "firstOrder", encodeFirstOrder firstOrder )
        ]


encodeFirstOrder : FirstOrder op -> Encode.Value
encodeFirstOrder { operator, arguments } =
    Encode.object
        [ ( "operator", Encode.string <| toString operator )
        , ( "arguments", Encode.list <| List.map Encode.string <| arguments )
        ]
