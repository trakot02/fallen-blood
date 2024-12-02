package pax

import "core:strings"
import "core:mem"
import "core:fmt"

import sdl  "vendor:sdl2"
import sdli "vendor:sdl2/image"

Texture :: struct
{
    value: ^sdl.Texture,
}

texture_create :: proc(self: ^sdl.Renderer)
{
    // empty.
}

texture_destroy :: proc(self: ^sdl.Renderer)
{
    // empty.
}

texture_load :: proc(self: ^sdl.Renderer, name: string) -> (Texture, Load_Error)
{
    result := Texture {nil}

    if self == nil {
        fmt.printf("ERROR: Null renderer\n")

        return result, .SOME
    }

    cstr, error := strings.clone_to_cstring(name, context.temp_allocator)

    if error != nil {
        fmt.printf("ERROR: Couldn't clone string\n")

        return result, .SOME
    }

    value := sdli.LoadTexture(self, cstr)

    mem.free_all(context.temp_allocator)

    if value == nil {
        fmt.printf("ERROR: %v\n", sdl.GetErrorString())

        return result, .SOME
    }

    result.value = value

    return result, nil
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
