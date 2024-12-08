package pax

import sdl  "vendor:sdl2"
import sdli "vendor:sdl2/image"

import "core:strings"
import "core:mem"
import "core:fmt"

Texture :: struct
{
    renderer: ^sdl.Renderer,
    pointer:  ^sdl.Texture,
}

texture_init :: proc(self: ^Texture, renderer: ^sdl.Renderer)
{
    self.renderer = renderer
}

texture_destroy :: proc(self: ^Texture)
{

}

texture_load :: proc(self: ^Texture, name: string) -> bool
{
    if self == nil {
        fmt.printf("ERROR: Renderer is null\n")

        return false
    }

    cstr, error := strings.clone_to_cstring(name, context.temp_allocator)

    if error != nil {
        fmt.printf("ERROR: Couldn't clone string\n")

        return false
    }

    self.pointer = sdli.LoadTexture(self.renderer, cstr)

    mem.free_all(context.temp_allocator)

    if self.pointer == nil {
        fmt.printf("ERROR: Unable to load texture '%v'\n",
            sdl.GetErrorString())

        return false
    }

    return true
}

texture_unload :: proc(self: ^sdl.Renderer, value: ^Texture)
{
    sdl.DestroyTexture(auto_cast value.pointer)
}
