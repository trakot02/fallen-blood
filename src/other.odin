package main

import "core:fmt"

import sdl  "vendor:sdl2"
import sdli "vendor:sdl2/image"

import "pax"

OTHER_GRID    :: "data/scene/other/table_grid.csv"
OTHER_TEXTURE :: "data/scene/other/table_texture.csv"
OTHER_SPRITE  :: "data/scene/other/table_sprite.csv"

OTHER_GRID_SIZE :: [2]int {24, 17}

Other_Scene :: struct
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

    loaded: bool,
    state:  int,
}

other_player_keyboard :: proc(self: ^Other_Scene, event: sdl.KeyboardEvent) -> int {
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

    return self.state
}

other_camera_keyboard :: proc(self: ^Other_Scene, event: sdl.KeyboardEvent) -> int {
    if event.type == .KEYDOWN {
        #partial switch event.keysym.sym {
            case .P, .PLUS,  .KP_PLUS:  self.camera.zoom += 1
            case .M, .MINUS, .KP_MINUS: self.camera.zoom -= 1
        }
    }

    return self.state
}

other_scene_keyboard :: proc(self: ^Other_Scene, event: sdl.KeyboardEvent) -> int {
    if event.type == .KEYUP {
        #partial switch event.keysym.sym {
            case .ESCAPE: self.state = -1

            case .R: {
                other_scene_unload(self)

                if other_scene_load(self) == false {
                    self.state = -1
                }
            }

            case .C: self.state = 1
        }
    }

    return self.state
}

other_scene_start :: proc(self: ^Other_Scene, stage: ^Game) -> bool
{
    self.camera.zoom = f32(stage.scale)

    self.window   = stage.window
    self.renderer = stage.renderer

    pax.channel_init(&self.keyboard_channel)

    pax.renderer_init(&self.graphics, self.renderer, &self.camera, &self.sprite_table, &self.texture_table)

    pax.grid_table_init(&self.grid_table, OTHER_GRID_SIZE, TILE_SIZE)
    pax.texture_table_init(&self.texture_table, self.renderer)
    pax.sprite_table_init(&self.sprite_table)

    pax.grid_stack_init(&self.sprite_grid, &self.grid_table)
    pax.grid_stack_init(&self.solid_grid, &self.grid_table)

    pax.world_init(&self.world)
    pax.group_init(&self.player_group)

    self.player = pax.world_create_actor(&self.world)

    pax.group_insert(&self.player_group, self.player)

    pax.channel_connect(&self.keyboard_channel, auto_cast other_player_keyboard, self)
    pax.channel_connect(&self.keyboard_channel, auto_cast other_camera_keyboard, self)
    pax.channel_connect(&self.keyboard_channel, auto_cast other_scene_keyboard, self)

    if other_scene_load(self) == false { return false }

    sdl.ShowWindow(self.window)

    return true
}

other_scene_stop :: proc(self: ^Other_Scene)
{
    sdl.HideWindow(self.window)
}

other_scene_load :: proc(self: ^Other_Scene) -> bool
{
    if self.loaded { return self.loaded }

    self.camera.size     = WINDOW_SIZE
    self.camera.offset.x = f32(WINDOW_SIZE.x) / 2 - f32(TILE_SIZE.x) / 2
    self.camera.offset.y = f32(WINDOW_SIZE.y) / 2 - f32(TILE_SIZE.y) / 2

    if pax.grid_table_load(&self.grid_table, OTHER_GRID)          == false { return false }
    if pax.texture_table_load(&self.texture_table, OTHER_TEXTURE) == false { return false }
    if pax.sprite_table_load(&self.sprite_table, OTHER_SPRITE)    == false { return false }

    if pax.grid_stack_push(&self.sprite_grid, 1) == false { return false }
    if pax.grid_stack_push(&self.sprite_grid, 3) == false { return false }
    if pax.grid_stack_push(&self.sprite_grid, 5) == false { return false }
    if pax.grid_stack_push(&self.sprite_grid, 6) == false { return false }

    if pax.grid_stack_push(&self.solid_grid, 0) == false { return false }
    if pax.grid_stack_push(&self.solid_grid, 2) == false { return false }
    if pax.grid_stack_push(&self.solid_grid, 4) == false { return false }
    if pax.grid_stack_push(&self.solid_grid, 6) == false { return false }

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

other_scene_unload :: proc(self: ^Other_Scene)
{
    pax.grid_stack_clear(&self.solid_grid)
    pax.grid_stack_clear(&self.sprite_grid)

    pax.sprite_table_unload(&self.sprite_table)
    pax.texture_table_unload(&self.texture_table)
    pax.grid_table_unload(&self.grid_table)

    self.loaded = false
}

other_scene_enter :: proc(self: ^Other_Scene)
{
    self.state = 0
}

other_scene_leave :: proc(self: ^Other_Scene)
{

}

other_scene_input :: proc(self: ^Other_Scene) -> int
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

other_scene_step :: proc(self: ^Other_Scene, delta: f32)
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
            angle = collider_test(&self.solid_grid, player.movement.point, angle, index)
        }

        if player.movement.state == .STILL {
            collider_move(&self.solid_grid, player.movement.point, angle, 3)
        }

        movement_step(&player.movement, &self.grid_table, angle, delta)

        player.visible.point = player.movement.point

        if player.camera != nil {
            player.camera.follow = player.movement.point
        }
    }
}

other_sprite_layer_draw :: proc(self: ^Other_Scene, index: int, cell: [2]int)
{
    value := pax.grid_stack_find(&self.sprite_grid, index, cell)
    point := pax.cell_to_point(&self.grid_table, cell)

    if value != nil {
        pax.renderer_draw_sprite(&self.graphics, value^, {
            f32(point.x), f32(point.y)
        })
    }
}

other_player_layer_draw :: proc(self: ^Other_Scene, index: int, cell: [2]int)
{
    value := pax.grid_stack_find(&self.sprite_grid, index, cell)

    if value != nil {
        entity := pax.group_find(&self.player_group, value^)

        if entity != nil {
            pax.renderer_draw_sprite(&self.graphics, entity.visible.sprite, entity.visible.point)
        }
    }
}

other_scene_draw :: proc(self: ^Other_Scene, extra: f32)
{
    assert(sdl.RenderClear(self.renderer) == 0,
        sdl.GetErrorString())

    corners := pax.camera_corners(&self.camera, &self.grid_table)

    for row in corners.z ..= corners.w {
        for col in corners.x ..= corners.y {
            other_sprite_layer_draw(self, 0, {col, row})
            other_sprite_layer_draw(self, 1, {col, row})
        }
    }

    for row in corners.z ..= corners.w {
        for col in corners.x ..= corners.y {
            other_sprite_layer_draw(self, 2, {col, row})
            other_player_layer_draw(self, 3, {col, row})
        }
    }

    sdl.RenderPresent(self.renderer)
}

other_scene :: proc(other: ^Other_Scene) -> pax.Scene
{
    self := pax.Scene {}

    self.instance = auto_cast other

    self.proc_start = auto_cast other_scene_start
    self.proc_stop  = auto_cast other_scene_stop
    self.proc_enter = auto_cast other_scene_enter
    self.proc_leave = auto_cast other_scene_leave
    self.proc_input = auto_cast other_scene_input
    self.proc_step  = auto_cast other_scene_step
    self.proc_draw  = auto_cast other_scene_draw

    return self
}
