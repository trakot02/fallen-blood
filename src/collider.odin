package main

import "core:fmt"

import "pax"

collider_test :: proc(grid: ^pax.Grid, point: [2]int, angle: [2]int) -> [2]int
{
    angle := angle
    cell  := pax.grid_from_point(grid, point)

    if angle.x == 0 && angle.y == 0 { return angle }

    actor_x := pax.grid_find(grid, {cell.x + angle.x, cell.y})
    actor_y := pax.grid_find(grid, {cell.x, cell.y + angle.y})

    if actor_x == nil || actor_x^ >= 0 { angle.x = 0 }
    if actor_y == nil || actor_y^ >= 0 { angle.y = 0 }

    if angle.x != 0 || angle.y != 0 {
        actor := pax.grid_find(grid, cell + angle)

        if actor == nil || actor^ >= 0 {
            return {0, 0}
        }
    }

    return angle
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
