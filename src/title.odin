package main

import sdl  "vendor:sdl2"
import sdli "vendor:sdl2/image"

import "core:fmt"

import "pax"

PLAYER_IDLE_DOWN_0 :: [4]int {64, 32, 16, 16}
PLAYER_POINT       :: [2]int {16, 16}
PLAYER_SPEED       :: 128

PALM_FRAME  :: [4]int {64,   0, 16, 32}
PALM_OFFSET :: [2]int { 0, -16}

TEXTURES :: [2]pax.Resource {
    {name = "characters", path = "data/scene/title/characters.png"},
    {name = "tileset",    path = "data/scene/title/tileset.png"},
}

GRIDS :: [3]pax.Resource {
    {name = "ground", path = "data/scene/title/ground.csv"},
    {name = "object", path = "data/scene/title/object.csv"},
    {name = "entity", path = "data/scene/title/entity.csv"},
}

Player :: struct
{
    using sprite: pax.Sprite,

    movement: Movement,
    controls: Controls,
    camera:   ^pax.Camera,
}

Obstacle :: struct
{
    using sprite: pax.Sprite,
}

Title_Scene :: struct
{
    camera: pax.Camera,

    window: ^sdl.Window,
    render: ^sdl.Renderer,

    txtr_registry: pax.Registry(pax.Texture),
    grid_registry: pax.Registry(pax.Grid),

    ground_layer: pax.Tile_Grid,
    object_layer: pax.Tile_Grid,
    entity_layer: pax.Actor_Grid,

    world: pax.World,

    player_group:   pax.Group(Player),
    obstacle_group: pax.Group(Obstacle),

    player: int,
    palm:   int,
}

title_scene_load :: proc(scene: ^Title_Scene) -> bool
{
    for resource in TEXTURES {
        state := pax.registry_load(&scene.txtr_registry, resource)

        if state == false {
            fmt.printf("FATAL: Couldn't load resource '%v', '%v'\n",
                resource.name, resource.path)

            return state
        }
    }

    for resource in GRIDS {
        state := pax.registry_load(&scene.grid_registry, resource)

        if state == false {
            fmt.printf("FATAL: Couldn't load resource '%v', '%v'\n",
                resource.name, resource.path)

            return state
        }
    }

    scene.ground_layer.texture   = pax.registry_find(&scene.txtr_registry, "tileset")^
    scene.ground_layer.grid      = pax.registry_find(&scene.grid_registry, "ground")^
    scene.ground_layer.grid.tile = TILE_SIZE

    scene.object_layer.texture   = pax.registry_find(&scene.txtr_registry, "tileset")^
    scene.object_layer.grid      = pax.registry_find(&scene.grid_registry, "object")^
    scene.object_layer.grid.tile = TILE_SIZE

    scene.entity_layer.grid      = pax.registry_find(&scene.grid_registry, "entity")^
    scene.entity_layer.grid.tile = TILE_SIZE

    player := pax.group_find(&scene.player_group, scene.player)

    player.movement.point = PLAYER_POINT
    player.movement.speed = PLAYER_SPEED
    player.movement.state = .STILL

    player.sprite.texture = pax.registry_find(&scene.txtr_registry, "characters")^
    player.sprite.frame   = PLAYER_IDLE_DOWN_0

    player.camera = &scene.camera

    palm := pax.group_find(&scene.obstacle_group, scene.palm)

    palm.texture = pax.registry_find(&scene.txtr_registry, "tileset")^
    palm.frame   = PALM_FRAME
    palm.offset  = PALM_OFFSET

    for value, index in scene.entity_layer.grid.value {
        actor := pax.group_find(&scene.player_group, value)

        if actor == nil { continue }

        actor.movement.point = pax.grid_to_point(&scene.entity_layer,
            pax.grid_pair(&scene.entity_layer, index))

        actor.sprite.pixel = actor.movement.point
    }

    for value, index in scene.entity_layer.grid.value {
        actor := pax.group_find(&scene.obstacle_group, value)

        if actor == nil { continue }

        actor.sprite.pixel = pax.grid_to_point(&scene.entity_layer,
            pax.grid_pair(&scene.entity_layer, index))
    }

    scene.camera.size   = WINDOW_SIZE / 2
    scene.camera.offset = WINDOW_SIZE / 2 - TILE_SIZE / 2

    return true
}

title_scene_start :: proc(scene: ^Title_Scene, stage: ^Game) -> bool
{
    scene.camera.scale = f32(stage.scale)

    scene.window = stage.window
    scene.render = stage.render

    scene.txtr_registry = pax.texture_registry(scene.render)
    scene.grid_registry = pax.grid_registry()

    pax.registry_create(&scene.txtr_registry)
    pax.registry_create(&scene.grid_registry)

    pax.world_create(&scene.world)
    pax.group_create(&scene.player_group)
    pax.group_create(&scene.obstacle_group)

    scene.player = pax.world_create_actor(&scene.world)
    scene.palm   = pax.world_create_actor(&scene.world)

    pax.group_insert(&scene.player_group, scene.player)
    pax.group_insert(&scene.obstacle_group, scene.palm)

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

                    case .P, .PLUS,  .KP_PLUS:  scene.camera.scale += 1
                    case .M, .MINUS, .KP_MINUS: scene.camera.scale -= 1
                }
            }

            case .QUIT: return false
        }
    }

    return true
}

title_scene_step :: proc(scene: ^Title_Scene, delta: f32)
{
    for index in 0 ..< scene.player_group.count {
        player := &scene.player_group.value[index]
        angle  := controls_angle(&player.controls)

        index := pax.grid_from_point(&scene.entity_layer.grid, player.sprite.frame.xy)

        switch angle {
            case { 0, -1}: index.x = 0
            case { 1, -1}: index.x = 1
            case { 1,  0}: index.x = 2
            case { 1,  1}: index.x = 3
            case { 0,  1}: index.x = 4
            case {-1,  1}: index.x = 5
            case {-1,  0}: index.x = 6
            case {-1, -1}: index.x = 7
        }

        player.sprite.frame.xy = pax.grid_to_point(&scene.entity_layer.grid, index)

        angle = collider_test(&scene.object_layer.grid, player.movement.point, angle)
        angle = collider_test(&scene.entity_layer.grid, player.movement.point, angle)

        if player.movement.state == .STILL {
            collider_move(&scene.entity_layer.grid, player.movement.point, angle)
        }

        movement_step(&player.movement, &scene.entity_layer.grid, angle, delta)

        player.sprite.pixel = player.movement.point

        if player.camera != nil {
            player.camera.follow = player.movement.point
        }
    }
}

title_scene_draw :: proc(scene: ^Title_Scene, extra: f32)
{
    assert(sdl.RenderClear(scene.render) == 0,
        sdl.GetErrorString())

    pax.tile_grid_draw(&scene.ground_layer, &scene.camera, scene.render)
    pax.tile_grid_draw(&scene.object_layer, &scene.camera, scene.render)
    pax.actor_grid_draw(&scene.entity_layer, &scene.camera, scene.render, &scene.player_group)
    pax.actor_grid_draw(&scene.entity_layer, &scene.camera, scene.render, &scene.obstacle_group)

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
