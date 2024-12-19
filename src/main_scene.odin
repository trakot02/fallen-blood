package main

import "core:log"

import sdl  "vendor:sdl2"
import sdli "vendor:sdl2/image"

import "pax"

WINDOW_SIZE :: [2]int {320, 180}

Main_Scene :: struct
{
    window:   pax.Window,
    renderer: pax.Renderer,
    camera:   pax.Camera,

    render_state: Render_State,

    image:  pax.Image_Resource,
    images: pax.Registry(pax.Image),

    sprite:  pax.Sprite_Resource,
    sprites: pax.Registry(pax.Sprite),

    grid:  pax.Grid_Resource,
    grids: pax.Registry(pax.Grid),

    keyboard: pax.Keyboard,

    world:        pax.World,
    player_group: pax.Group(Player),

    state:  int,
    player: int,
}

main_scene_camera_on_key_press :: proc(event: sdl.KeyboardEvent, self: ^pax.Camera)
{
    #partial switch event.keysym.sym {
        case .P, .PLUS,  .KP_PLUS:  self.scale += 1
        case .M, .MINUS, .KP_MINUS: self.scale -= 1
    }
}

main_scene_player_on_key_release :: proc(event: sdl.KeyboardEvent, self: ^Player)
{
    #partial switch event.keysym.sym {
        case .D, .RIGHT: self.controls.east  = false
        case .W, .UP:    self.controls.north = false
        case .A, .LEFT:  self.controls.west  = false
        case .S, .DOWN:  self.controls.south = false
    }
}

main_scene_player_on_key_press :: proc(event: sdl.KeyboardEvent, self: ^Player)
{
    #partial switch event.keysym.sym {
        case .D, .RIGHT: self.controls.east  = true
        case .W, .UP:    self.controls.north = true
        case .A, .LEFT:  self.controls.west  = true
        case .S, .DOWN:  self.controls.south = true
    }
}

main_scene_on_key_release :: proc(event: sdl.KeyboardEvent, self: ^Main_Scene)
{
    #partial switch event.keysym.sym {
        case .ESCAPE: self.state = -1

        case .R: {
            main_scene_unload(self)

            if main_scene_load(self) == false {
                self.state = -1
            }
        }
    }

    pax.window_set_size(&self.window, [2]int {
        int(f32(WINDOW_SIZE.x) * self.camera.scale.x),
        int(f32(WINDOW_SIZE.y) * self.camera.scale.y),
    })
}

main_scene_on_close :: proc(self: ^Main_Scene)
{
    self.state = -1
}

main_scene_start :: proc(self: ^Main_Scene, stage: ^Game_Stage) -> bool
{
    self.window   = stage.window
    self.renderer = stage.renderer

    self.render_state.renderer = &self.renderer
    self.render_state.camera   = &self.camera
    self.render_state.images   = &self.images
    self.render_state.sprites  = &self.sprites

    self.image.renderer   = auto_cast self.renderer.data
    self.sprite.allocator = context.allocator
    self.grid.allocator   = context.allocator

    pax.registry_init(&self.images,  pax.image_resource(&self.image))
    pax.registry_init(&self.sprites, pax.sprite_resource(&self.sprite))
    pax.registry_init(&self.grids,   pax.grid_resource(&self.grid))

    pax.keyboard_init(&self.keyboard)

    pax.world_init(&self.world)
    pax.group_init(&self.player_group)

    self.player = pax.world_create_actor(&self.world)

    if self.player <= 0 { return false }

    pax.signal_insert(&self.keyboard.press,   &self.camera, main_scene_camera_on_key_press)

    pax.signal_insert(&self.keyboard.release, self, main_scene_on_key_release)
    pax.signal_insert(&self.window.close,     self, main_scene_on_close)

    if main_scene_load(self) == false { return false }

    pax.window_show(&self.window)

    return true
}

main_scene_stop :: proc(self: ^Main_Scene)
{
    pax.window_hide(&self.window)

    main_scene_unload(self)
}

main_scene_load :: proc(self: ^Main_Scene) -> bool
{
    if pax.registry_read(&self.images, []string {
        "data/main_scene/image/tiles.png",
        "data/main_scene/image/chars.png",
    }) == false { return false }

    if pax.registry_read(&self.sprites, []string {
        "data/main_scene/sprite/tiles.json",
        "data/main_scene/sprite/chars.json",
    }) == false { return false }

    if pax.registry_read(&self.grids, []string {
        "data/main_scene/grid/grid1.json",
        "data/main_scene/grid/grid2.json",
    }) == false { return false }

    player := pax.group_insert(&self.player_group, self.player)

    if player == nil { return false }

    pax.signal_insert(&self.keyboard.release, player, main_scene_player_on_key_release)
    pax.signal_insert(&self.keyboard.press,   player, main_scene_player_on_key_press)

    player.animation.sprite = 2
    player.animation.chain  = 5

    player.transform.point = {32, 32}
    player.transform.scale = { 1,  1}

    player.movement.point = {32, 32}
    player.movement.speed = 128
    player.movement.grid  = 1

    player.camera = &self.camera

    grid := pax.registry_find(&self.grids, player.movement.grid)

    value := pax.grid_find(grid, 1, 4,
        pax.point_to_cell(grid, player.transform.point))

    if value == nil { return false }

    value^ = self.player

    self.camera.size   = WINDOW_SIZE
    self.camera.offset = WINDOW_SIZE / 2 - grid.tile / 2
    self.camera.scale  = {3, 3}

    pax.window_set_title(&self.window, "xyz")

    pax.window_set_size(&self.window, [2]int {
        int(f32(WINDOW_SIZE.x) * self.camera.scale.x),
        int(f32(WINDOW_SIZE.y) * self.camera.scale.y),
    })

    return true
}

main_scene_unload :: proc(self: ^Main_Scene)
{
    pax.registry_clear(&self.grids)
    pax.registry_clear(&self.sprites)
    pax.registry_clear(&self.images)

    pax.group_clear(&self.player_group)
}

main_scene_enter :: proc(self: ^Main_Scene)
{
    // empty.
}

main_scene_leave :: proc(self: ^Main_Scene)
{
    // empty.
}

main_scene_input :: proc(self: ^Main_Scene, event: sdl.Event) -> int
{
    pax.keyboard_emit(&self.keyboard, event)
    pax.window_emit(&self.window, event)

    return self.state
}

main_scene_step :: proc(self: ^Main_Scene, delta: f32)
{
    for index in 0 ..< self.player_group.count {
        player := &self.player_group.values[index]

        angle := controls_angle(&player.controls)
        chain := 5

        switch angle {
            case { 0, -1}: chain = 0
            case { 1, -1}: chain = 1
            case { 1,  0}: chain = 2
            case { 1,  1}: chain = 3
            case { 0,  1}: chain = 4
            case {-1,  1}: chain = 5
            case {-1,  0}: chain = 6
            case {-1, -1}: chain = 7
        }

        grid := pax.registry_find(&self.grids, player.movement.grid)

        if grid == nil { continue }

        for layer in 1 ..= len(grid.stacks[0]) {
            angle = movement_test_collision(&player.movement, &self.grids, angle, 1, layer)
        }

        if player.movement.state == .STILL {
            gate := movement_test_gate(&player.movement, &self.grids, 3, 1)

            if gate != nil {
                movement_grid_change(&player.movement, &self.grids, 1, 4, gate^)
            }
        }

        movement_grid_next(&player.movement, &self.grids, angle, 1, 4)
        movement_step(&player.movement, &self.grids, angle, delta)

        player.transform.point = {
            int(player.movement.point.x),
            int(player.movement.point.y),
        }

        if player.camera != nil {
            player.camera.follow = player.transform.point
        }
    }
}

main_scene_draw_sprite_layer :: proc(self: ^Main_Scene, layer: int, cell: [2]int)
{
    grid := pax.registry_find(&self.grids,
        pax.group_find(&self.player_group, self.player).movement.grid)

    value := pax.grid_find(grid, 2, layer, cell)
    point := pax.cell_to_point(grid, cell)

    if value == nil { return }

    animat := Animation {
        sprite = 1,
        chain  = value^,
    }

    transf := Transform {
        point = point,
        scale = {1, 1},
    }

    render_state_draw_sprite(&self.render_state, animat, transf)
}

main_scene_draw_player_layer :: proc(self: ^Main_Scene, layer: int, cell: [2]int)
{
    grid := pax.registry_find(&self.grids,
        pax.group_find(&self.player_group, self.player).movement.grid)

    value := pax.grid_find_value(grid, 2, layer, cell)
    point := pax.cell_to_point(grid, cell)

    if value == nil { return }

    player := pax.group_find(&self.player_group, value^)

    if player != nil {
        render_state_draw_sprite(&self.render_state, player.animation, player.transform)
    }
}

main_scene_draw :: proc(self: ^Main_Scene)
{
    grid := pax.registry_find(&self.grids,
        pax.group_find(&self.player_group, self.player).movement.grid)

    pax.renderer_clear(&self.renderer)

    area := pax.camera_grid_area(&self.camera, grid)

    for row in area.y ..= area.w {
        for col in area.x ..= area.z {
            main_scene_draw_sprite_layer(self, 1, {col, row})
            main_scene_draw_sprite_layer(self, 2, {col, row})
        }
    }

    for row in area.y ..= area.w {
        for col in area.x ..= area.z {
            main_scene_draw_sprite_layer(self, 3, {col, row})
            main_scene_draw_player_layer(self, 4, {col, row})
        }
    }

    pax.renderer_apply(&self.renderer)
}

main_scene :: proc(self: ^Main_Scene) -> pax.Scene
{
    value := pax.Scene {}

    value.instance = auto_cast self

    value.proc_start = auto_cast main_scene_start
    value.proc_stop  = auto_cast main_scene_stop
    value.proc_enter = auto_cast main_scene_enter
    value.proc_leave = auto_cast main_scene_leave
    value.proc_input = auto_cast main_scene_input
    value.proc_step  = auto_cast main_scene_step
    value.proc_draw  = auto_cast main_scene_draw

    return value
}
