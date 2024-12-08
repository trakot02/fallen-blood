package pax

import sdl  "vendor:sdl2"
import sdli "vendor:sdl2/image"

import "base:intrinsics"

Actor_Grid :: struct
{
    using grid: Grid,
}

actor_grid_sprite :: proc(self: ^Actor_Grid, cell: [2]int, group: ^Group($T)) -> (int, [2]int)
    where intrinsics.type_is_subtype_of(T, Visible)
{
    value := grid_find(self, cell)

    if value != nil && value^ > 0 {
        actor := group_find(group, value^ - 1)

        if actor != nil {
            return actor.visible.sprite, actor.visible.point
        }
    }

    return 0, {}
}
