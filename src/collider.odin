package main

import "core:fmt"

import "pax"

collider_test :: proc(grid: ^pax.Grid_Stack, point: [2]f32, angle: [2]int, index: int) -> [2]int
{
    angle := angle
    cell  := pax.point_to_cell(grid.table, [2]int {int(point.x), int(point.y)})

    if angle.x == 0 && angle.y == 0 { return angle }

    value_x := pax.grid_stack_find(grid, index, [2]int {cell.x + angle.x, cell.y})
    value_y := pax.grid_stack_find(grid, index, [2]int {cell.x, cell.y + angle.y})

    if value_x == nil || value_x^ >= 0 { angle.x = 0 }
    if value_y == nil || value_y^ >= 0 { angle.y = 0 }

    if angle.x == 0 && angle.y == 0 { return angle }

    value := pax.grid_stack_find(grid, index, cell + angle)

    if value == nil || value^ >= 0 { return {0, 0} }

    return angle
}

collider_move :: proc(grid: ^pax.Grid_Stack, point: [2]f32, angle: [2]int, index: int)
{
    cell := pax.point_to_cell(grid.table, [2]int {int(point.x), int(point.y)})

    if angle.x == 0 && angle.y == 0 { return }

    curr := pax.grid_stack_find(grid, index, cell)
    next := pax.grid_stack_find(grid, index, cell + angle)

    if curr != nil && next != nil {
        next^ = curr^
        curr^ = -1
    }
}
