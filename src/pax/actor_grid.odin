package pax

import sdl  "vendor:sdl2"
import sdli "vendor:sdl2/image"

import "base:intrinsics"

Actor_Grid :: struct
{
    using grid: Grid,
}

actor_grid_draw :: proc(self: ^Actor_Grid, camera: ^Camera, render: ^sdl.Renderer, group: ^Group($T))
    where intrinsics.type_is_subtype_of(T, Sprite)
{
    follow := grid_from_point(self, camera.follow)
    size   := grid_from_point(self, camera.size)
    start  := follow - size - 1
    stop   := follow + size + 2

    for row in start.y ..< stop.y {
        if row < 0 || row >= self.size.y { continue }

        for col in start.x ..< stop.x {
            if col < 0 || col >= self.size.x { continue }

            index := grid_index(self, {col, row})
            value := group_find(group, self.value[index])

            if value != nil {
                sprite_draw(value, camera, render)
            }
        }
    }
}
