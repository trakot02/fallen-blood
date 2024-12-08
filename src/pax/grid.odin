package pax

import "core:strings"
import "core:strconv"
import "core:encoding/csv"
import "core:os"
import "core:fmt"

Grid :: struct
{
    value: [dynamic]int,
    size:  [2]int,
    tile:  [2]int,
}

grid_init :: proc(self: ^Grid, tile: [2]int, allocator := context.allocator)
{
    self.tile  = tile
    self.value = make([dynamic]int, allocator)
}

grid_destroy :: proc(self: ^Grid)
{
    delete(self.value)
}

grid_load :: proc(self: ^Grid, name: string) -> bool
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
        self.size.y = row + 1

        for field, col in record {
            if col > self.size.x { self.size.x = col + 1 }

            temp, succ := strconv.parse_int(
                strings.trim(field, " \n\t\r\v\f"))

            if succ == false {
                fmt.printf("ERROR: Unable to parse '%v' in file %v, record %v, %v\n",
                    field, col, row)

                temp = -1
            }

            append(&self.value, temp)
        }
    }

    return true
}

grid_unload :: proc(self: ^Grid)
{
    delete(self.value)
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
