package main

import sdl  "vendor:sdl2"
import sdli "vendor:sdl2/image"

import "pax"

WINDOW_SIZE :: [2]int {320, 180}
TILE_SIZE   :: [2]int { 16,  16}

Game :: struct
{
    scale: int,

    window:   ^sdl.Window,
    renderer: ^sdl.Renderer,
}

game_start :: proc(stage: ^Game, config: ^pax.Loop_Config)
{
    config.frame_rate = 30
    config.frame_skip = 30

    assert(sdl.Init(sdl.INIT_VIDEO) == 0, sdl.GetErrorString())

    assert(sdli.Init(sdli.INIT_PNG) == sdli.INIT_PNG,
        sdl.GetErrorString())

    stage.scale = 5

    stage.window = sdl.CreateWindow("Fallen blood",
        sdl.WINDOWPOS_UNDEFINED, sdl.WINDOWPOS_UNDEFINED,
        i32(WINDOW_SIZE.x * stage.scale),
        i32(WINDOW_SIZE.y * stage.scale), {.HIDDEN})

    assert(stage.window != nil, sdl.GetErrorString())

    stage.renderer = sdl.CreateRenderer(stage.window, -1, {.ACCELERATED})

    assert(stage.renderer != nil, sdl.GetErrorString())
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
