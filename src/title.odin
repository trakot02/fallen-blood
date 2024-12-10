package main

import "core:fmt"

import sdl  "vendor:sdl2"
import sdli "vendor:sdl2/image"

import "pax"

TITLE_GRID    :: "data/scene/title/table_grid.csv"
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

    grid_table:    pax.Grid_Table,
    texture_table: pax.Texture_Table,
    sprite_table:  pax.Sprite_Table,

    sprite_grid:  pax.Grid_Stack,
    solid_grid:   pax.Grid_Stack,
    event_grid:   pax.Grid_Stack,

    world: pax.World,

    player_group: pax.Group(Player),

    player: int,

    loaded: bool,
    state:  int,

    grid_handlers: [1]pax.Handler(rawptr),
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

            case .C: self.state = 2
        }
    }
}

title_scene_change :: proc(self: ^Title_Scene, value: rawptr)
{
    self.state = 2
}

title_scene_collision :: proc(self: ^Title_Scene, event: pax.Grid_Swap_Event)
{
    if event.source == &self.solid_grid && event.layer == 3 {
        value := pax.grid_stack_find(event.source, event.layer, event.cell1)
        actor := pax.group_find(&self.player_group, value^)

        handler := pax.grid_stack_find(&self.event_grid, 0, event.cell2)

        if value^ == self.player && 0 <= handler^ && handler^ < len(self.grid_handlers) {
            pax.handler_call(&self.grid_handlers[handler^], nil)
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

    pax.grid_table_init(&self.grid_table, TITLE_GRID_SIZE, TILE_SIZE)
    pax.texture_table_init(&self.texture_table, self.renderer)
    pax.sprite_table_init(&self.sprite_table)

    pax.grid_stack_init(&self.sprite_grid, &self.grid_table)
    pax.grid_stack_init(&self.solid_grid, &self.grid_table)
    pax.grid_stack_init(&self.event_grid, &self.grid_table)

    pax.world_init(&self.world)
    pax.group_init(&self.player_group)

    self.player = pax.world_create_actor(&self.world)

    pax.group_insert(&self.player_group, self.player)

    pax.channel_connect(&self.keyboard_channel, auto_cast title_player_keyboard, self)
    pax.channel_connect(&self.keyboard_channel, auto_cast title_camera_keyboard, self)
    pax.channel_connect(&self.keyboard_channel, auto_cast title_scene_keyboard, self)

    pax.channel_connect(&self.solid_grid.swap, auto_cast title_scene_collision, self)

    self.grid_handlers[0] = pax.handler_init_pair(auto_cast title_scene_change, self)

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
    if self.loaded { return self.loaded }

    self.camera.size     = WINDOW_SIZE
    self.camera.offset.x = WINDOW_SIZE.x / 2 - TILE_SIZE.x / 2
    self.camera.offset.y = WINDOW_SIZE.y / 2 - TILE_SIZE.y / 2

    if pax.grid_table_load(&self.grid_table, TITLE_GRID)          == false { return false }
    if pax.texture_table_load(&self.texture_table, TITLE_TEXTURE) == false { return false }
    if pax.sprite_table_load(&self.sprite_table, TITLE_SPRITE)    == false { return false }

    if pax.grid_stack_push(&self.sprite_grid, 1) == false { return false }
    if pax.grid_stack_push(&self.sprite_grid, 3) == false { return false }
    if pax.grid_stack_push(&self.sprite_grid, 5) == false { return false }
    if pax.grid_stack_push(&self.sprite_grid, 6) == false { return false }

    if pax.grid_stack_push(&self.solid_grid, 0) == false { return false }
    if pax.grid_stack_push(&self.solid_grid, 2) == false { return false }
    if pax.grid_stack_push(&self.solid_grid, 4) == false { return false }
    if pax.grid_stack_push(&self.solid_grid, 6) == false { return false }

    if pax.grid_stack_push(&self.event_grid, 7) == false { return false }

    player := pax.group_find(&self.player_group, self.player)

    player.visible.sprite = 13
    player.movement.speed = 128
    player.movement.state = .STILL
    player.camera         = &self.camera

    layer := pax.grid_stack_find(&self.solid_grid, 3)

    for value, index in layer.values {
        actor := pax.group_find(&self.player_group, value)

        if actor == nil { continue }

        point := pax.cell_to_point(&self.grid_table,
            pax.index_to_cell(&self.grid_table, index))

        actor.movement.point = {f32(point.x), f32(point.y)}
    }

    self.loaded = true

    return true
}

title_scene_unload :: proc(self: ^Title_Scene)
{
    pax.grid_stack_clear(&self.solid_grid)
    pax.grid_stack_clear(&self.sprite_grid)

    pax.sprite_table_unload(&self.sprite_table)
    pax.texture_table_unload(&self.texture_table)
    pax.grid_table_unload(&self.grid_table)

    self.loaded = false
}

title_scene_enter :: proc(self: ^Title_Scene)
{
    self.state = 0
}

title_scene_leave :: proc(self: ^Title_Scene)
{

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

        for index in 0 ..< len(self.solid_grid.layers) {
            angle = movement_test(&player.movement, &self.solid_grid, angle, index)
        }

        if movement_step(&player.movement, &self.solid_grid, angle, delta) {
            movement_grid(&player.movement, &self.solid_grid, angle, 3)
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
    value := pax.grid_stack_find(&self.sprite_grid, index, cell)
    point := pax.cell_to_point(&self.grid_table, cell)

    if value != nil {
        pax.renderer_draw_sprite(&self.graphics, value^, point)
    }
}

title_player_layer_draw :: proc(self: ^Title_Scene, index: int, cell: [2]int)
{
    value := pax.grid_stack_find(&self.sprite_grid, index, cell)

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

    corners := pax.camera_corners(&self.camera, &self.grid_table)

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
