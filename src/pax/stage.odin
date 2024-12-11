package pax

import "core:time"
import "core:fmt"

Stage_Config :: struct {
    frame_rate: i64,
    frame_skip: i64,
    frame_tick: time.Tick,
}

Stage :: struct
{
    config: Stage_Config,
    scenes: [dynamic]Scene,

    instance: rawptr,

    proc_start: proc(self: rawptr) -> bool,
    proc_stop:  proc(self: rawptr),
}

stage_init :: proc(self: ^Stage, allocator := context.allocator)
{
    self.scenes = make([dynamic]Scene, allocator)
}

stage_destroy :: proc(self: ^Stage)
{
    delete(self.scenes)
}

stage_push :: proc(self: ^Stage, scene: Scene)
{
    append(&self.scenes, scene)
}

stage_clear :: proc(self: ^Stage)
{
    clear(&self.scenes)
}

stage_start :: proc(self: ^Stage)-> bool
{
    state := self.proc_start(self.instance)
    index := 0
    count := len(self.scenes)

    if state == true {
        for idx := 0; idx < count; idx += 1 {
            state = scene_start(&self.scenes[idx], self.instance)

            if state == false {
                index = idx
                break
            }
        }
    }

    if state == false {
        for idx := index; idx > 0; idx -= 1 {
            scene_stop(&self.scenes[idx - 1])
        }
    }

    return state
}

stage_stop :: proc(self: ^Stage)
{
    count := len(self.scenes)

    for idx := count; idx > 0; idx -= 1 {
        scene_stop(&self.scenes[idx - 1])
    }

    self.proc_stop(self.instance)
}

stage_delta :: proc(config: ^Stage_Config) -> i64
{
    delta := time.tick_lap_time(
        &config.frame_tick)

    nano := time.duration_nanoseconds(delta)

    return nano
}

stage_loop :: proc(self: ^Stage, index: int) -> bool
{
    count := len(self.scenes)

    if index < 0 || index >= count { return false }

    if stage_start(self) == false {
        return false
    }

    skip: i64 = self.config.frame_skip
    cntr: i64 = 0

    nano: i64 = 1_000_000_000 / self.config.frame_rate
    elap: i64 = 0
    diff: i64 = 0

    step: f32 = 1 / f32(self.config.frame_rate)

    scene := &self.scenes[index]
    loop  := true

    scene_enter(scene)

    for loop {
        diff = stage_delta(&self.config)

        scene_draw(scene, 1 / f32(diff))

        cntr  = 0
        elap += diff

        for nano < elap && cntr < skip {
            scene_step(scene, step)

            elap -= nano
            cntr += 1
        }

        index := scene_input(scene)

        if index < 0 { loop = false }

        if 0 < index && index <= count {
            scene_leave(scene)

            scene = &self.scenes[index - 1]

            scene_enter(scene)
        }
    }

    scene_leave(scene)
    stage_stop(self)

    return true
}

Scene :: struct
{
    instance: rawptr,

    proc_start: proc(self: rawptr, stage: rawptr) -> bool,
    proc_stop:  proc(self: rawptr),
    proc_enter: proc(self: rawptr),
    proc_leave: proc(self: rawptr),
    proc_input: proc(self: rawptr) -> int,
    proc_step:  proc(self: rawptr, delta: f32),
    proc_draw:  proc(self: rawptr, frame: f32),
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
    return self.proc_input(self.instance)
}

scene_step :: proc(self: ^Scene, delta: f32)
{
    self.proc_step(self.instance, delta)
}

scene_draw :: proc(self: ^Scene, frame: f32)
{
    self.proc_draw(self.instance, frame)
}
