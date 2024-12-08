package pax

import "core:strings"
import "core:strconv"
import "core:encoding/csv"
import "core:os"
import "core:fmt"

Sprite :: struct
{
    texture: int,
    part:   [4]int,
    size:   [2]int,
    origin: [2]int,
}

Sprite_Table :: struct
{
    sprites: [dynamic]Sprite,
}

sprite_table_init :: proc(self: ^Sprite_Table, allocator := context.allocator)
{
    self.sprites = make([dynamic]Sprite, allocator)
}

sprite_table_destroy :: proc(self: ^Sprite_Table)
{
    delete(self.sprites)
}

sprite_table_load :: proc(self: ^Sprite_Table, name: string) -> bool
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
        sprite := Sprite {}

        for &field, col in record {
            field = strings.trim(field, " \n\t\v\r\f")

            temp, succ := strconv.parse_int(
                strings.trim(field, " \n\t\v\r\f"))

            if succ == false {
                fmt.printf("FATAL: Unable to parse '%v' in file %v, record %v, %v\n",
                    field, col, row)

                return false
            }

            switch col {
                case 0: sprite.texture  = temp
                case 1: sprite.part.x   = temp
                case 2: sprite.part.y   = temp
                case 3: sprite.part.z   = temp
                case 4: sprite.part.w   = temp
                case 5: sprite.size.x   = temp
                case 6: sprite.size.y   = temp
                case 7: sprite.origin.x = temp
                case 8: sprite.origin.y = temp

                case: return false
            }
        }

        append(&self.sprites, sprite)
    }

    return true
}

sprite_table_unload :: proc(self: ^Sprite_Table)
{
    clear(&self.sprites)
}

sprite_table_find :: proc(self: ^Sprite_Table, index: int) -> ^Sprite
{
    count := len(self.sprites)
    index := index - 1

    if 0 <= index && index < count {
        return &self.sprites[index]
    }

    return nil
}
