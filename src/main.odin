package main

import "pax"

main :: proc()
{
    game  := Game {}
    stage := game_stage(&game)

    title := Title_Scene {}
    scene := title_scene(&title)

    pax.stage_loop(&stage, &scene)
}
