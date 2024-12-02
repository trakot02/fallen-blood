package main

import "core:math/linalg"
import "core:fmt"
import "core:os"

import sdl  "vendor:sdl2"
import sdli "vendor:sdl2/image"

import "pax"

PLAYER             :: 0
PLAYER_TEXTURE     :: "data/scene/title/player.png"
PLAYER_IDLE_DOWN_0 :: [4]i32 { 0,  0, 16, 16}
PLAYER_POINT       :: [2]f32 {16, 16}
PLAYER_SPEED       :: 128

Title_Scene :: struct
{
    scale: i32,

    window_size: [2]i32,
    tile_size:   [2]i32,

    window: ^sdl.Window,
    render: ^sdl.Renderer,

    tex_registry: pax.Registry(pax.Texture),

    // replace with archetypes
    sprites:   [dynamic]Sprite,
    movements: [dynamic]Movement,
    inputs:    [dynamic]Input,
}

title_scene_load :: proc(scene: ^Title_Scene) -> bool
{
    inject_at(&scene.sprites,   PLAYER, Sprite {})
    inject_at(&scene.movements, PLAYER, Movement {})
    inject_at(&scene.inputs,    PLAYER, Input {})

    texture, error := pax.registry_load(&scene.tex_registry, PLAYER_TEXTURE)

    if error != nil {
        fmt.printf("Unable to find '%v'\n", PLAYER_TEXTURE)

        return false
    }

    player_spr         := &scene.sprites[PLAYER]
    player_spr.texture  = texture
    player_spr.frame    = PLAYER_IDLE_DOWN_0

    player_mov       := &scene.movements[PLAYER]
    player_mov.point  = PLAYER_POINT * f32(scene.scale)
    player_mov.speed  = PLAYER_SPEED * f32(scene.scale)
    player_mov.state  = .STILL

    return true
}

title_scene_start :: proc(scene: ^Title_Scene, stage: ^Game) -> bool
{
    scene.scale       = stage.scale
    scene.window_size = stage.window_size
    scene.tile_size   = stage.tile_size
    scene.window      = stage.window
    scene.render      = stage.render

    scene.tex_registry = pax.texture_registry(scene.render)

    pax.registry_create(&scene.tex_registry)

    if title_scene_load(scene) == false {
        return false
    }

    sdl.ShowWindow(scene.window)

    return true
}

title_scene_stop :: proc(scene: ^Title_Scene)
{
    sdl.HideWindow(scene.window)
}

title_scene_input :: proc(scene: ^Title_Scene) -> bool
{
    event: sdl.Event

    player_inp := &scene.inputs[PLAYER]

    for sdl.PollEvent(&event) {
        #partial switch event.type {
            case .KEYUP: {
                key := event.key

                #partial switch key.keysym.sym {
                    case .ESCAPE: return false

                    case .R: title_scene_load(scene)

                    case .D, .RIGHT: player_inp.east  = false
                    case .W, .UP:    player_inp.north = false
                    case .A, .LEFT:  player_inp.west  = false
                    case .S, .DOWN:  player_inp.south = false
                }
            }

            case .KEYDOWN: {
                key := event.key

                #partial switch key.keysym.sym {
                    case .D, .RIGHT: player_inp.east  = true
                    case .W, .UP:    player_inp.north = true
                    case .A, .LEFT:  player_inp.west  = true
                    case .S, .DOWN:  player_inp.south = true
                }
            }

            case .QUIT: return false
        }
    }

    return true
}

title_scene_step :: proc(scene: ^Title_Scene, delta: f32)
{
    player_mov := &scene.movements[PLAYER]
    player_inp := &scene.inputs[PLAYER]

    if player_mov.state == .STILL {
        player_mov.delta = {
            i32(player_inp.east)  - i32(player_inp.west),
            i32(player_inp.south) - i32(player_inp.north),
        }

        if player_mov.delta == {0, 0} do return

        dist := [2]f32 {
            f32(player_mov.delta.x * scene.tile_size.x),
            f32(player_mov.delta.y * scene.tile_size.y),
        }

        player_mov.angle = linalg.normalize0([2]f32 {
            f32(player_mov.delta.x), f32(player_mov.delta.y),
        })

        player_mov.target = player_mov.point + dist
        player_mov.state  = .MOVING
    }

    if player_mov.state == .MOVING {
        player_mov.point += player_mov.angle *
            player_mov.speed * delta

        dist := [2]i32 {
            i32(player_mov.target.x) - i32(player_mov.point.x),
            i32(player_mov.target.y) - i32(player_mov.point.y),
        }

        if dist.x * player_mov.delta.x <= 0 {
            player_mov.point.x = player_mov.target.x
        }

        if dist.y * player_mov.delta.y <= 0 {
            player_mov.point.y = player_mov.target.y
        }

        if player_mov.target == player_mov.point {
            player_mov.state = .STILL
        }
    }
}

title_scene_draw :: proc(scene: ^Title_Scene, extra: f32)
{
    assert(sdl.RenderClear(scene.render) == 0,
        sdl.GetErrorString())

    player_spr := scene.sprites[PLAYER]
    player_mov := scene.movements[PLAYER]

    dest := [4]f32 {
        player_mov.point.x,
        player_mov.point.y,
        f32(player_spr.frame.z * scene.scale),
        f32(player_spr.frame.w * scene.scale),
    }

    sprite_draw(&player_spr, scene.render, dest)

    sdl.RenderPresent(scene.render)
}

title_scene :: proc(title: ^Title_Scene) -> pax.Scene
{
    scene := pax.Scene {}

    scene.instance = auto_cast title

    scene.proc_start = auto_cast title_scene_start
    scene.proc_stop  = auto_cast title_scene_stop
    scene.proc_input = auto_cast title_scene_input
    scene.proc_step  = auto_cast title_scene_step
    scene.proc_draw  = auto_cast title_scene_draw

    return scene
}
