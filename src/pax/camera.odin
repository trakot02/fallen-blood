package pax

import sdl  "vendor:sdl2"
import sdli "vendor:sdl2/image"

Camera :: struct {
    size:   [2]int,
    follow: [2]int,
    offset: [2]int,
    scale:  f32,
}

camera_draw :: proc(self: ^Camera, texture: Texture, render: ^sdl.Renderer, part: [4]int, rect: [4]int)
{
    src := sdl.Rect {
        i32(part.x), i32(part.y),
        i32(part.z), i32(part.w),
    }

    rect_x := rect.x + self.offset.x - self.follow.x
    rect_y := rect.y + self.offset.y - self.follow.y

    dst := sdl.Rect {
        i32(f32(rect_x) * self.scale),
        i32(f32(rect_y) * self.scale),
        i32(f32(rect.z) * self.scale),
        i32(f32(rect.w) * self.scale),
    }

    assert(sdl.RenderCopy(render, texture.value, &src, &dst) == 0,
        sdl.GetErrorString())
}

camera_draw_full :: proc(self: ^Camera, texture: Texture, render: ^sdl.Renderer, rect: [4]int)
{
    rect_x := rect.x + self.offset.x - self.follow.x
    rect_y := rect.y + self.offset.y - self.follow.y

    dst := sdl.Rect {
        i32(f32(rect_x) * self.scale),
        i32(f32(rect_y) * self.scale),
        i32(f32(rect.z) * self.scale),
        i32(f32(rect.w) * self.scale),
    }

    assert(sdl.RenderCopy(render, texture.value, nil, &dst) == 0,
        sdl.GetErrorString())
}
