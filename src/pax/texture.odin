package pax

import "core:strings"
import "core:mem"
import "core:fmt"

import sdl  "vendor:sdl2"
import sdli "vendor:sdl2/image"

Texture :: struct
{
    value: ^sdl.Texture,
    size:  [2]int,
}

texture_create :: proc(self: ^sdl.Renderer)
{
    // empty.
}

texture_destroy :: proc(self: ^sdl.Renderer)
{
    // empty.
}

texture_load :: proc(self: ^sdl.Renderer, name: string) -> (Texture, bool)
{
    result := Texture {nil, {0, 0}}

    if self == nil {
        fmt.printf("ERROR: Renderer is null\n")

        return result, false
    }

    cstr, error := strings.clone_to_cstring(name, context.temp_allocator)

    if error != nil {
        fmt.printf("ERROR: Couldn't clone string\n")

        return result, false
    }

    value := sdli.LoadTexture(self, cstr)

    mem.free_all(context.temp_allocator)

    if value == nil {
        fmt.printf("ERROR: %v\n", sdl.GetErrorString())

        return result, false
    }

    size := sdl.Point {}

    assert(sdl.QueryTexture(value, nil, nil, &size.x, &size.y) == 0,
        sdl.GetErrorString())

    result.value  = value
    result.size.x = int(size.x)
    result.size.y = int(size.y)

    return result, true
}

texture_unload :: proc(self: ^sdl.Renderer, value: ^sdl.Texture)
{
    sdl.DestroyTexture(value)
}

texture_registry :: proc(self: ^sdl.Renderer) -> Registry(Texture)
{
    registry := Registry(Texture) {}

    registry.instance = auto_cast self

    registry.proc_create  = auto_cast texture_create
    registry.proc_destroy = auto_cast texture_destroy
    registry.proc_load    = auto_cast texture_load
    registry.proc_unload  = auto_cast texture_unload

    return registry
}

texture_pair :: proc(self: ^Texture, index: int) -> [2]int
{
    return {index % self.size.x, index / self.size.x}
}
