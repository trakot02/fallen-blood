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

GROUND_TEXTURE :: "data/scene/title/ground.png"
GROUND_GRID    :: "data/scene/title/ground.csv"

Player :: struct {
    sprite:   Sprite,
    movement: Movement,
    controls: Controls,
}

Title_Scene :: struct
{
    window_size: [2]i32,
    tile_size:   [2]i32,

    camera: pax.Camera,

    window: ^sdl.Window,
    render: ^sdl.Renderer,

    txtr_registry: pax.Registry(pax.Texture),
    grid_registry: pax.Registry(pax.Grid),

    world: pax.World,

    player_group: pax.Group(Player),

    player: pax.Actor,
}

title_scene_load :: proc(scene: ^Title_Scene) -> bool
{
    player: ^Player

    texture, error := pax.registry_load(&scene.txtr_registry, PLAYER_TEXTURE)

    if error != nil {
        fmt.printf("Unable to find '%v'\n", PLAYER_TEXTURE)

        return false
    }

    _, err1 := pax.registry_load(&scene.txtr_registry, GROUND_TEXTURE)

    if err1 != nil {
        fmt.printf("Unable to find '%v'\n", GROUND_TEXTURE)

        return false
    }

    _, err2 := pax.registry_load(&scene.grid_registry, GROUND_GRID)

    if err2 != nil {
        fmt.printf("Unable to find '%v'\n", GROUND_GRID)

        return false
    }

    scene.player, player = pax.group_create_actor(&scene.player_group)

    player.sprite.texture = texture
    player.sprite.frame   = PLAYER_IDLE_DOWN_0

    player.movement.point = PLAYER_POINT
    player.movement.speed = PLAYER_SPEED
    player.movement.state = .STILL

    scene.camera.target = PLAYER_POINT

    scene.camera.offset = [2]f32 {
        f32(WINDOW_SIZE.x) / 2 - f32(TILE_SIZE.x) / 2,
        f32(WINDOW_SIZE.y) / 2 - f32(TILE_SIZE.y) / 2,
    }

    return true
}

title_scene_start :: proc(scene: ^Title_Scene, stage: ^Game) -> bool
{
    scene.camera.scale  = f32(stage.scale)
    scene.camera.render = stage.render

    scene.window_size = stage.window_size
    scene.tile_size   = stage.tile_size
    scene.window      = stage.window
    scene.render      = stage.render

    scene.txtr_registry = pax.texture_registry(scene.render)
    scene.grid_registry = pax.grid_registry()

    pax.registry_create(&scene.txtr_registry)
    pax.registry_create(&scene.grid_registry)

    pax.world_create(&scene.world)
    pax.group_create(&scene.player_group, &scene.world)

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

    player := pax.group_find(&scene.player_group, scene.player)

    for sdl.PollEvent(&event) {
        #partial switch event.type {
            case .KEYUP: {
                key := event.key

                #partial switch key.keysym.sym {
                    case .ESCAPE: return false

                    case .R: title_scene_load(scene)

                    case .F: scene.camera.target = player.movement.point
                    case .G: scene.camera.target = {0, 0}

                    case .D, .RIGHT: player.controls.east  = false
                    case .W, .UP:    player.controls.north = false
                    case .A, .LEFT:  player.controls.west  = false
                    case .S, .DOWN:  player.controls.south = false
                }
            }

            case .KEYDOWN: {
                key := event.key

                #partial switch key.keysym.sym {
                    case .D, .RIGHT: player.controls.east  = true
                    case .W, .UP:    player.controls.north = true
                    case .A, .LEFT:  player.controls.west  = true
                    case .S, .DOWN:  player.controls.south = true
                }
            }

            case .QUIT: return false
        }
    }

    return true
}

title_scene_step :: proc(scene: ^Title_Scene, delta: f32)
{
    player := pax.group_find(&scene.player_group, scene.player)

    if player.movement.state == .STILL {
        player.movement.delta = {
            i32(player.controls.east)  - i32(player.controls.west),
            i32(player.controls.south) - i32(player.controls.north),
        }

        if player.movement.delta == {0, 0} do return

        dist := [2]f32 {
            f32(player.movement.delta.x * scene.tile_size.x),
            f32(player.movement.delta.y * scene.tile_size.y),
        }

        player.movement.angle = linalg.normalize0([2]f32 {
            f32(player.movement.delta.x), f32(player.movement.delta.y),
        })

        player.movement.target = player.movement.point + dist
        player.movement.state  = .MOVING
    }

    if player.movement.state == .MOVING {
        player.movement.point += player.movement.angle * player.movement.speed * delta

        dist := [2]i32 {
            i32(player.movement.target.x) - i32(player.movement.point.x),
            i32(player.movement.target.y) - i32(player.movement.point.y),
        }

        if dist.x * player.movement.delta.x <= 0 {
            player.movement.point.x = player.movement.target.x
        }

        if dist.y * player.movement.delta.y <= 0 {
            player.movement.point.y = player.movement.target.y
        }

        if player.movement.target == player.movement.point {
            player.movement.state = .STILL
        }
    }

    scene.camera.target = player.movement.point
}

title_scene_draw :: proc(scene: ^Title_Scene, extra: f32)
{
    assert(sdl.RenderClear(scene.render) == 0,
        sdl.GetErrorString())

    ground_tex, _ := pax.registry_load(&scene.txtr_registry, GROUND_TEXTURE)
    ground_lyr, _ := pax.registry_load(&scene.grid_registry, GROUND_GRID)

    for value, index in ground_lyr.value {
        ground_spr := Sprite {
            ground_tex, {0, 0, scene.tile_size.x, scene.tile_size.y}
        }

        ground_spr.frame.x = (i32(value) % (ground_tex.size.x / scene.tile_size.x)) * scene.tile_size.x
        ground_spr.frame.y = (i32(value) / (ground_tex.size.x / scene.tile_size.y)) * scene.tile_size.y

        point := [2]f32 {
            f32((i32(index) % ground_lyr.size.x) * scene.tile_size.x),
            f32((i32(index) / ground_lyr.size.x) * scene.tile_size.y),
        }

        sprite_draw(&ground_spr, &scene.camera, point)
    }

    player := pax.group_find(&scene.player_group, scene.player)

    sprite_draw(&player.sprite, &scene.camera, player.movement.point)

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
