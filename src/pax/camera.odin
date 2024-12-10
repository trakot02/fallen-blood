package pax

import sdl  "vendor:sdl2"
import sdli "vendor:sdl2/image"

Camera :: struct {
    size:   [2]int,
    follow: [2]f32,
    offset: [2]f32,
    zoom:   [2]f32,
}

camera_move :: proc(self: ^Camera) -> [2]f32
{
    return {
        self.offset.x - self.follow.x,
        self.offset.y - self.follow.y,
    }
}

camera_zoom :: proc(self: ^Camera) -> [2]f32
{
    return {
        self.zoom.x,
        self.zoom.y,
    }
}

camera_corners :: proc(self: ^Camera, grid: ^Grid_Table) -> [4]int
{
    follow := point_to_cell(grid, [2]int {int(self.follow.x), int(self.follow.y)})
    size   := point_to_cell(grid, self.size)
    start  := follow - size - 1
    stop   := follow + size + 1

    return {start.x, stop.x, start.y, stop.y}
}
