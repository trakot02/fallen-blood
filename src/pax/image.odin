package pax

import "core:mem"
import "core:log"
import "core:os"
import "core:encoding/json"
import "core:strings"

import sdl  "vendor:sdl2"
import sdli "vendor:sdl2/image"

Image :: struct
{
    data: ^sdl.Texture,
}

Image_Frame :: struct
{
    rect: [4]int,
    base: [2]int,
}

Image_Sheet :: struct
{
    image:  int,
    frames: []Image_Frame,
}

Sprite :: struct
{
    sheet: int,
    frame: int,
    point: [2]int,
    scale: [2]f32,
}

Image_Reader :: struct
{
    renderer: ^sdl.Renderer,
}

image_read :: proc(self: ^Image_Reader, name: string) -> (Image, bool)
{
    temp  := context.temp_allocator
    value := Image {}

    cstr, error := strings.clone_to_cstring(name, temp)

    if error != nil {
        log.errorf("Unable to open %q for reading\n",
            name)

        return {}, false
    }

    value.data = sdli.LoadTexture(self.renderer, cstr)

    mem.free_all(temp)

    if value.data == nil {
        log.errorf("SDL: %v", sdl.GetErrorString())

        return {}, false
    }

    return value, true
}

image_clear :: proc(self: ^Image_Reader, value: ^Image)
{
    sdl.DestroyTexture(value.data)
}

Image_Sheet_Reader :: struct
{
    allocator: mem.Allocator,
}

image_sheet_read :: proc(self: ^Image_Sheet_Reader, name: string) -> (Image_Sheet, bool)
{
    spec  := json.DEFAULT_SPECIFICATION
    temp  := context.temp_allocator
    value := Image_Sheet {}

    data, succ := os.read_entire_file_from_filename(name, temp)

    if succ == false {
        log.errorf("Unable to open %q for reading\n",
            name)

        return {}, false
    }

    error := json.unmarshal(data, &value, spec, self.allocator)

    mem.free_all(temp)


    switch type in error {
        case json.Error: log.errorf("Unable to parse JSON\n")

        case json.Unmarshal_Data_Error: {
            log.errorf("Unable to unmarshal JSON:")

            switch type {
                case .Invalid_Data:          log.errorf("Invalid data\n")
                case .Invalid_Parameter:     log.errorf("Invalid parameter\n")
                case .Multiple_Use_Field:    log.errorf("Multiple use field\n")
                case .Non_Pointer_Parameter: log.errorf("Non pointer parameter\n")
                case:                        log.errorf("\n")
            }
        }

        case json.Unsupported_Type_Error: {
            log.errorf("Unable to parse JSON: Unsupported type\n")
        }
    }

    if error != nil {
        return {}, false
    }

    return value, true
}

image_sheet_clear :: proc(self: ^Image_Sheet_Reader, value: ^Image_Sheet)
{
    mem.free_all(self.allocator)
}
