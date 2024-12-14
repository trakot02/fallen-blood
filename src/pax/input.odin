package pax

import sdl "vendor:sdl2"

Keyboard :: struct
{
    key_press:   Signal(sdl.KeyboardEvent),
    key_release: Signal(sdl.KeyboardEvent),
}

keyboard_init :: proc(self: ^Keyboard, allocator := context.allocator)
{
    signal_init(&self.key_press)
    signal_init(&self.key_release)
}

keyboard_destroy :: proc(self: ^Keyboard)
{
    signal_destroy(&self.key_release)
    signal_destroy(&self.key_press)
}

keyboard_emit :: proc(self: ^Keyboard, event: sdl.Event)
{
    #partial switch event.type {
        case .KEYUP:   signal_emit(&self.key_release, event.key)
        case .KEYDOWN: signal_emit(&self.key_press,   event.key)
    }
}

Mouse :: struct
{
    btn_press:   Signal(sdl.MouseButtonEvent),
    btn_release: Signal(sdl.MouseButtonEvent),
    move:        Signal(sdl.MouseMotionEvent),
    wheel:       Signal(sdl.MouseWheelEvent),
}

mouse_init :: proc(self: ^Mouse, allocator := context.allocator)
{
    signal_init(&self.btn_press)
    signal_init(&self.btn_release)
    signal_init(&self.move)
    signal_init(&self.wheel)
}

mouse_destroy :: proc(self: ^Mouse)
{
    signal_destroy(&self.wheel)
    signal_destroy(&self.move)
    signal_destroy(&self.btn_release)
    signal_destroy(&self.btn_press)
}

mouse_emit :: proc(self: ^Mouse, event: sdl.Event)
{
    #partial switch event.type {
        case .MOUSEBUTTONUP:   signal_emit(&self.btn_release, event.button)
        case .MOUSEBUTTONDOWN: signal_emit(&self.btn_press,   event.button)
        case .MOUSEMOTION:     signal_emit(&self.move,        event.motion)
        case .MOUSEWHEEL:      signal_emit(&self.wheel,       event.wheel)
    }
}
