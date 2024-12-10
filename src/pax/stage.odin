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

stage_init :: proc(stage: ^Stage, allocator := context.allocator)
{
    stage.scenes = make([dynamic]Scene, allocator)
}

stage_destroy :: proc(stage: ^Stage)
{
    delete(stage.scenes)
}

stage_push :: proc(stage: ^Stage, scene: Scene)
{
    append(&stage.scenes, scene)
}

stage_clear :: proc(stage: ^Stage)
{
    clear(&stage.scenes)
}

stage_start :: proc(stage: ^Stage)-> bool
{
    state := stage.proc_start(stage.instance)
    index := 0
    count := len(stage.scenes)

    if state == true {
        for idx := 0; idx < count; idx += 1 {
            state = scene_start(&stage.scenes[idx], stage.instance)

            if state == false {
                index = idx
                break
            }
        }
    }

    if state == false {
        for idx := index; idx > 0; idx -= 1 {
            scene_stop(&stage.scenes[idx - 1])
        }
    }

    return state
}

stage_stop :: proc(stage: ^Stage)
{
    count := len(stage.scenes)

    for idx := count; idx > 0; idx -= 1 {
        scene_stop(&stage.scenes[idx - 1])
    }

    stage.proc_stop(stage.instance)
}

stage_delta :: proc(config: ^Stage_Config) -> i64
{
    delta := time.tick_lap_time(
        &config.frame_tick)

    nano := time.duration_nanoseconds(delta)

    return nano
}

stage_loop :: proc(stage: ^Stage, index: int) -> bool
{
    count := len(stage.scenes)

    if index < 0 || index >= count { return false }

    if stage_start(stage) == false {
        return false
    }

    skip: i64 = stage.config.frame_skip
    cntr: i64 = 0

    nano: i64 = 1_000_000_000 / stage.config.frame_rate
    elap: i64 = 0
    diff: i64 = 0

    step: f32 = 1 / f32(stage.config.frame_rate)

    scene := &stage.scenes[index]
    loop  := true

    scene_enter(scene)

    for loop {
        diff = stage_delta(&stage.config)

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

        if index > 0 {
            scene_leave(scene)

            scene = &stage.scenes[index - 1]

            scene_enter(scene)
        }
    }

    scene_leave(scene)
    stage_stop(stage)

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

scene_start :: proc(scene: ^Scene, stage: rawptr) -> bool
{
    return scene.proc_start(scene.instance, stage)
}

scene_stop :: proc(scene: ^Scene)
{
    scene.proc_stop(scene.instance)
}

scene_enter :: proc(scene: ^Scene)
{
    scene.proc_enter(scene.instance)
}

scene_leave :: proc(scene: ^Scene)
{
    scene.proc_leave(scene.instance)
}

scene_input :: proc(scene: ^Scene) -> int
{
    return scene.proc_input(scene.instance)
}

scene_step :: proc(scene: ^Scene, delta: f32)
{
    scene.proc_step(scene.instance, delta)
}

scene_draw :: proc(scene: ^Scene, frame: f32)
{
    scene.proc_draw(scene.instance, frame)
}
