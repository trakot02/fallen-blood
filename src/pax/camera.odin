package pax

import sdl  "vendor:sdl2"
import sdli "vendor:sdl2/image"

Camera :: struct {
    render: ^sdl.Renderer,
    target: [2]f32,
    offset: [2]f32,
    scale:  f32,
}

camera_draw :: proc(self: ^Camera, texture: Texture, part: [4]i32, rect: [4]f32)
{
    src := sdl.Rect {part.x, part.y, part.z, part.w}

    rect_x := rect.x + self.offset.x - self.target.x
    rect_y := rect.y + self.offset.y - self.target.y

    dst := sdl.Rect {
        i32(rect_x * self.scale),
        i32(rect_y * self.scale),
        i32(rect.z * self.scale),
        i32(rect.w * self.scale),
    }

    assert(sdl.RenderCopy(self.render, texture.value, &src, &dst) == 0,
        sdl.GetErrorString())
}

camera_draw_full :: proc(self: ^Camera, texture: Texture, rect: [4]f32)
{
    rect_x := rect.x + self.offset.x - self.target.x
    rect_y := rect.y + self.offset.y - self.target.y

    dst := sdl.Rect {
        i32(rect_x * self.scale),
        i32(rect_y * self.scale),
        i32(rect.z * self.scale),
        i32(rect.w * self.scale),
    }

    assert(sdl.RenderCopy(self.render, texture.value, nil, &dst) == 0,
        sdl.GetErrorString())
}
