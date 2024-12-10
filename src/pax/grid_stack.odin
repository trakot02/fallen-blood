package pax

import "core:strings"
import "core:strconv"
import "core:encoding/csv"
import "core:os"
import "core:fmt"

Grid_Swap_Event :: struct
{
    source: ^Grid_Stack,
    layer: int,
    cell1: [2]int,
    cell2: [2]int,
}

Grid_Stack :: struct
{
    table:  ^Grid_Table,
    layers: [dynamic]^Grid_Layer,

    swap: Channel(Grid_Swap_Event),
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

    channel_init(&self.swap, allocator)
}

grid_stack_destroy :: proc(self: ^Grid_Stack)
{
    channel_destroy(&self.swap)

    delete(self.layers)
}

grid_stack_push :: proc(self: ^Grid_Stack, index: int) -> bool
{
    count := len(self.table.layers)

    if 0 <= index && index < count {
        _, error := append(&self.layers, &self.table.layers[index])

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
        temp  := cell.y * self.table.size.x + cell.x

        return grid_layer_find(layer, temp)
    }

    return nil
}

grid_stack_swap :: proc(self: ^Grid_Stack, index: int, cell1: [2]int, cell2: [2]int)
{
    count  := len(self.layers)
    result := 0

    if cell1.x < 0 || cell1.x >= self.table.size.x { return }
    if cell1.y < 0 || cell1.y >= self.table.size.y { return }

    if cell2.x < 0 || cell2.x >= self.table.size.x { return }
    if cell2.y < 0 || cell2.y >= self.table.size.y { return }

    if 0 <= index && index < count {
        layer := self.layers[index]
        temp1 := cell1.y * self.table.size.x + cell1.x
        temp2 := cell2.y * self.table.size.x + cell2.x

        channel_send(&self.swap, Grid_Swap_Event {
            source = self,
            layer  = index,
            cell1  = cell1,
            cell2  = cell2,
        })

        grid_layer_swap(layer, temp1, temp2)
    }
}

grid_stack_find :: proc {
    grid_stack_find_layer,
    grid_stack_find_value,
}
