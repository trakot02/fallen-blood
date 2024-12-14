package pax

import "core:log"
import "core:time"

import sdl "vendor:sdl2"

App_Config :: struct
{
    frame_rate:  int,
    frame_skip:  int,
    first_scene: int,
}

App :: struct
{
    tick: time.Tick,

    stage:  Stage,
    scenes: [dynamic]Scene,
}

app_init :: proc(self: ^App, allocator := context.allocator)
{
    self.scenes = make([dynamic]Scene, allocator)
}

app_destroy :: proc(self: ^App)
{
    delete(self.scenes)
}

app_push :: proc(self: ^App, scene: Scene) -> bool
{
    _, error := append(&self.scenes, scene)

    if error != nil {
        log.errorf("Unable to insert a scene\n")
    }

    return error == nil
}

app_clear :: proc(self: ^App)
{
    clear(&self.scenes)
}

app_start :: proc(self: ^App) -> bool
{
    count := len(self.scenes)
    index := 0

    state := stage_start(&self.stage)

    if state == true {
        for idx := 0; idx < count; idx += 1 {
            state = scene_start(&self.scenes[idx], self.stage.instance)

            if state == false {
                index = idx
                idx   = count
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

app_stop :: proc(self: ^App)
{
    for &scene in self.scenes {
        scene_stop(&scene)
    }

    stage_stop(&self.stage)
}

app_elapsed :: proc(self: ^App) -> i64
{
    durat := time.tick_lap_time(&self.tick)
    nano  := time.duration_nanoseconds(durat)

    return nano
}

app_loop :: proc(self: ^App, stage: Stage, config: App_Config) -> bool
{
    count := len(self.scenes)

    if config.first_scene < 0 || config.first_scene >= count {
        return false
    }

    scene := &self.scenes[config.first_scene]

    frame_rate : i64 = i64(config.frame_rate)
    frame_skip : i64 = i64(config.frame_skip)
    frame_time : i64 = 1_000_000_000 / frame_rate

    delta : f32 = 1 / f32(frame_rate)
    elaps : i64 = 0

    self.stage = stage

    if app_start(self) == false { return false }

    scene_enter(scene)

    for loops : i64 = 0; true; loops = 0 {
        elaps += app_elapsed(self)

        for frame_time < elaps && loops < frame_skip {
            scene_step(scene, delta)

            elaps -= frame_time
            loops += 1
        }

        scene_draw(scene)

        value := scene_input(scene)
        index := value - 1

        if value < 0 { break }

        if 0 < value && value <= count {
            scene_leave(scene)

            scene = &self.scenes[index]

            scene_enter(scene)
        }
    }

    scene_leave(scene)
    app_stop(self)

    return true
}
