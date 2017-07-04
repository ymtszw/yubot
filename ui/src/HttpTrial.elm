module HttpTrial exposing (Response, responseDecoder)

import Json.Decode as Decode


type alias Response =
    { status : Int
    , headers : List ( String, String )
    , body : String
    , elapsedMs : Float
    }


responseDecoder : Decode.Decoder Response
responseDecoder =
    Decode.map4 Response
        (Decode.field "status" Decode.int)
        (Decode.field "headers" (Decode.keyValuePairs Decode.string))
        (Decode.field "body" Decode.string)
        (Decode.field "elapsed_ms" Decode.float)
