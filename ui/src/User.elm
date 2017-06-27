module User exposing (User, Data, Readonly, decoder)

import Json.Decode as Decode


type alias Data =
    { displayName : String }


type alias Readonly =
    { pollCapacity : Int }


type alias User =
    { email : String
    , data : Data
    , readonly : Readonly
    }


decoder : Decode.Decoder User
decoder =
    Decode.map3 User
        (Decode.field "email" Decode.string)
        (Decode.field "data"
            (Decode.map Data
                (Decode.field "display_name" Decode.string)
            )
        )
        (Decode.field "readonly"
            (Decode.map Readonly
                (Decode.field "poll_capacity" Decode.int)
            )
        )
