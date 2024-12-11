package pax

import "core:strings"
import "core:strconv"
import "core:encoding/csv"
import "core:os"
import "core:fmt"

Grid_Chunk :: struct
{
    table:  Grid_Table,
    stacks: [dynamic]Grid_Stack,
}

grid_chunk_init :: proc(self: ^Grid_Chunk, size: [2]int, tile: [2]int, allocator := context.allocator)
{
    grid_table_init(&self.table, size, tile, allocator)

    self.stacks = make([dynamic]Grid_Stack, allocator)
}

grid_chunk_destroy :: proc(self: ^Grid_Chunk)
{
    for &stack in self.stacks {
        grid_stack_destroy(&stack)
    }

    delete(self.stacks)

    grid_table_destroy(&self.table)
}

grid_chunk_load :: proc(self: ^Grid_Chunk, name: string) -> bool
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

            switch col {
                case 0: {
                    if row == 0 {
                        if grid_table_load(&self.table, field) == false {
                            return false
                        }
                    } else {
                        stack : Grid_Stack

                        grid_stack_init(&stack, &self.table)
                        
                        if grid_stack_load(&stack, field) == false {
                            return false
                        }

                        _, error := append(&self.stacks, stack)

                        if error != nil {
                            fmt.printf("FATAL: Unable to grow the chunk\n")

                            return false
                        }
                    }
                }

                case: return false
            }
        }
    }

    return true

}

grid_chunk_unload :: proc(self: ^Grid_Chunk)
{
    for &stack in self.stacks {
        grid_stack_unload(&stack)
    }

    clear(&self.stacks)

    grid_table_unload(&self.table)
}
