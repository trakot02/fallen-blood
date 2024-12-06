package pax

import sdl  "vendor:sdl2"
import sdli "vendor:sdl2/image"

import "core:fmt"

Tile_Grid :: struct
{
    using grid: Grid,

    texture: Texture,
}

tile_grid_draw :: proc(self: ^Tile_Grid, camera: ^Camera, render: ^sdl.Renderer)
{
    follow := grid_from_point(self, camera.follow)
    size   := grid_from_point(self, camera.size)
    start  := follow - size - 1
    stop   := follow + size + 2

    sprite := Sprite {texture = self.texture}

    sprite.frame.zw = self.tile

    for row in start.y ..< stop.y {
        if row < 0 || row >= self.size.y { continue }

        for col in start.x ..< stop.x {
            if col < 0 || col >= self.size.x { continue }

            index := grid_index(self, {col, row})
            value := self.value[index]

            if value >= 0 {
                sprite.frame.xy = {
                    (value % (self.texture.size.x / self.tile.x)) * self.tile.x,
                    (value / (self.texture.size.x / self.tile.x)) * self.tile.y,
                }

                sprite.pixel = grid_to_point(self, grid_pair(self, index))

                sprite_draw(&sprite, camera, render)
            }
        }
    }
}
