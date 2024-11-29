package main

import sdl  "vendor:sdl2"
import sdli "vendor:sdl2/image"

import fbd "blood"

Game :: struct
{
    window_scale: i32,
    window_size:  [2]i32,

    sprite_scale: i32,

    window: ^sdl.Window,
    render: ^sdl.Renderer,
}

game_start :: proc(stage: ^Game, config: ^fbd.Loop_Config)
{
    config.frame_rate = 64
    config.frame_skip = 64

    assert(sdl.Init(sdl.INIT_VIDEO) == 0, sdl.GetErrorString())

    assert(sdli.Init(sdli.INIT_PNG) == sdli.INIT_PNG,
        sdl.GetErrorString())

    stage.window_scale = 4
    stage.window_size  = {320, 180}

    stage.sprite_scale = 3

    size := stage.window_size * stage.window_scale

    stage.window = sdl.CreateWindow("Fallen blood",
        sdl.WINDOWPOS_UNDEFINED, sdl.WINDOWPOS_UNDEFINED,
        size.x, size.y, {.HIDDEN})

    assert(stage.window != nil, sdl.GetErrorString())

    stage.render = sdl.CreateRenderer(stage.window, -1, {.ACCELERATED})

    assert(stage.render != nil, sdl.GetErrorString())
}

game_stop :: proc(stage: ^Game)
{
    sdl.DestroyRenderer(stage.render)
    sdl.DestroyWindow(stage.window)

    sdli.Quit()
    sdl.Quit()
}
