module ListSet exposing (ListSet, insert, remove, toggle)

import Utils


{-| Set represented by List, so that it can hold non-comparable values.
It is inefficient compared to Set since linked-list requires linear computation order for many operations.
-}
type alias ListSet a =
    List a


insert : a -> ListSet a -> ListSet a
insert item listSet =
    Utils.ite (List.member item listSet) listSet (item :: listSet)


remove : a -> ListSet a -> ListSet a
remove item listSet =
    List.filter ((/=) item) listSet


toggle : a -> ListSet a -> ListSet a
toggle item listSet =
    listSet
        |> Utils.ite (List.member item listSet) (remove item) ((::) item)
