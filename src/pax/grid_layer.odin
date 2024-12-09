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
        for field, col in record {
            temp, succ := strconv.parse_int(
                strings.trim(field, " \n\t\r\v\f"))

            if succ == false {
                fmt.printf("ERROR: Unable to parse '%v' inside %v:(%v, %v)\n",
                    field, col, row)

                temp = -1
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
