package pax

import "core:encoding/csv"
import "core:strings"
import "core:strconv"
import "core:os"
import "core:mem"
import "core:fmt"

Grid :: struct
{
    value: [dynamic]int,
    size:  [2]int,
    tile:  [2]int,
}

grid_create :: proc(self: rawptr)
{
    assert(self == nil)
}

grid_destroy :: proc(self: rawptr)
{
    assert(self == nil)
}

grid_load :: proc(self: rawptr, name: string) -> (Grid, bool)
{
    assert(self == nil)

    result := Grid {nil, {0, 0}, {0, 0}}

    value, error := os.open(name)

    if error != nil {
        fmt.printf("FATAL: Unable to open file '%v'\n",
            name)

        return result, false
    }

    defer os.close(value)

    reader := csv.Reader {}

    reader.reuse_record        = true
    reader.reuse_record_buffer = true

    csv.reader_init(&reader, os.stream_from_handle(value))

    defer csv.reader_destroy(&reader)

    for record, row in csv.iterator_next(&reader) {
        result.size.y = row + 1

        for field, col in record {
            if col > result.size.x { result.size.x = col + 1 }

            temp, succ := strconv.parse_int(
                strings.trim(field, " \n\t\r\v\f"))

            if succ == false {
                fmt.printf("ERROR: Unable to parse '%v' in file %v, record %v, %v\n",
                    field, col, row)

                temp = -1
            }

            append(&result.value, temp)
        }
    }

    return result, true
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

grid_to_point :: proc(self: ^Grid, cell: [2]int) -> [2]int
{
    return cell * self.tile
}

grid_from_point :: proc(self: ^Grid, point: [2]int) -> [2]int
{
    return point / self.tile
}

grid_index :: proc(self: ^Grid, cell: [2]int) -> int
{
    return cell.y * self.size.x + cell.x
}

grid_pair :: proc(self: ^Grid, index: int) -> [2]int
{
    return {index % self.size.x, index / self.size.x}
}

grid_find :: proc(self: ^Grid, cell: [2]int) -> ^int
{
    if cell.x < 0 || cell.x >= self.size.x { return nil }
    if cell.y < 0 || cell.y >= self.size.y { return nil }

    index := cell.y * self.size.x + cell.x

    return &self.value[index]
}

grid_show :: proc(self: ^Grid)
{
    for row in 0 ..< self.size.y {
        for col in 0 ..< self.size.x {
            index := grid_index(self, {col, row})
            value := self.value[index]

            fmt.printf("%3v ", value)
        }

        fmt.printf("\n")
    }

    fmt.printf("\n")
}
