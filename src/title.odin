package main

import sdl  "vendor:sdl2"
import sdli "vendor:sdl2/image"

import "core:fmt"

import "pax"

PLAYER_IDLE_DOWN_0 :: [4]int {64,  0, 16, 32}
PLAYER_IDLE_ORIGIN :: [2]int { 0, 16}
PLAYER_POINT       :: [2]int {16, 16}
PLAYER_SPEED       :: 128

TEXTURES :: [2]string {
    "data/scene/title/tileset.png",
    "data/scene/title/characters.png",
}

GROUND_GRID       :: "data/scene/title/ground.csv"
GROUND_SOLID_GRID :: "data/scene/title/ground_solid.csv"
OBJECT_GRID       :: "data/scene/title/object.csv"
OBJECT_SOLID_GRID :: "data/scene/title/object_solid.csv"
ENTITY_GRID       :: "data/scene/title/entity.csv"

SPRITE :: "data/scene/title/sprite.csv"

Player :: struct
{
    using visible: pax.Visible,

    movement: Movement,
    controls: Controls,
    camera:   ^pax.Camera,
}

Title_Scene :: struct
{
    camera: pax.Camera,

    window:  ^sdl.Window,
    texture: pax.Texture,
    render:  pax.Renderer,

    keyboard_channel: pax.Channel(sdl.KeyboardEvent),

    sprite_table: pax.Sprite_Table,

    ground_layer:       pax.Tile_Grid,
    ground_solid_layer: pax.Actor_Grid,
    object_layer:       pax.Tile_Grid,
    object_solid_layer: pax.Actor_Grid,
    entity_layer:       pax.Actor_Grid,

    world: pax.World,

    player_group: pax.Group(Player),

    player: int,
}

player_keyboard :: proc(self: ^Title_Scene, event: sdl.KeyboardEvent) -> bool {
    player := pax.group_find(&self.player_group, self.player)

    if event.type == .KEYUP {
        #partial switch event.keysym.sym {
            case .D, .RIGHT: player.controls.east  = false
            case .W, .UP:    player.controls.north = false
            case .A, .LEFT:  player.controls.west  = false
            case .S, .DOWN:  player.controls.south = false
        }
    }

    if event.type == .KEYDOWN {
        #partial switch event.keysym.sym {
            case .D, .RIGHT: player.controls.east  = true
            case .W, .UP:    player.controls.north = true
            case .A, .LEFT:  player.controls.west  = true
            case .S, .DOWN:  player.controls.south = true
        }
    }

    return true
}

camera_keyboard :: proc(self: ^Title_Scene, event: sdl.KeyboardEvent) -> bool {
    if event.type == .KEYDOWN {
        #partial switch event.keysym.sym {
            case .P, .PLUS,  .KP_PLUS:  self.camera.zoom += 1
            case .M, .MINUS, .KP_MINUS: self.camera.zoom -= 1
        }
    }

    return true
}

title_scene_keyboard :: proc(self: ^Title_Scene, event: sdl.KeyboardEvent) -> bool {
    if event.type == .KEYUP {
        #partial switch event.keysym.sym {
            case .ESCAPE: return false

            case .R: {
                if title_scene_load(self) == false {
                    return false
                }
            }
        }
    }

    return true
}

title_scene_load :: proc(scene: ^Title_Scene) -> bool
{
    for name in TEXTURES {
        state := pax.texture_load(&scene.texture, name)

        if state == false {
            fmt.printf("FATAL: Couldn't load resource '%v'\n",
                name)

            return state
        }

        pax.renderer_push(&scene.render, scene.texture.pointer)
    }

    if pax.grid_load(&scene.ground_layer,       GROUND_GRID)       == false { return false }
    if pax.grid_load(&scene.ground_solid_layer, GROUND_SOLID_GRID) == false { return false }
    if pax.grid_load(&scene.object_layer,       OBJECT_GRID)       == false { return false }
    if pax.grid_load(&scene.object_solid_layer, OBJECT_SOLID_GRID) == false { return false }
    if pax.grid_load(&scene.entity_layer,       ENTITY_GRID)       == false { return false }

    if pax.sprite_table_load(&scene.sprite_table, SPRITE) == false {
        return false
    }

    player := pax.group_find(&scene.player_group, scene.player)

    player.movement.point = PLAYER_POINT
    player.movement.speed = PLAYER_SPEED
    player.movement.state = .STILL

    player.visible.sprite = 10

    player.camera = &scene.camera

    for value, index in scene.entity_layer.grid.value {
        actor := pax.group_find(&scene.player_group, value - 1)

        if actor == nil { continue }

        actor.movement.point = pax.grid_to_point(&scene.entity_layer,
            pax.grid_pair(&scene.entity_layer, index))
    }

    scene.camera.size   = WINDOW_SIZE
    scene.camera.offset = WINDOW_SIZE / 2 - TILE_SIZE / 2

    return true
}

title_scene_start :: proc(scene: ^Title_Scene, stage: ^Game) -> bool
{
    scene.camera.zoom = f32(stage.scale)

    scene.window = stage.window

    pax.renderer_init(&scene.render, stage.render)
    pax.texture_init(&scene.texture, scene.render.render)

    pax.sprite_table_init(&scene.sprite_table)

    pax.grid_init(&scene.ground_layer, TILE_SIZE)
    pax.grid_init(&scene.ground_solid_layer, TILE_SIZE)
    pax.grid_init(&scene.object_layer, TILE_SIZE)
    pax.grid_init(&scene.object_solid_layer, TILE_SIZE)
    pax.grid_init(&scene.entity_layer, TILE_SIZE)

    pax.channel_init(&scene.keyboard_channel)
    pax.world_init(&scene.world)
    pax.group_init(&scene.player_group)

    scene.player = pax.world_create_actor(&scene.world)

    pax.group_insert(&scene.player_group, scene.player)

    if title_scene_load(scene) == false { return false }

    pax.channel_connect(&scene.keyboard_channel, auto_cast player_keyboard, scene)
    pax.channel_connect(&scene.keyboard_channel, auto_cast camera_keyboard, scene)
    pax.channel_connect(&scene.keyboard_channel, auto_cast title_scene_keyboard, scene)

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

    for sdl.PollEvent(&event) {
        #partial switch event.type {
            case .KEYUP:   return pax.channel_send(&scene.keyboard_channel, event.key)
            case .KEYDOWN: return pax.channel_send(&scene.keyboard_channel, event.key)
            case .QUIT:    return false
        }
    }

    return true
}

title_scene_step :: proc(scene: ^Title_Scene, delta: f32)
{
    for index in 0 ..< scene.player_group.count {
        player := &scene.player_group.values[index]

        angle := controls_angle(&player.controls)

        switch angle {
            case { 0, -1}: player.visible.sprite = 10
            case { 1, -1}: player.visible.sprite = 11
            case { 1,  0}: player.visible.sprite = 12
            case { 1,  1}: player.visible.sprite = 13
            case { 0,  1}: player.visible.sprite = 14
            case {-1,  1}: player.visible.sprite = 15
            case {-1,  0}: player.visible.sprite = 16
            case {-1, -1}: player.visible.sprite = 17
        }

        angle = collider_test(&scene.ground_solid_layer.grid, player.movement.point, angle)
        angle = collider_test(&scene.object_solid_layer.grid, player.movement.point, angle)
        angle = collider_test(&scene.entity_layer.grid,       player.movement.point, angle)

        if player.movement.state == .STILL {
            collider_move(&scene.entity_layer.grid, player.movement.point, angle)
        }

        movement_step(&player.movement, &scene.entity_layer.grid, angle, delta)

        player.visible.point = player.movement.point

        if player.camera != nil {
            player.camera.follow = player.movement.point
        }
    }
}

title_scene_draw :: proc(scene: ^Title_Scene, extra: f32)
{
    assert(sdl.RenderClear(scene.render.render) == 0,
        sdl.GetErrorString())

    follow := pax.grid_from_point(&scene.ground_layer, scene.camera.follow)
    size   := pax.grid_from_point(&scene.ground_layer, scene.camera.size)
    start  := follow - size - 1
    stop   := follow + size + 2

    // NOTE: if two layers never swap order, draw them fully one after the other.

    for row in start.y ..< stop.y {
        for col in start.x ..< stop.x {
            index, point := pax.tile_grid_sprite(&scene.ground_layer, {col, row})

            if index != 0 {
                sprite := pax.sprite_table_find(&scene.sprite_table, index)

                if sprite != nil {
                    pax.camera_draw(&scene.camera, &scene.render, sprite^, point)
                }
            }
        }
    }

    for row in start.y ..< stop.y {
        for col in start.x ..< stop.x {
            index, point := pax.tile_grid_sprite(&scene.object_layer, {col, row})

            if index != 0 {
                sprite := pax.sprite_table_find(&scene.sprite_table, index)

                if sprite != nil {
                    pax.camera_draw(&scene.camera, &scene.render, sprite^, point)
                }
            }

            index, point = pax.actor_grid_sprite(&scene.entity_layer, {col, row}, &scene.player_group)

            if index != 0 {
                sprite := pax.sprite_table_find(&scene.sprite_table, index)

                if sprite != nil {
                    pax.camera_draw(&scene.camera, &scene.render, sprite^, point)
                }
            }
        }
    }

    sdl.RenderPresent(scene.render.render)
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
