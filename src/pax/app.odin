package pax

import "core:log"
import "core:time"

import sdl  "vendor:sdl2"
import sdli "vendor:sdl2/image"

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

    self.stage = {}
    self.tick  = {}
}

app_insert :: proc(self: ^App, scene: Scene) -> int
{
    index, error := append(&self.scenes, scene)

    if error != nil {
        log.errorf("Unable to insert a scene\n")

        return 0
    }

    return index + 1
}

app_remove :: proc(self: ^App, scene: int)
{
    assert(false, "Not implemented yet")
}

app_clear :: proc(self: ^App)
{
    clear(&self.scenes)
}

app_find :: proc(self: ^App, scene: int) -> ^Scene
{
    count := len(self.scenes)
    index := scene - 1

    if 0 <= index && index < count {
        return &self.scenes[index]
    }

    return nil
}

app_start :: proc(self: ^App) -> bool
{
    count := len(self.scenes)
    index := 0

    state := stage_start(&self.stage)

    if state == true {
        for idx := 0; idx < count; idx += 1 {
            state = scene_start(&self.scenes[idx], &self.stage)

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
    diff := time.tick_lap_time(&self.tick)
    nano := time.duration_nanoseconds(diff)

    return nano
}

app_loop :: proc(self: ^App, stage: Stage, config: App_Config) -> bool
{
    scene := app_find(self, config.first_scene)

    if scene == nil { return false }

    frame_rate: i64 = i64(config.frame_rate)
    frame_skip: i64 = i64(config.frame_skip)
    frame_time: i64 = 1_000_000_000 / frame_rate

    delta: f32 = 1 / f32(frame_rate)
    elaps: i64 = 0
    input: int = 0

    self.stage = stage

    if app_start(self) == false { return false }

    scene_enter(scene)

    for loops: i64 = 0; true && input >= 0; loops = 0 {
        elaps += app_elapsed(self)

        for frame_time < elaps && loops < frame_skip {
            scene_step(scene, delta)

            elaps -= frame_time
            loops += 1
        }

        scene_draw(scene)

        input = scene_input(scene)

        if input > 0 {
            next := app_find(self, input)

            if next != nil {
                scene_leave(scene)
                scene_enter(next)

                scene = next
            }
        }
    }

    scene_leave(scene)
    app_stop(self)

    return true
}

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

scene_start :: proc(self: ^Scene, stage: ^Stage) -> bool
{
    return self.proc_start(self.instance, stage.instance)
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
    event: sdl.Event

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
