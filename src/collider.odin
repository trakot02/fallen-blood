package main

import "core:fmt"

import "pax"

collider_test :: proc(grid: ^pax.Grid, point: [2]int, angle: [2]int) -> [2]int
{
    delta := angle
    cell  := pax.grid_from_point(grid, point)

    if delta.x == 0 && delta.y == 0 { return delta }

    actor_x := pax.grid_find(grid, {cell.x + delta.x, cell.y})
    actor_y := pax.grid_find(grid, {cell.x, cell.y + delta.y})

    if actor_x == nil || actor_x^ > 0 { delta.x = 0 }
    if actor_y == nil || actor_y^ > 0 { delta.y = 0 }

    if delta.x != 0 || delta.y != 0 {
        actor := pax.grid_find(grid, cell + delta)

        if actor == nil || actor^ > 0 {
            return {0, 0}
        }
    }

    return delta
}

collider_move :: proc(grid: ^pax.Grid, point: [2]int, angle: [2]int)
{
    cell := pax.grid_from_point(grid, point)

    if angle.x == 0 && angle.y == 0 { return }

    curr := pax.grid_find(grid, cell)
    next := pax.grid_find(grid, cell + angle)

    if curr != nil && next != nil {
        next^ = curr^
        curr^ = -1
    }
}
