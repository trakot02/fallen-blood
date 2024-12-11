package main

import "pax"

main :: proc()
{
    game  := Game {}
    stage := game_stage(&game)

    pax.stage_init(&stage)

    title := Title_Scene {}
    pax.stage_push(&stage, title_scene(&title))

    stage.config.frame_rate = 60
    stage.config.frame_skip = 60

    pax.stage_loop(&stage, 0)
    pax.stage_destroy(&stage)
}
