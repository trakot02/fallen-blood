package pax

import "core:strings"
import "core:strconv"
import "core:encoding/csv"
import "core:os"
import "core:fmt"

Grid_Stack :: struct
{
    table:  ^Grid_Table,
    layers: [dynamic]^Grid_Layer,
}

Grid_Item :: struct {
    cell:  [2]int,
    index: int,
    value: int,
}

grid_stack_init :: proc(self: ^Grid_Stack, table: ^Grid_Table, allocator := context.allocator)
{
    self.table  = table
    self.layers = make([dynamic]^Grid_Layer, allocator)
}

grid_stack_destroy :: proc(self: ^Grid_Stack)
{
    delete(self.layers)
}

grid_stack_push :: proc(self: ^Grid_Stack, index: int) -> bool
{
    count := len(self.table.layers)

    if 0 <= index && index < count {
        index, error := append(&self.layers, &self.table.layers[index])

        if error == nil {
            return true
        }
    }

    return false
}

grid_stack_clear :: proc(self: ^Grid_Stack)
{
    clear(&self.layers)
}

grid_stack_find_layer :: proc(self: ^Grid_Stack, index: int) -> ^Grid_Layer
{
    count := len(self.layers)

    if 0 <= index && index < count {
        return self.layers[index]
    }

    return nil
}

grid_stack_find_value :: proc(self: ^Grid_Stack, index: int, cell: [2]int) -> ^int
{
    count := len(self.layers)

    if cell.x < 0 || cell.x >= self.table.size.x { return nil }
    if cell.y < 0 || cell.y >= self.table.size.y { return nil }

    if 0 <= index && index < count {
        layer := self.layers[index]
        index := cell.y * self.table.size.x + cell.x

        return &layer.values[index]
    }

    return nil
}

grid_stack_find :: proc {
    grid_stack_find_layer,
    grid_stack_find_value,
}
