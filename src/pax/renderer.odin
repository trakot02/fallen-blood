package pax

import "core:log"

import sdl  "vendor:sdl2"
import sdli "vendor:sdl2/image"

Renderer :: struct
{
    data: rawptr,
}

renderer_init :: proc(self: ^Renderer, window: ^Window) -> bool
{
    self.data = auto_cast sdl.CreateRenderer(auto_cast window.data,
        -1, {.ACCELERATED})

    if self.data == nil {
        log.errorf("SDL: %v\n", sdl.GetErrorString())

        return false
    }

    return true
}

renderer_destroy :: proc(self: ^Renderer)
{
    sdl.DestroyRenderer(auto_cast self.data)

    self.data = nil
}

renderer_clear :: proc(self: ^Renderer, color: [4]u8 = {})
{
    sdl.SetRenderDrawColor(auto_cast self.data,
        color.x, color.y, color.z, color.w)

    clear := sdl.RenderClear(auto_cast self.data)

    assert(clear == 0, sdl.GetErrorString())
}

renderer_apply :: proc(self: ^Renderer)
{
    sdl.RenderPresent(auto_cast self.data)
}

renderer_draw_image :: proc(self: ^Renderer, image: Image, from: [4]int, rect: [4]int)
{
    src := sdl.Rect {
        i32(from.x), i32(from.y),
        i32(from.z), i32(from.w),
    }

    dst := sdl.Rect {
        i32(rect.x), i32(rect.y),
        i32(rect.z), i32(rect.w),
    }

    copy := sdl.RenderCopy(auto_cast self.data,
        auto_cast image.data, &src, &dst)

    assert(copy == 0, sdl.GetErrorString())
}
