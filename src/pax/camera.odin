package pax

import sdl  "vendor:sdl2"
import sdli "vendor:sdl2/image"

Camera :: struct
{
    follow: [2]int,
    size:   [2]int,
    bounds: [4]int,
    offset: [2]int,
    scale:  [2]f32,
}

camera_move :: proc(self: ^Camera, diff: [2]int)
{
    self.follow += diff

    self.follow.x = clamp(self.follow.x,
        self.bounds.x, self.bounds.z - self.size.x)

    self.follow.y = clamp(self.follow.y,
        self.bounds.y, self.bounds.w - self.size.y)
}

camera_point :: proc(self: ^Camera) -> [2]int
{
    return {
        self.offset.x - self.follow.x,
        self.offset.y - self.follow.y,
    }
}

camera_scale :: proc(self: ^Camera) -> [2]f32
{
    return {self.scale.x, self.scale.y}
}

camera_grid_follow :: proc(self: ^Camera, grid: ^Grid) -> [2]int
{
    return point_to_cell(grid, self.follow)
}

camera_grid_area :: proc(self: ^Camera, grid: ^Grid) -> [4]int
{
    follow := point_to_cell(grid, self.follow)
    size   := point_to_cell(grid, self.size) + 1

    start := follow - size
    stop  := follow + size

    return {start.x, start.y, stop.x, stop.y}
}
