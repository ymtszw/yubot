module Stack exposing (Stack, push, pop, isEmpty, nonEmpty)


type alias Stack x =
    List x


push : x -> Stack x -> Stack x
push element listStack =
    element :: listStack


pop : Stack x -> ( Maybe x, Stack x )
pop listStack =
    case listStack of
        [] ->
            ( Nothing, [] )

        hd :: tl ->
            ( Just hd, tl )


isEmpty : Stack x -> Bool
isEmpty =
    List.isEmpty


nonEmpty : Stack x -> Bool
nonEmpty =
    not << isEmpty
