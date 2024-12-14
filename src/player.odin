package main

import sdl "vendor:sdl2"

import "pax"

Player :: struct
{
    sprite:   pax.Sprite,
    camera:   ^pax.Camera,
    motion:   Motion,
    controls: Controls,
}

player_on_key_release :: proc(event: sdl.KeyboardEvent, self: ^Player)
{
    #partial switch event.keysym.sym {
        case .D, .RIGHT: self.controls.east  = false
        case .W, .UP:    self.controls.north = false
        case .A, .LEFT:  self.controls.west  = false
        case .S, .DOWN:  self.controls.south = false
    }
}

player_on_key_press :: proc(event: sdl.KeyboardEvent, self: ^Player)
{
    #partial switch event.keysym.sym {
        case .D, .RIGHT: self.controls.east  = true
        case .W, .UP:    self.controls.north = true
        case .A, .LEFT:  self.controls.west  = true
        case .S, .DOWN:  self.controls.south = true
    }
}
