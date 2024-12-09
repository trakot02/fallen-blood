package pax

import "core:strings"
import "core:strconv"
import "core:encoding/csv"
import "core:os"
import "core:mem"
import "core:fmt"

import sdl  "vendor:sdl2"
import sdli "vendor:sdl2/image"

Texture :: struct
{
    pointer: ^sdl.Texture,
}

Texture_Table :: struct
{
    renderer: ^sdl.Renderer,
    textures: [dynamic]Texture,
}

texture_table_init :: proc(self: ^Texture_Table, renderer: ^sdl.Renderer, allocator := context.allocator)
{
    self.renderer = renderer
    self.textures = make([dynamic]Texture, allocator)
}

texture_table_destroy :: proc(self: ^Texture_Table)
{
    for texture in self.textures {
        sdl.DestroyTexture(texture.pointer)
    }

    delete(self.textures)
}

texture_table_load :: proc(self: ^Texture_Table, name: string) -> bool
{
    value, error := os.open(name)

    if error != nil {
        fmt.printf("FATAL: Unable to open file '%v'\n",
            name)

        return false
    }

    defer os.close(value)

    reader := csv.Reader {}

    reader.reuse_record        = true
    reader.reuse_record_buffer = true

    csv.reader_init(&reader, os.stream_from_handle(value))

    defer csv.reader_destroy(&reader)

    for record, row in csv.iterator_next(&reader) {
        texture := Texture {}

        for &field, col in record {
            field = strings.trim(field, " \n\t\r\v\f")

            switch col {
                case 0: {
                    cstr, error := strings.clone_to_cstring(field,
                        context.temp_allocator)

                    if error != nil {
                        fmt.printf("FATAL: Couldn't clone string\n")

                        return false
                    }

                    texture.pointer = sdli.LoadTexture(self.renderer, cstr)

                    mem.free_all(context.temp_allocator)

                    if texture.pointer == nil {
                        fmt.printf("FATAL: Unable to load texture '%v'\n",
                            sdl.GetErrorString())

                        return false
                    }
                }

                case: return false
            }
        }

        _, error := append(&self.textures, texture)

        if error != nil {
            fmt.printf("FATAL: Unable to grow the array\n")

            return false
        }
    }

    return true
}

texture_table_unload :: proc(self: ^Texture_Table)
{
    for texture in self.textures {
        sdl.DestroyTexture(texture.pointer)
    }

    clear(&self.textures)
}

texture_table_find :: proc(self: ^Texture_Table, index: int) -> ^Texture
{
    count := len(self.textures)

    if 0 <= index && index < count {
        return &self.textures[index]
    }

    return nil
}
