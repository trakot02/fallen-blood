package pax

import sdl  "vendor:sdl2"
import sdli "vendor:sdl2/image"

Camera :: struct
{
    follow: [2]int,
    offset: [2]int,
    size:   [2]int,
    scale:  [2]f32,
}

camera_displ :: proc(self: ^Camera) -> [2]int
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

camera_grid_area :: proc(self: ^Camera, grid: ^Grid) -> [2][2]int
{
    follow := point_to_cell(grid, self.follow)
    size   := point_to_cell(grid, self.size) + 1

    return {follow - size, follow + size}
}

camera_on_key_press :: proc(event: sdl.KeyboardEvent, self: ^Camera)
{
    #partial switch event.keysym.sym {
        case .P, .PLUS,  .KP_PLUS:  self.scale += 0.01
        case .M, .MINUS, .KP_MINUS: self.scale -= 0.01
    }
}
