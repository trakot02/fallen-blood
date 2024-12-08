package pax

import sdl  "vendor:sdl2"
import sdli "vendor:sdl2/image"

Renderer :: struct
{
    render: ^sdl.Renderer,

    textures: [dynamic]^sdl.Texture,
}

renderer_init :: proc(self: ^Renderer, render: ^sdl.Renderer, allocator := context.allocator)
{
    self.render = render

    self.textures = make([dynamic]^sdl.Texture, allocator)
}

renderer_destroy :: proc(self: ^Renderer)
{
    delete(self.textures)
}

renderer_push :: proc(self: ^Renderer, texture: ^sdl.Texture) -> int
{
    index, error := append(&self.textures, texture)

    if error != nil {
        return 0
    }

    return index + 1
}

renderer_clear :: proc(self: ^Renderer)
{
    clear(&self.textures)
}

renderer_find :: proc(self: ^Renderer, texture: int) -> ^sdl.Texture
{
    count := len(self.textures)
    index := texture - 1

    if 0 <= index && index < count {
        return self.textures[index]
    }

    return nil
}

renderer_draw_part :: proc(self: ^Renderer, texture: int, rect: [4]int, part: [4]int)
{
    count := len(self.textures)
    index := texture - 1

    src := sdl.Rect {
        i32(part.x), i32(part.y), i32(part.z), i32(part.w),
    }

    dst := sdl.Rect {
        i32(rect.x), i32(rect.y), i32(rect.z), i32(rect.w),
    }

    if 0 <= index && index < count {
        value := self.textures[index]

        assert(sdl.RenderCopy(self.render, value, &src, &dst) == 0,
            sdl.GetErrorString())
    }
}

renderer_draw_full :: proc(self: ^Renderer, texture: int, rect: [4]int)
{
    count := len(self.textures)
    index := texture - 1

    dst := sdl.Rect {
        i32(rect.x), i32(rect.y), i32(rect.z), i32(rect.w),
    }

    if 0 <= index && index < count {
        value := self.textures[index]

        assert(sdl.RenderCopy(self.render, value, nil, &dst) == 0,
            sdl.GetErrorString())
    }
}

renderer_draw_sprite :: proc(self: ^Renderer, sprite: Sprite, point: [2]int)
{
    count := len(self.textures)
    index := sprite.texture - 1

    src := sdl.Rect {
        i32(sprite.part.x), i32(sprite.part.y),
        i32(sprite.part.z), i32(sprite.part.w),
    }

    dst := sdl.Rect {
        i32(point.x),
        i32(point.y),
        i32(sprite.size.x),
        i32(sprite.size.y),
    }

    if 0 <= index && index < count {
        value := self.textures[index]

        assert(sdl.RenderCopy(self.render, value, &src, &dst) == 0,
            sdl.GetErrorString())
    }
}

renderer_draw :: proc {
    renderer_draw_part,
    renderer_draw_full,
    renderer_draw_sprite,
}
