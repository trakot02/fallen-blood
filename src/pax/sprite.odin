package pax

import "core:mem"
import "core:log"
import "core:encoding/json"
import "core:os"

Sprite_Frame :: struct
{
    rect:  [4]int,
    base:  [2]int,
    delay: f32,
}

Sprite_Chain :: struct
{
    frame:  int,
    delay:  f32,
    frames: []int,
    loop:   b8,
    stop:   b8,
}

Sprite :: struct
{
    image: int,
    frames: []Sprite_Frame,
    chains: []Sprite_Chain,
}

Sprite_Resource :: struct
{
    allocator: mem.Allocator,
}

sprite_clear :: proc(self: ^Sprite_Resource, value: ^Sprite)
{
    mem.free_all(self.allocator)
}

sprite_read :: proc(self: ^Sprite_Resource, name: string) -> (Sprite, bool)
{
    spec  := json.DEFAULT_SPECIFICATION
    alloc := context.temp_allocator
    value := Sprite {}

    bytes, state := os.read_entire_file_from_filename(name, alloc)

    if state == false {
        log.errorf("Unable to open %q for reading\n",
            name)

        return {}, false
    }

    error := json.unmarshal(bytes, &value, spec, self.allocator)

    mem.free_all(alloc)

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

    if error != nil { return {}, false }

    return value, true
}

sprite_resource :: proc(self: ^Sprite_Resource) -> Resource(Sprite)
{
    value := Resource(Sprite) {}

    value.instance = auto_cast self

    value.clear_proc = auto_cast sprite_clear
    value.read_proc  = auto_cast sprite_read

    return value
}
