package pax

import sdl  "vendor:sdl2"
import sdli "vendor:sdl2/image"

import "core:fmt"

Tile_Grid :: struct
{
    using grid: Grid,
}

tile_grid_sprite :: proc(self: ^Tile_Grid, cell: [2]int) -> (int, [2]int)
{
    value := grid_find(self, cell)

    if value != nil && value^ > 0 {
        return value^, grid_to_point(self, cell)
    }

    return 0, {}
}
