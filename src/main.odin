package main

import "core:log"

import "pax"

main :: proc()
{
    app  := pax.App {}
    game := Game_Stage {}
    main := Main_Scene {}

    context.logger = log.create_console_logger(lowest = .Debug)

    pax.app_init(&app)
    pax.app_insert(&app, main_scene(&main))

    succ := pax.app_loop(&app, game_stage(&game), {
        frame_rate  = 60,
        frame_skip  = 60,
        first_scene = 1,
    })

    if succ == false {
        log.errorf("result = %v", succ)
    }

    pax.app_destroy(&app)
}
