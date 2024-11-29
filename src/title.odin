package main

import "core:fmt"

import sdl  "vendor:sdl2"
import sdli "vendor:sdl2/image"

import fbd "blood"

PLAYER_TEXTURE     :: "data/scene/title/player.png"
PLAYER_IDLE_DOWN_0 :: sdl.Rect  {0, 0, 16, 16}
PLAYER_POINT       :: sdl.FRect {0, 0, 16, 16}

Title_Scene :: struct
{
    window_scale: i32,
    window_size:  [2]i32,

    sprite_scale: i32,

    window: ^sdl.Window,
    render: ^sdl.Renderer,

    player: fbd.Sprite,
}

title_scene_load :: proc(scene: ^Title_Scene)
{
    scene.player.frame = PLAYER_IDLE_DOWN_0
    scene.player.point = PLAYER_POINT

    fbd.sprite_load_texture(&scene.player, scene.render, PLAYER_TEXTURE)
}

title_scene_start :: proc(scene: ^Title_Scene, stage: ^Game)
{
    scene.window_scale = stage.window_scale
    scene.window_size  = stage.window_size

    scene.sprite_scale = stage.sprite_scale

    scene.window = stage.window
    scene.render = stage.render

    title_scene_load(scene)

    sdl.ShowWindow(scene.window)
}

title_scene_stop :: proc(scene: ^Title_Scene) {}

title_scene_input :: proc(scene: ^Title_Scene) -> bool
{
    event: sdl.Event

    for sdl.PollEvent(&event) {
        #partial switch event.type {
            case .KEYUP: {
                key := event.key

                #partial switch key.keysym.scancode {
                    case sdl.SCANCODE_ESCAPE:
                        return false
                }
            }

            case .QUIT: return false
        }
    }

    return true
}

title_scene_step :: proc(scene: ^Title_Scene, delta: f32)
{
    scene.player.point.x += 100 * delta
    scene.player.point.y += 100 * delta
}

title_scene_draw :: proc(scene: ^Title_Scene)
{
    assert(sdl.RenderClear(scene.render) == 0,
        sdl.GetErrorString())

    fbd.sprite_draw(&scene.player, scene.render, f32(scene.sprite_scale))

    sdl.RenderPresent(scene.render)
}
