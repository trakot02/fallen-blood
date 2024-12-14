package pax

import "core:log"
import "core:time"

import sdl "vendor:sdl2"

Stage :: struct
{
    instance: rawptr,

    proc_start: proc(self: rawptr) -> bool,
    proc_stop:  proc(self: rawptr),
}

stage_start :: proc(self: ^Stage)-> bool
{
    return self.proc_start(self.instance)
}

stage_stop :: proc(self: ^Stage)
{
    self.proc_stop(self.instance)
}

Scene :: struct
{
    instance: rawptr,

    proc_start: proc(self: rawptr, stage: rawptr) -> bool,
    proc_stop:  proc(self: rawptr),
    proc_enter: proc(self: rawptr),
    proc_leave: proc(self: rawptr),
    proc_input: proc(self: rawptr, event: sdl.Event) -> int,
    proc_step:  proc(self: rawptr, delta: f32),
    proc_draw:  proc(self: rawptr),
}

scene_start :: proc(self: ^Scene, stage: rawptr) -> bool
{
    return self.proc_start(self.instance, stage)
}

scene_stop :: proc(self: ^Scene)
{
    self.proc_stop(self.instance)
}

scene_enter :: proc(self: ^Scene)
{
    self.proc_enter(self.instance)
}

scene_leave :: proc(self: ^Scene)
{
    self.proc_leave(self.instance)
}

scene_input :: proc(self: ^Scene) -> int
{
    event : sdl.Event

    for sdl.PollEvent(&event) {
        value := self.proc_input(self.instance, event)

        if value != 0 {
            return value
        }
    }

    return 0
}

scene_step :: proc(self: ^Scene, delta: f32)
{
    self.proc_step(self.instance, delta)
}

scene_draw :: proc(self: ^Scene)
{
    self.proc_draw(self.instance)
}
