package pax

import "core:strings"
import "core:strconv"
import "core:encoding/csv"
import "core:os"
import "core:fmt"

Grid_Layer :: struct
{
    values: [dynamic]int,
}

grid_layer_init :: proc(self: ^Grid_Layer, allocator := context.allocator)
{
    self.values = make([dynamic]int, allocator)
}

grid_layer_destroy :: proc(self: ^Grid_Layer)
{
    delete(self.values)
}

grid_layer_load :: proc(self: ^Grid_Layer, name: string) -> bool
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
        for &field, col in record {
            field = strings.trim(field, " \n\t\r\v\f")

            temp, succ := strconv.parse_int(field)

            if succ == false {
                fmt.printf("FATAL: Unable to parse '%v' inside %v:(%v, %v)\n",
                    field, col, row)

                return false 
            }

            _, error := append(&self.values, temp)

            if error != nil {
                fmt.printf("FATAL: Unable to grow the layer\n")

                return false
            }
        }
    }

    return true
}

grid_layer_unload :: proc(self: ^Grid_Layer)
{
    delete(self.values)
}

grid_layer_find :: proc(self: ^Grid_Layer, index: int) -> ^int
{
    count := len(self.values)

    if 0 <= index && index < count {
        return &self.values[index]
    }

    return nil
}

grid_layer_swap :: proc(self: ^Grid_Layer, index: int, other: int)
{
    count := len(self.values)

    if index < 0 || index >= count { return }
    if other < 0 || other >= count { return }

    temp := self.values[index]

    self.values[index] = self.values[other]
    self.values[other] = temp
}
