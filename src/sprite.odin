package main

import sdl  "vendor:sdl2"
import sdli "vendor:sdl2/image"

import "pax"

Sprite :: struct
{
    texture: pax.Texture,
    frame:   [4]i32,
}

sprite_draw :: proc(self: ^Sprite, render: ^sdl.Renderer, point: [4]f32)
{
    src := sdl.Rect {
        self.frame.x, self.frame.y,
        self.frame.z, self.frame.w,
    }

    dst := sdl.Rect {
        i32(point.x), i32(point.y),
        i32(point.z), i32(point.w),
    }

    assert(sdl.RenderCopy(render, self.texture.value, &src, &dst) == 0,
        sdl.GetErrorString())
}
