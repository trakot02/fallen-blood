package pax

import "core:time"
import "core:fmt"

Loop_Config :: struct {
    frame_rate: i64,
    frame_skip: i64,
    frame_tick: time.Tick,
}

Stage :: struct
{
    config: Loop_Config,

    instance: rawptr,

    proc_start: proc(self: rawptr, config: ^Loop_Config),
    proc_stop:  proc(self: rawptr),
}

stage_delta :: proc(config: ^Loop_Config) -> i64
{
    delta := time.tick_lap_time(
        &config.frame_tick)

    nano := time.duration_nanoseconds(delta)

    return nano
}

stage_start :: proc(stage: ^Stage, config: ^Loop_Config)
{
    stage.proc_start(stage.instance, config)
}

stage_stop :: proc(stage: ^Stage)
{
    stage.proc_stop(stage.instance)
}

stage_loop :: proc(stage: ^Stage, scene: ^Scene)
{
    loop := true

    stage_start(stage, &stage.config)

    if scene_start(scene, stage.instance) == false {
        stage_stop(stage)

        return
    }

    skip: i64 = stage.config.frame_skip
    cntr: i64 = 0

    nano: i64 = 1_000_000_000 / stage.config.frame_rate
    elap: i64 = 0
    diff: i64 = 0

    step: f32 = 1 / f32(stage.config.frame_rate)

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

        loop = scene_input(scene)
    }

    scene_stop(scene)
    stage_stop(stage)
}

Scene :: struct
{
    instance: rawptr,

    proc_start: proc(self: rawptr, stage: rawptr) -> bool,
    proc_stop:  proc(self: rawptr),
    proc_input: proc(self: rawptr) -> bool,
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

scene_input :: proc(scene: ^Scene) -> bool
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
