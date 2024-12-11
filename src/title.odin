package main

import "core:fmt"

import sdl  "vendor:sdl2"
import sdli "vendor:sdl2/image"

import "pax"

TITLE_GRID_1  :: "data/scene/title/grid_1/chunk.csv"
TITLE_GRID_2  :: "data/scene/title/grid_1/chunk.csv"
TITLE_TEXTURE :: "data/scene/title/table_texture.csv"
TITLE_SPRITE  :: "data/scene/title/table_sprite.csv"

TITLE_GRID_SIZE :: [2]int {24, 17}

Title_Scene :: struct
{
    camera: pax.Camera,

    window:   ^sdl.Window,
    renderer: ^sdl.Renderer,

    graphics: pax.Renderer,

    keyboard_channel: pax.Channel(sdl.KeyboardEvent),

    grid_1: pax.Grid_Chunk,

    sprite_table:  pax.Sprite_Table,
    texture_table: pax.Texture_Table,

    world: pax.World,

    player_group: pax.Group(Player),

    player: int,

    state: int,
}


title_player_keyboard :: proc(self: ^Title_Scene, event: sdl.KeyboardEvent) {
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
}

title_camera_keyboard :: proc(self: ^Title_Scene, event: sdl.KeyboardEvent) {
    if event.type == .KEYDOWN {
        #partial switch event.keysym.sym {
            case .P, .PLUS,  .KP_PLUS:  self.camera.zoom += 1
            case .M, .MINUS, .KP_MINUS: self.camera.zoom -= 1
        }
    }
}

title_scene_keyboard :: proc(self: ^Title_Scene, event: sdl.KeyboardEvent) {
    if event.type == .KEYUP {
        #partial switch event.keysym.sym {
            case .ESCAPE: self.state = -1

            case .R: {
                title_scene_unload(self)

                if title_scene_load(self) == false {
                    self.state = -1
                }
            }
        }
    }
}

title_scene_start :: proc(self: ^Title_Scene, stage: ^Game) -> bool
{
    self.camera.zoom = f32(stage.scale)

    self.window   = stage.window
    self.renderer = stage.renderer

    pax.channel_init(&self.keyboard_channel)
    pax.renderer_init(&self.graphics, self.renderer, &self.camera, &self.sprite_table, &self.texture_table)

    pax.grid_chunk_init(&self.grid_1, TITLE_GRID_SIZE, TILE_SIZE)
    pax.sprite_table_init(&self.sprite_table)
    pax.texture_table_init(&self.texture_table, self.renderer)

    pax.world_init(&self.world)
    pax.group_init(&self.player_group)

    self.player = pax.world_create_actor(&self.world)

    pax.group_insert(&self.player_group, self.player)

    pax.channel_connect(&self.keyboard_channel, auto_cast title_player_keyboard, self)
    pax.channel_connect(&self.keyboard_channel, auto_cast title_camera_keyboard, self)
    pax.channel_connect(&self.keyboard_channel, auto_cast title_scene_keyboard, self)

    if title_scene_load(self) == false { return false }

    sdl.ShowWindow(self.window)

    return true
}

title_scene_stop :: proc(self: ^Title_Scene)
{
    sdl.HideWindow(self.window)
}

title_scene_load :: proc(self: ^Title_Scene) -> bool
{
    self.camera.size     = WINDOW_SIZE
    self.camera.offset.x = WINDOW_SIZE.x / 2 - TILE_SIZE.x / 2
    self.camera.offset.y = WINDOW_SIZE.y / 2 - TILE_SIZE.y / 2

    if pax.grid_chunk_load(&self.grid_1, TITLE_GRID_1) == false {
        return false
    }

    if pax.sprite_table_load(&self.sprite_table, TITLE_SPRITE)    == false { return false }
    if pax.texture_table_load(&self.texture_table, TITLE_TEXTURE) == false { return false }

    player := pax.group_find(&self.player_group, self.player)

    player.visible.sprite = 13
    player.visible.point  = {32, 32}
    player.movement.point = {32, 32}
    player.movement.speed = 128
    player.movement.state = .STILL
    player.camera         = &self.camera

    layer := pax.grid_stack_find(&self.grid_1.stacks[0], 3)

    for value, index in layer.values {
        actor := pax.group_find(&self.player_group, value)

        if actor == nil { continue }

        point := pax.cell_to_point(&self.grid_1.table,
            pax.index_to_cell(&self.grid_1.table, index))

        actor.movement.point = {f32(point.x), f32(point.y)}
    }

    return true
}

title_scene_unload :: proc(self: ^Title_Scene)
{
    pax.sprite_table_unload(&self.sprite_table)
    pax.texture_table_unload(&self.texture_table)

    pax.grid_chunk_unload(&self.grid_1)
}

title_scene_enter :: proc(self: ^Title_Scene)
{
    // empty.
}

title_scene_leave :: proc(self: ^Title_Scene)
{
    // empty.
}

title_scene_input :: proc(self: ^Title_Scene) -> int
{
    event: sdl.Event

    for sdl.PollEvent(&event) {
        #partial switch event.type {
            case .KEYUP:   pax.channel_send(&self.keyboard_channel, event.key)
            case .KEYDOWN: pax.channel_send(&self.keyboard_channel, event.key)

            case .QUIT: self.state = -1
        }
    }

    return self.state
}

title_scene_step :: proc(self: ^Title_Scene, delta: f32)
{
    for index in 0 ..< self.player_group.count {
        player := &self.player_group.values[index]

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

        for index in 0 ..< len(self.grid_1.stacks[0].layers) {
            angle = movement_test(&player.movement, &self.grid_1.stacks[0], angle, index)
        }

        if movement_step(&player.movement, &self.grid_1.stacks[0], angle, delta) {
            movement_grid(&player.movement, &self.grid_1.stacks[0], angle, 3)
        }

        player.visible.point = {
            int(player.movement.point.x),
            int(player.movement.point.y),
        }

        if player.camera != nil {
            player.camera.follow = player.visible.point
        }
    }
}

title_sprite_layer_draw :: proc(self: ^Title_Scene, index: int, cell: [2]int)
{
    value := pax.grid_stack_find(&self.grid_1.stacks[1], index, cell)
    point := pax.cell_to_point(&self.grid_1.table, cell)

    if value != nil {
        pax.renderer_draw_sprite(&self.graphics, value^, point)
    }
}

title_player_layer_draw :: proc(self: ^Title_Scene, index: int, cell: [2]int)
{
    value := pax.grid_stack_find(&self.grid_1.stacks[1], index, cell)

    if value != nil {
        entity := pax.group_find(&self.player_group, value^)

        if entity != nil {
            pax.renderer_draw_sprite(&self.graphics, entity.visible.sprite, entity.visible.point)
        }
    }
}

title_scene_draw :: proc(self: ^Title_Scene, extra: f32)
{
    assert(sdl.RenderClear(self.renderer) == 0,
        sdl.GetErrorString())

    corners := pax.camera_corners(&self.camera, &self.grid_1.table)

    for row in corners.z ..= corners.w {
        for col in corners.x ..= corners.y {
            title_sprite_layer_draw(self, 0, {col, row})
            title_sprite_layer_draw(self, 1, {col, row})
        }
    }

    for row in corners.z ..= corners.w {
        for col in corners.x ..= corners.y {
            title_sprite_layer_draw(self, 2, {col, row})
            title_player_layer_draw(self, 3, {col, row})
        }
    }

    sdl.RenderPresent(self.renderer)
}

title_scene :: proc(title: ^Title_Scene) -> pax.Scene
{
    self := pax.Scene {}

    self.instance = auto_cast title

    self.proc_start = auto_cast title_scene_start
    self.proc_stop  = auto_cast title_scene_stop
    self.proc_enter = auto_cast title_scene_enter
    self.proc_leave = auto_cast title_scene_leave
    self.proc_input = auto_cast title_scene_input
    self.proc_step  = auto_cast title_scene_step
    self.proc_draw  = auto_cast title_scene_draw

    return self
}
