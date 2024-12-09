package pax

import "core:strings"
import "core:strconv"
import "core:encoding/csv"
import "core:os"
import "core:fmt"

Grid_Table :: struct
{
    size:   [2]int,
    tile:   [2]int,
    layers: [dynamic]Grid_Layer,
}

grid_table_init :: proc(self: ^Grid_Table, size: [2]int, tile: [2]int, allocator := context.allocator)
{
    self.size   = size
    self.tile   = tile
    self.layers = make([dynamic]Grid_Layer, allocator)
}

grid_table_destroy :: proc(self: ^Grid_Table)
{
    #reverse for &layer in self.layers {
        grid_layer_unload(&layer)
    }

    delete(self.layers)
}

grid_table_load :: proc(self: ^Grid_Table, name: string) -> bool
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
        layer := Grid_Layer {}

        for &field, col in record {
            field = strings.trim(field, " \n\t\r\v\f")

            switch col {
                case 0: {
                    grid_layer_init(&layer)

                    if grid_layer_load(&layer, field) == false {
                        return false
                    }
                }

                case: return false
            }
        }

        _, error := append(&self.layers, layer)

        if error != nil {
            fmt.printf("FATAL: Unable to grow the stack\n")

            return false
        }
    }

    return true
}

grid_table_unload :: proc(self: ^Grid_Table)
{
    #reverse for &layer in self.layers {
        grid_layer_unload(&layer)
    }

    delete(self.layers)
}

grid_table_find :: proc(self: ^Grid_Table, index: int) -> ^Grid_Layer
{
    count := len(self.layers)

    if 0 <= index && index < count {
        return &self.layers[index]
    }

    return nil
}

cell_to_point :: proc(self: ^Grid_Table, cell: [2]int) -> [2]int
{
    return cell * self.tile
}

point_to_cell :: proc(self: ^Grid_Table, point: [2]int) -> [2]int
{
    return point / self.tile
}

cell_to_index :: proc(self: ^Grid_Table, cell: [2]int) -> int
{
    return cell.y * self.size.x + cell.x
}

index_to_cell :: proc(self: ^Grid_Table, index: int) -> [2]int
{
    return {index % self.size.x, index / self.size.x}
}
