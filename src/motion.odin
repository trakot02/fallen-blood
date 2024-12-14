package main

import "core:math/linalg"

import "pax"

Motion_State :: enum
{
    STILL, MOVING,
}

Motion :: struct
{
    point:  [2]f32,
    target: [2]f32,
    normal: [2]f32,
    speed:  f32,
    state:  Motion_State,
}

motion_step :: proc(self: ^Motion, grid: ^pax.Grid, step: [2]int, delta: f32) -> bool
{
    switch self.state {
        case .STILL: {
            tile := pax.cell_to_point(grid, step)

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

motion_test :: proc(self: ^Motion, grid: ^pax.Grid, step: [2]int, stack: int, layer: int) -> [2]int
{
    step := step
    cell := pax.point_to_cell(grid, [2]int {
        int(self.point.x), int(self.point.y),
    })

    if step.x == 0 && step.y == 0 { return step }

    next_x := pax.grid_find_value(grid, stack, layer, [2]int {cell.x + step.x, cell.y})
    next_y := pax.grid_find_value(grid, stack, layer, [2]int {cell.x, cell.y + step.y})

    if next_x == nil || next_x^ >= 0 { step.x = 0 }
    if next_y == nil || next_y^ >= 0 { step.y = 0 }

    if step.x == 0 && step.y == 0 { return step }

    next := pax.grid_find_value(grid, stack, layer, cell + step)

    if next == nil || next^ >= 0 {
        step.x = 0
        step.y = 0
    }

    return step
}

motion_grid :: proc(self: ^Motion, grid: ^pax.Grid, step: [2]int, stack: int, layer: int)
{
    cell := pax.point_to_cell(grid, [2]int {
        int(self.point.x), int(self.point.y)
    })

    curr := pax.grid_find_value(grid, stack, layer, cell)
    next := pax.grid_find_value(grid, stack, layer, cell + step)

    if curr != nil && next != nil {
        temp := curr^

        curr^ = next^
        next^ = temp
    }
}
