package main

import "core:fmt"

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

game_start :: proc(stage: ^Game) -> bool
{
    if sdl.Init(sdl.INIT_VIDEO) != 0 {
        fmt.printf("FATAL: %v", sdl.GetErrorString())

        return false
    }

    if sdli.Init(sdli.INIT_PNG) != sdli.INIT_PNG {
        fmt.printf("FATAL: %v", sdl.GetErrorString())

        return false
    }

    stage.scale = 5

    stage.window = sdl.CreateWindow("Fallen blood",
        sdl.WINDOWPOS_UNDEFINED, sdl.WINDOWPOS_UNDEFINED,
        i32(WINDOW_SIZE.x * stage.scale),
        i32(WINDOW_SIZE.y * stage.scale), {.HIDDEN})

    if stage.window == nil {
        fmt.printf("FATAL: %v", sdl.GetErrorString())

        return false
    }

    stage.renderer = sdl.CreateRenderer(stage.window, -1, {.ACCELERATED})

    if stage.renderer == nil {
        fmt.printf("FATAL: %v", sdl.GetErrorString())

        return false
    }

    return true
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
