module HttpTrial exposing (Response, responseDecoder)

import Json.Decode as JD
import Json.Decode.Extra exposing ((|:))


type alias Response =
    { status : Int
    , headers : List ( String, String )
    , body : String
    , elapsedMs : Float
    }


responseDecoder : JD.Decoder Response
responseDecoder =
    JD.succeed Response
        |: JD.field "status" JD.int
        |: JD.field "headers" (JD.keyValuePairs JD.string)
        |: JD.field "body" JD.string
        |: JD.field "elapsed_ms" JD.float
