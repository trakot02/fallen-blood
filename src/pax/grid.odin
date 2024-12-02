package pax

import "core:encoding/csv"
import "core:strings"
import "core:strconv"
import "core:os"
import "core:mem"
import "core:fmt"

Grid :: struct
{
    value: [dynamic]i32,
    size:  [2]i32,
}

grid_create :: proc(self: rawptr)
{
    assert(self == nil)

    // empty.
}

grid_destroy :: proc(self: rawptr)
{
    assert(self == nil)

    // empty.
}

grid_load :: proc(self: rawptr, name: string) -> (Grid, Load_Error)
{
    assert(self == nil)

    result := Grid {nil, {0, 0}}

    file, error := os.open(name)

    if error != nil {
        fmt.printf("FATAL: Unable to open file '%v'\n",
            name)

        return result, .SOME
    }

    defer os.close(file)

    reader := csv.Reader {}

    reader.reuse_record        = true
    reader.reuse_record_buffer = true

    csv.reader_init(&reader, os.stream_from_handle(file))

    defer csv.reader_destroy(&reader)

    for record, row in csv.iterator_next(&reader) {
        result.size.y = i32(row + 1)

        for field, col in record {
            if i32(col) > result.size.x {
                result.size.x = i32(col + 1)
            }

            temp, succ := strconv.parse_int(
                strings.trim(field, " \n\t\r\v\f"))

            if succ == false {
                fmt.printf("ERROR: Unable to parse '%v' in file = %v, record = %v, %v\n",
                    field, col, row)

                temp = -1
            }

            append(&result.value, i32(temp))
        }
    }

    return result, nil
}

grid_unload :: proc(self: rawptr, value: ^Grid)
{
    assert(self == nil)

    delete(value.value)
}

grid_registry :: proc() -> Registry(Grid)
{
    registry := Registry(Grid) {}

    registry.proc_create  = auto_cast grid_create
    registry.proc_destroy = auto_cast grid_destroy
    registry.proc_load    = auto_cast grid_load
    registry.proc_unload  = auto_cast grid_unload

    return registry
}
