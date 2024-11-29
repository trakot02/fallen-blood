package main

import "core:fmt"

import fbd "blood"

main :: proc()
{
    stage := fbd.Stage(Game) {}
    blood := Game {}

    stage.instance   = &blood
    stage.proc_start = auto_cast game_start
    stage.proc_stop  = auto_cast game_stop

    scene := fbd.Scene(Title_Scene, Game) {}
    title := Title_Scene {}

    scene.instance   = &title
    scene.proc_start = auto_cast title_scene_start
    scene.proc_stop  = auto_cast title_scene_stop
    scene.proc_input = auto_cast title_scene_input
    scene.proc_step  = auto_cast title_scene_step
    scene.proc_draw  = auto_cast title_scene_draw

    state := fbd.stage_loop(&stage, &scene)

    if state == .SKIPPED {
        fmt.printf("ERROR: Skipped too much frames\n")
    }
}
