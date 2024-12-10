package pax

import sdl  "vendor:sdl2"
import sdli "vendor:sdl2/image"

Renderer :: struct
{
    pointer: ^sdl.Renderer,
    camera:  ^Camera,
    sprite:  ^Sprite_Table,
    texture: ^Texture_Table,
}

renderer_init :: proc(self: ^Renderer, renderer: ^sdl.Renderer, camera: ^Camera, sprite: ^Sprite_Table, texture: ^Texture_Table)
{
    self.pointer = renderer
    self.camera  = camera
    self.sprite  = sprite
    self.texture = texture
}

renderer_destroy :: proc(self: ^Renderer)
{

}

renderer_draw_part :: proc(self: ^Renderer, texture: int, rect: [4]f32, part: [4]f32)
{
    txtr := texture_table_find(self.texture, texture)

    if txtr == nil { return }

    move := [2]f32 {0, 0}
    zoom := [2]f32 {1, 1}

    if self.camera != nil {
        move = camera_move(self.camera)
        zoom = camera_zoom(self.camera)
    }

    dst := sdl.Rect {
        i32(zoom.x * f32(rect.x + move.x)),
        i32(zoom.y * f32(rect.y + move.y)),
        i32(zoom.x * f32(rect.z)),
        i32(zoom.y * f32(rect.w)),
    }

    src := sdl.Rect {
        i32(part.x), i32(part.y), i32(part.z), i32(part.w),
    }

    assert(sdl.RenderCopy(self.pointer, txtr.pointer, &src, &dst) == 0,
        sdl.GetErrorString())
}

renderer_draw_full :: proc(self: ^Renderer, texture: int, rect: [4]f32)
{
    txtr := texture_table_find(self.texture, texture)

    if txtr == nil { return }

    move := [2]f32 {0, 0}
    zoom := [2]f32 {1, 1}

    if self.camera != nil {
        move = camera_move(self.camera)
        zoom = camera_zoom(self.camera)
    }

    dst := sdl.Rect {
        i32(zoom.x * f32(rect.x + move.x)),
        i32(zoom.y * f32(rect.y + move.y)),
        i32(zoom.x * f32(rect.z)),
        i32(zoom.y * f32(rect.w)),
    }

    assert(sdl.RenderCopy(self.pointer, txtr.pointer, nil, &dst) == 0,
        sdl.GetErrorString())
}

renderer_draw_sprite :: proc(self: ^Renderer, sprite: int, point: [2]f32)
{
    sprt := sprite_table_find(self.sprite, sprite)

    if sprt == nil { return }

    txtr := texture_table_find(self.texture, sprt.texture)

    if txtr == nil { return }

    move := [2]f32 {0, 0}
    zoom := [2]f32 {1, 1}

    if self.camera != nil {
        move = camera_move(self.camera)
        zoom = camera_zoom(self.camera)
    }

    move.x -= f32(sprt.origin.x)
    move.y -= f32(sprt.origin.y)

    dst := sdl.Rect {
        i32(zoom.x * f32(point.x + move.x)),
        i32(zoom.y * f32(point.y + move.y)),
        i32(zoom.x * f32(sprt.size.x)),
        i32(zoom.y * f32(sprt.size.y)),
    }

    src := sdl.Rect {
        i32(sprt.part.x), i32(sprt.part.y),
        i32(sprt.part.z), i32(sprt.part.w),
    }

    assert(sdl.RenderCopy(self.pointer, txtr.pointer, &src, &dst) == 0,
        sdl.GetErrorString())
}

renderer_draw :: proc {
    renderer_draw_part,
    renderer_draw_full,
    renderer_draw_sprite,
}
