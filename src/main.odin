package main

import "core:log"

import "pax"

main :: proc()
{
    context.logger = log.create_console_logger(lowest = .Debug)

    app := pax.App {}

    game := Game_Stage {}
    main := Main_Scene {}

    pax.app_init(&app)
    pax.app_push(&app, main_scene(&main))

    succ := pax.app_loop(&app, game_stage(&game), {
        frame_rate = 60,
        frame_skip = 60,
    })

    if succ == false {
        log.errorf("result = %v", succ)
    }

    pax.app_destroy(&app)
}
