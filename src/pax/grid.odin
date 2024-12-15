package pax

import "core:mem"
import "core:log"
import "core:encoding/json"
import "core:os"

Grid_Layer :: []int
Grid_Stack :: []int

Grid_Gate :: struct
{
    grid: int,
    cell: [2]int,
    step: [2]int,
}

Grid :: struct
{
    tile:   [2]int,
    size:   [2]int,
    layers: []Grid_Layer,
    stacks: []Grid_Stack,
    gates:  []Grid_Gate,
}

grid_find_stack :: proc(self: ^Grid, stack: int) -> ^Grid_Stack
{
    count := len(self.stacks)

    if 0 <= stack && stack < count {
        return &self.stacks[stack]
    }

    return nil
}

grid_find_layer :: proc(self: ^Grid, stack: int, layer: int) -> ^Grid_Layer
{
    count := len(self.layers)
    stk   := grid_find_stack(self, stack)

    if stk != nil && 0 <= layer && layer < count {
        return &self.layers[stk[layer]]
    }

    return nil
}

grid_find_value :: proc(self: ^Grid, stack: int, layer: int, cell: [2]int) -> ^int
{
    index := cell_to_index(self, cell)
    lyr   := grid_find_layer(self, stack, layer)

    if cell.x < 0 || cell.x >= self.size.x ||
       cell.y < 0 || cell.y >= self.size.y { return nil }

    if lyr == nil { return nil }

    return &lyr[index]
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

Grid_Reader :: struct
{
    allocator: mem.Allocator,
}

grid_read :: proc(self: ^Grid_Reader, name: string) -> (Grid, bool)
{
    spec  := json.DEFAULT_SPECIFICATION
    temp  := context.temp_allocator
    value := Grid {}

    data, succ := os.read_entire_file_from_filename(name, temp)

    if succ == false {
        log.errorf("Unable to open %q for reading\n",
            name)

        return {}, false
    }

    error := json.unmarshal(data, &value, spec, self.allocator)

    mem.free_all(temp)

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

    if error != nil {
        return {}, false
    }

    return value, true
}

grid_clear :: proc(self: ^Grid_Reader, value: ^Grid)
{
    mem.free_all(self.allocator)
}

Grid_State :: struct
{
    grids: [dynamic]Grid,
}

grid_init :: proc(self: ^Grid_State, allocator := context.allocator)
{
    self.grids = make([dynamic]Grid, allocator)
}

grid_destroy :: proc(self: ^Grid_State)
{
    delete(self.grids)
}

grid_find :: proc(self: ^Grid_State, grid: int) -> ^Grid
{
    count := len(self.grids)

    if 0 <= grid && grid < count {
        return &self.grids[grid]
    }

    return nil
}
