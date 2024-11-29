package blood

import "core:time"
import "core:fmt"

Loop_State :: enum {
    SUCCESS, // nothing to report
    SKIPPED, // skipped too much frames
}

Loop_Config :: struct {
    frame_rate: i64,
    frame_skip: i64,
    frame_tick: time.Tick,
}

Stage :: struct ($T: typeid)
{
    config: Loop_Config,

    instance: ^T,

    proc_start: proc(self: ^T, config: ^Loop_Config),
    proc_stop:  proc(self: ^T),
}

Scene :: struct ($T, $U: typeid)
{
    instance: ^T,

    proc_start: proc(self: ^T, stage: ^U),
    proc_stop:  proc(self: ^T),
    proc_input: proc(self: ^T) -> bool,
    proc_step:  proc(self: ^T, delta: f32),
    proc_draw:  proc(self: ^T),
}

stage_start :: proc(stage: ^Stage($T), config: ^Loop_Config)
{
    stage.proc_start(stage.instance, config)
}

stage_stop :: proc(stage: ^Stage($T))
{
    stage.proc_stop(stage.instance)
}

stage_loop :: proc(stage: ^Stage($T), scene: ^Scene($U, T)) -> Loop_State
{
    loop := true

    stage_start(stage, &stage.config)
    scene_start(scene, stage.instance)

    skip: i64 = stage.config.frame_skip
    cntr: i64 = 0

    nano: i64 = 1_000_000_000 / stage.config.frame_rate
    elap: i64 = 0

    step: f32 = 1 / f32(stage.config.frame_rate)

    for loop {
        scene_draw(scene)

        cntr  = 0
        elap += stage_delta(&stage.config)

        for nano < elap && cntr < skip {
            scene_step(scene, step)

            elap -= nano
            elap += stage_delta(&stage.config)
            cntr += 1
        }

        if cntr == skip do return .SKIPPED

        loop = scene_input(scene)
    }

    scene_stop(scene)
    stage_stop(stage)

    return .SUCCESS
}

stage_delta :: proc(config: ^Loop_Config) -> i64
{
    delta := time.tick_lap_time(
        &config.frame_tick)

    nano := time.duration_nanoseconds(delta)

    fmt.printf("INFO: frames = %v\n",
        1 / time.duration_seconds(delta))

    return nano
}

scene_start :: proc(scene: ^Scene($T, $U), stage: ^U)
{
    scene.proc_start(scene.instance, stage)
}

scene_stop :: proc(scene: ^Scene($T, $U))
{
    scene.proc_stop(scene.instance)
}

scene_input :: proc(scene: ^Scene($T, $U)) -> bool
{
    return scene.proc_input(scene.instance)
}

scene_step :: proc(scene: ^Scene($T, $U), delta: f32)
{
    scene.proc_step(scene.instance, delta)
}

scene_draw :: proc(scene: ^Scene($T, $U))
{
    scene.proc_draw(scene.instance)
}
