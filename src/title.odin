package main

import "core:fmt"

import sdl  "vendor:sdl2"
import sdli "vendor:sdl2/image"

import "pax"

GRID    :: "data/scene/title/table_grid.csv"
TEXTURE :: "data/scene/title/table_texture.csv"
SPRITE  :: "data/scene/title/table_sprite.csv"

GRID_SIZE :: [2]int {24, 17}

Title_Scene :: struct
{
    camera: pax.Camera,

    window:   ^sdl.Window,
    renderer: ^sdl.Renderer,

    graphics: pax.Renderer,

    keyboard_channel: pax.Channel(sdl.KeyboardEvent),

    grid_table:    pax.Grid_Table,
    texture_table: pax.Texture_Table,
    sprite_table:  pax.Sprite_Table,

    sprite_grid:  pax.Grid_Stack,
    solid_grid:   pax.Grid_Stack,

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
    scene.camera.size   = WINDOW_SIZE
    scene.camera.offset = WINDOW_SIZE / 2 - TILE_SIZE / 2

    if pax.grid_table_load(&scene.grid_table, GRID)          == false { return false }
    if pax.texture_table_load(&scene.texture_table, TEXTURE) == false { return false }
    if pax.sprite_table_load(&scene.sprite_table, SPRITE)    == false { return false }

    pax.grid_stack_push(&scene.sprite_grid, 1)
    pax.grid_stack_push(&scene.sprite_grid, 3)
    pax.grid_stack_push(&scene.sprite_grid, 4)

    pax.grid_stack_push(&scene.solid_grid, 0)
    pax.grid_stack_push(&scene.solid_grid, 2)
    pax.grid_stack_push(&scene.solid_grid, 4)

    player := pax.group_find(&scene.player_group, scene.player)

    player.visible.sprite = 9
    player.movement.speed = 128
    player.movement.state = .STILL
    player.camera         = &scene.camera

    layer := pax.grid_stack_find(&scene.solid_grid, 2)

    for value, index in layer.values {
        actor := pax.group_find(&scene.player_group, value)

        if actor == nil { continue }

        actor.movement.point = pax.cell_to_point(&scene.grid_table,
            pax.index_to_cell(&scene.grid_table, index))
    }

    return true
}

title_scene_start :: proc(scene: ^Title_Scene, stage: ^Game) -> bool
{
    scene.camera.zoom = f32(stage.scale)

    scene.window   = stage.window
    scene.renderer = stage.renderer

    pax.channel_init(&scene.keyboard_channel)

    pax.renderer_init(&scene.graphics, scene.renderer, &scene.camera, &scene.sprite_table, &scene.texture_table)

    pax.grid_table_init(&scene.grid_table, GRID_SIZE, TILE_SIZE)
    pax.texture_table_init(&scene.texture_table, scene.renderer)
    pax.sprite_table_init(&scene.sprite_table)

    pax.grid_stack_init(&scene.sprite_grid, &scene.grid_table)
    pax.grid_stack_init(&scene.solid_grid, &scene.grid_table)

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
            case { 0, -1}: player.visible.sprite = 9
            case { 1, -1}: player.visible.sprite = 10
            case { 1,  0}: player.visible.sprite = 11
            case { 1,  1}: player.visible.sprite = 12
            case { 0,  1}: player.visible.sprite = 13
            case {-1,  1}: player.visible.sprite = 14
            case {-1,  0}: player.visible.sprite = 15
            case {-1, -1}: player.visible.sprite = 16
        }

        angle = collider_test(&scene.solid_grid, player.movement.point, angle)

        if player.movement.state == .STILL {
            collider_move(&scene.solid_grid, player.movement.point, angle, 2)
        }

        movement_step(&player.movement, &scene.grid_table, angle, delta)

        player.visible.point = player.movement.point

        if player.camera != nil {
            player.camera.follow = player.movement.point
        }
    }
}

scene_sprite_layer_draw :: proc(scene: ^Title_Scene, index: int, cell: [2]int)
{
    value := pax.grid_stack_find(&scene.sprite_grid, index, cell)
    point := pax.cell_to_point(&scene.grid_table, cell)

    if value != nil {
        pax.renderer_draw_sprite(&scene.graphics, value^, point)
    }
}

scene_player_layer_draw :: proc(scene: ^Title_Scene, index: int, cell: [2]int)
{
    value := pax.grid_stack_find(&scene.sprite_grid, index, cell)

    if value != nil {
        entity := pax.group_find(&scene.player_group, value^)

        if entity != nil {
            pax.renderer_draw_sprite(&scene.graphics, entity.visible.sprite, entity.visible.point)
        }
    }
}

title_scene_draw :: proc(scene: ^Title_Scene, extra: f32)
{
    assert(sdl.RenderClear(scene.renderer) == 0,
        sdl.GetErrorString())

    corners := pax.camera_corners(&scene.camera, &scene.grid_table)

    for row in corners.z ..= corners.w {
        for col in corners.x ..= corners.y {
            scene_sprite_layer_draw(scene, 0, {col, row})
        }
    }

    for row in corners.z ..= corners.w {
        for col in corners.x ..= corners.y {
            scene_sprite_layer_draw(scene, 1, {col, row})
            scene_player_layer_draw(scene, 2, {col, row})
        }
    }

    sdl.RenderPresent(scene.renderer)
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
