package pax

import "core:log"
import "core:strings"
import "core:mem"

import sdl "vendor:sdl2"

Window :: struct
{
    data: rawptr,

    close: Signal(Empty_Event),
}

window_init :: proc(self: ^Window, allocator := context.allocator) -> bool
{
    self.data = auto_cast sdl.CreateWindow("",
        sdl.WINDOWPOS_CENTERED,
        sdl.WINDOWPOS_CENTERED,
        320, 180, {.HIDDEN})

    if self.data == nil {
        log.errorf("SDL: %v\n", sdl.GetErrorString())

        return false
    }

    return true
}

window_destroy :: proc(self: ^Window)
{
    sdl.DestroyWindow(auto_cast self.data)

    self.data = nil
}

window_show :: proc(self: ^Window)
{
    sdl.ShowWindow(auto_cast self.data)
}

window_hide :: proc(self: ^Window)
{
    sdl.HideWindow(auto_cast self.data)
}

window_set_title :: proc(self: ^Window, name: string)
{
    alloc := context.temp_allocator

    clone, error := strings.clone_to_cstring(name, alloc)

    if error != nil {
        log.errorf("Unable to clone %q to c-string\n", name)

        return
    }

    sdl.SetWindowTitle(auto_cast self.data, clone)
    sdl.SetWindowBordered(auto_cast self.data, true)

    mem.free_all(alloc)
}

window_set_size :: proc(self: ^Window, size: [2]int)
{
    sdl.SetWindowSize(auto_cast self.data, i32(size.x), i32(size.y))
}

window_set_point :: proc(self: ^Window, point: [2]int)
{
    sdl.SetWindowPosition(auto_cast self.data, i32(point.x), i32(point.y))
}

window_emit :: proc(self: ^Window, event: sdl.Event)
{
    #partial switch event.type {
        case .QUIT: signal_emit(&self.close)
    }
}
