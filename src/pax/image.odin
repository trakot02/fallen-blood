package pax

import "core:mem"
import "core:log"
import "core:strings"
import "core:encoding/json"
import "core:os"

import sdl  "vendor:sdl2"
import sdli "vendor:sdl2/image"

Image :: struct
{
    data: rawptr,
}

Image_Resource :: struct
{
    renderer: ^sdl.Renderer,
}

image_clear :: proc(self: ^Image_Resource, value: ^Image)
{
    sdl.DestroyTexture(auto_cast value.data)
}

image_read :: proc(self: ^Image_Resource, name: string) -> (Image, bool)
{
    alloc := context.temp_allocator
    value := Image {}

    clone, error := strings.clone_to_cstring(name, alloc)

    if error != nil {
        log.errorf("Unable to open %q for reading\n",
            name)

        return {}, false
    }

    value.data = sdli.LoadTexture(self.renderer, clone)

    mem.free_all(alloc)

    if value.data == nil {
        log.errorf("SDL: %v\n", sdl.GetErrorString())

        return {}, false
    }

    return value, true
}

image_resource :: proc(self: ^Image_Resource) -> Resource(Image)
{
    value := Resource(Image) {}

    value.instance = auto_cast self

    value.clear_proc = auto_cast image_clear
    value.read_proc  = auto_cast image_read

    return value
}
