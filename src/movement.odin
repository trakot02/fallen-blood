package main

import "core:math/linalg"

import "pax"

Movement_State :: enum
{
    STILL, MOVING,
}

Movement :: struct
{
    point:  [2]f32,
    target: [2]f32,
    normal: [2]f32,
    speed:  f32,
    state:  Movement_State,
}

movement_step :: proc(self: ^Movement, grid: ^pax.Grid_Stack, step: [2]int, delta: f32) -> bool
{
    switch self.state {
        case .STILL: {
            tile := pax.cell_to_point(grid.table, step)

            if step.x == 0 && step.y == 0 { return false }

            diff := [2]f32 {f32(tile.x), f32(tile.y)}

            self.target = self.point + diff
            self.normal = linalg.normalize(diff)
            self.state  = .MOVING

            return true
        }

        case .MOVING: {
            diff := self.target - self.point
            step := self.normal * self.speed * delta

            self.point += step

            if diff.x * diff.x <= step.x * step.x {
                self.point.x = self.target.x
            }

            if diff.y * diff.y <= step.y * step.y {
                self.point.y = self.target.y
            }

            if self.target == self.point {
                self.state  = .STILL
            }
        }
    }

    return false
}

movement_test :: proc(self: ^Movement, grid: ^pax.Grid_Stack, step: [2]int, index: int) -> [2]int
{
    step := step
    cell := pax.point_to_cell(grid.table, [2]int {
        int(self.point.x), int(self.point.y),
    })

    if step.x == 0 && step.y == 0 { return step }

    next_x := pax.grid_stack_find(grid, index, [2]int {cell.x + step.x, cell.y})
    next_y := pax.grid_stack_find(grid, index, [2]int {cell.x, cell.y + step.y})

    if next_x == nil || next_x^ >= 0 { step.x = 0 }
    if next_y == nil || next_y^ >= 0 { step.y = 0 }

    if step.x == 0 && step.y == 0 { return step }

    next := pax.grid_stack_find(grid, index, cell + step)

    if next == nil || next^ >= 0 {
        step.x = 0
        step.y = 0
    }

    return step
}

movement_grid :: proc(self: ^Movement, grid: ^pax.Grid_Stack, step: [2]int, index: int)
{
    cell := pax.point_to_cell(grid.table, [2]int {
        int(self.point.x), int(self.point.y)
    })

    pax.grid_stack_swap(grid, index, cell, cell + step)
}
