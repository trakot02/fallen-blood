package blood

import sdl  "vendor:sdl2"
import sdli "vendor:sdl2/image"

Sprite :: struct
{
    texture: ^sdl.Texture,
    frame:   sdl.Rect,
    point:   sdl.FRect,
}

sprite_load_texture :: proc(sprite: ^Sprite, render: ^sdl.Renderer, name: cstring)
{
    sdl.DestroyTexture(sprite.texture)

    sprite.texture = sdli.LoadTexture(render, name)

    assert(sprite.texture != nil, sdl.GetErrorString())
}

sprite_unload_texture :: proc(sprite: ^Sprite)
{
    sdl.DestroyTexture(sprite.texture)
}

sprite_move :: proc(sprite: ^Sprite, point: sdl.FPoint)
{
    sprite.point.x = point.x
    sprite.point.y = point.y
}

sprite_draw :: proc(sprite: ^Sprite, render: ^sdl.Renderer, scale: f32)
{
    rect := sdl.Rect {
        i32(sprite.point.x), i32(sprite.point.y),
        i32(sprite.point.w * scale),
        i32(sprite.point.h * scale),
    }

    assert(sdl.RenderCopy(render, sprite.texture, &sprite.frame, &rect) == 0,
        sdl.GetErrorString())
}
