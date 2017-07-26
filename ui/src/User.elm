module User exposing (User, Data, Readonly, decoder)

import Json.Decode as JD
import Json.Decode.Extra exposing ((|:))


type alias Data =
    { displayName : String }


type alias Readonly =
    { pollCapacity : Int }


type alias User =
    { email : String
    , data : Data
    , readonly : Readonly
    }


decoder : JD.Decoder User
decoder =
    JD.succeed User
        |: JD.field "email" JD.string
        |: JD.field "data"
            (JD.succeed Data
                |: JD.field "display_name" JD.string
            )
        |: JD.field "readonly"
            (JD.succeed Readonly
                |: JD.field "poll_capacity" JD.int
            )
