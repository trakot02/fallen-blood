package pax

import sdl "vendor:sdl2"

Keyboard :: struct
{
    press:   Signal(sdl.KeyboardEvent),
    release: Signal(sdl.KeyboardEvent),
}

keyboard_init :: proc(self: ^Keyboard, allocator := context.allocator)
{
    signal_init(&self.press)
    signal_init(&self.release)
}

keyboard_destroy :: proc(self: ^Keyboard)
{
    signal_destroy(&self.release)
    signal_destroy(&self.press)
}

keyboard_emit :: proc(self: ^Keyboard, event: sdl.Event)
{
    #partial switch event.type {
        case .KEYUP:   signal_emit(&self.release, event.key)
        case .KEYDOWN: signal_emit(&self.press,   event.key)
    }
}
