package pax

import "core:mem"
import "core:log"
import "core:encoding/json"
import "core:os"

Grid_Gate :: struct
{
    grid: int,
    cell: [2]int,
    step: [2]int,
}

Grid_Layer :: []int
Grid_Stack :: []int

Grid :: struct
{
    tile:   [2]int,
    size:   [2]int,
    layers: []Grid_Layer,
    stacks: []Grid_Stack,
    gates:  []Grid_Gate,
}

grid_find_layer :: proc(self: ^Grid, stack: int, layer: int) -> ^Grid_Layer
{
    stack_count := len(self.stacks)
    stack_index := stack - 1
    layer_count := len(self.layers)
    layer_index := layer - 1

    if 0 <= stack_index && stack_index < stack_count {
        stack := &self.stacks[stack_index]

        if 0 <= layer_index && layer_index < layer_count {
            return &self.layers[stack[layer_index] - 1]
        }
    }

    return nil
}

grid_find_value :: proc(self: ^Grid, stack: int, layer: int, cell: [2]int) -> ^int
{
    index := cell_to_index(self, cell)

    if cell.x < 0 || cell.x >= self.size.x ||
       cell.y < 0 || cell.y >= self.size.y { return nil }

    values := grid_find_layer(self, stack, layer)

    if values != nil {
        return &values[index]
    }

    return nil
}

grid_find :: proc {
    grid_find_layer,
    grid_find_value,
}

cell_to_point :: proc(self: ^Grid, cell: [2]int) -> [2]int
{
    return cell * self.tile
}

cell_to_index :: proc(self: ^Grid, cell: [2]int) -> int
{
    return cell.y * self.size.x + cell.x
}

point_to_cell :: proc(self: ^Grid, cell: [2]int) -> [2]int
{
    return cell / self.tile
}

index_to_cell :: proc(self: ^Grid, index: int) -> [2]int
{
    return {index % self.size.x, index / self.size.x}
}

Grid_Resource :: struct
{
    allocator: mem.Allocator,
}

grid_clear :: proc(self: ^Grid_Resource, value: ^Grid)
{
    mem.free_all(self.allocator)
}

grid_read :: proc(self: ^Grid_Resource, name: string) -> (Grid, bool)
{
    spec  := json.DEFAULT_SPECIFICATION
    alloc := context.temp_allocator
    value := Grid {}

    bytes, state := os.read_entire_file_from_filename(name, alloc)

    if state == false {
        log.errorf("Unable to open %q for reading\n",
            name)

        return {}, false
    }

    error := json.unmarshal(bytes, &value, spec, self.allocator)

    mem.free_all(alloc)

    switch type in error {
        case json.Error: log.errorf("Unable to parse JSON\n")

        case json.Unmarshal_Data_Error: {
            log.errorf("Unable to unmarshal JSON:")

            switch type {
                case .Invalid_Data:          log.errorf("Invalid data\n")
                case .Invalid_Parameter:     log.errorf("Invalid parameter\n")
                case .Multiple_Use_Field:    log.errorf("Multiple use field\n")
                case .Non_Pointer_Parameter: log.errorf("Non pointer parameter\n")
                case:                        log.errorf("\n")
            }
        }

        case json.Unsupported_Type_Error: {
            log.errorf("Unable to parse JSON: Unsupported type\n")
        }
    }

    if error != nil { return {}, false }

    return value, true
}

grid_resource :: proc(self: ^Grid_Resource) -> Resource(Grid)
{
    value := Resource(Grid) {}

    value.instance = auto_cast self

    value.clear_proc = auto_cast grid_clear
    value.read_proc  = auto_cast grid_read

    return value
}
