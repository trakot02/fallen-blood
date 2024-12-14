package pax

import "core:log"
import "core:strings"
import "core:mem"

import sdl "vendor:sdl2"

Window :: struct
{
    raw: ^sdl.Window,

    close: Signal(Empty_Event),
}

window_init :: proc(self: ^Window, title: string, size: [2]int, allocator := context.allocator)
{
    temp        := context.temp_allocator
    cstr, error := strings.clone_to_cstring(title, temp)

    if error != nil {
        log.errorf("Unable to create temporary string\n")

        return
    }

    flags := sdl.WindowFlags {.HIDDEN}

    self.raw = sdl.CreateWindow(cstr,
        sdl.WINDOWPOS_CENTERED,
        sdl.WINDOWPOS_CENTERED,
        i32(size.x), i32(size.y), flags)

    mem.delete(cstr, temp)

    if self.raw == nil {
        log.errorf("SDL: %v\n",
            sdl.GetErrorString())

        return
    }
}

window_destroy :: proc(self: ^Window)
{
    sdl.DestroyWindow(self.raw)
}

window_show :: proc(self: ^Window)
{
    sdl.ShowWindow(self.raw)
}

window_hide :: proc(self: ^Window)
{
    sdl.HideWindow(self.raw)
}

window_resize :: proc(self: ^Window, size: [2]int)
{
    sdl.SetWindowSize(self.raw, i32(size.x), i32(size.y))
}

window_emit :: proc(self: ^Window, event: sdl.Event)
{
    #partial switch event.type {
        case .QUIT: signal_emit(&self.close)
    }
}
