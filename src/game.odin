package main

import sdl  "vendor:sdl2"
import sdli "vendor:sdl2/image"

import "pax"

WINDOW_SIZE :: [2]i32 {320, 180}
TILE_SIZE   :: [2]i32 { 16,  16}

Game :: struct
{
    scale: i32,

    window_size: [2]i32,
    tile_size:   [2]i32,

    window: ^sdl.Window,
    render: ^sdl.Renderer,
}

game_start :: proc(stage: ^Game, config: ^pax.Loop_Config)
{
    config.frame_rate = 256
    config.frame_skip = 256

    assert(sdl.Init(sdl.INIT_VIDEO) == 0, sdl.GetErrorString())

    assert(sdli.Init(sdli.INIT_PNG) == sdli.INIT_PNG,
        sdl.GetErrorString())

    stage.scale = 5

    stage.window_size = WINDOW_SIZE * stage.scale
    stage.tile_size   = TILE_SIZE * stage.scale

    stage.window = sdl.CreateWindow("Fallen blood",
        sdl.WINDOWPOS_UNDEFINED, sdl.WINDOWPOS_UNDEFINED,
        stage.window_size.x, stage.window_size.y, {.HIDDEN})

    assert(stage.window != nil, sdl.GetErrorString())

    stage.render = sdl.CreateRenderer(stage.window, -1, {.ACCELERATED})

    assert(stage.render != nil, sdl.GetErrorString())
}

game_stop :: proc(stage: ^Game)
{
    // empty.
}

game_stage :: proc(game: ^Game) -> pax.Stage
{
    stage := pax.Stage {}

    stage.instance = auto_cast game

    stage.proc_start = auto_cast game_start
    stage.proc_stop  = auto_cast game_stop

    return stage
}
