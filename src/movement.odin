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
    grid:   int,
    speed:  f32,
    state:  Movement_State,
}

movement_step :: proc(self: ^Movement, grids: ^pax.Registry(pax.Grid), step: [2]int, delta: f32)
{
    active := pax.registry_find(grids, self.grid)

    switch self.state {
        case .STILL: {
            step := pax.cell_to_point(active, step)

            if step.x == 0 && step.y == 0 { return }

            stepf := [2]f32 {f32(step.x), f32(step.y)}

            self.target = self.point + stepf
            self.normal = linalg.normalize(stepf)
            self.state  = .MOVING
        }

        case .MOVING: {
            diff := self.target - self.point
            step := self.normal * self.speed * delta

            self.point += step

            diff *= diff
            step *= step

            if diff.x <= step.x { self.point.x = self.target.x }
            if diff.y <= step.y { self.point.y = self.target.y }

            if self.target == self.point {
                self.state = .STILL
            }
        }
    }
}

movement_test_collision :: proc(self: ^Movement, grids: ^pax.Registry(pax.Grid), step: [2]int, stack: int, layer: int) -> [2]int
{
    active := pax.registry_find(grids, self.grid)

    step   := [2]int {step.x, step.y}
    step_x := [2]int {step.x,      0}
    step_y := [2]int {     0, step.y}

    cell := pax.point_to_cell(active, [2]int {
        int(self.point.x), int(self.point.y),
    })

    if step.x == 0 && step.y == 0 { return step }

    next_x := pax.grid_find_value(active, stack, layer, cell + step_x)
    next_y := pax.grid_find_value(active, stack, layer, cell + step_y)

    if next_x == nil || next_x^ > 0 { step.x = 0 }
    if next_y == nil || next_y^ > 0 { step.y = 0 }

    if step.x == 0 && step.y == 0 { return step }

    next := pax.grid_find_value(active, stack, layer, cell + step)

    if next == nil || next^ > 0 { step = {0, 0} }

    return step
}

movement_test_gate :: proc(self: ^Movement, grids: ^pax.Registry(pax.Grid), stack: int, layer: int) -> ^pax.Grid_Gate
{
    active := pax.registry_find(grids, self.grid)

    cell := pax.point_to_cell(active, [2]int {
        int(self.point.x), int(self.point.y),
    })

    curr := pax.grid_find_value(active, stack, layer, cell)

    if curr != nil && curr^ > 0 {
        index := curr^ - 1

        if index < len(active.gates) {
            return &active.gates[index]
        }
    }

    return nil
}

import "core:fmt"

movement_grid_next :: proc(self: ^Movement, grids: ^pax.Registry(pax.Grid), step: [2]int, stack: int, layer: int)
{
    active := pax.registry_find(grids, self.grid)

    cell := pax.point_to_cell(active, [2]int {
        int(self.point.x), int(self.point.y)
    })

    if self.state != .STILL { return }

    curr := pax.grid_find_value(active, stack, layer, cell)
    next := pax.grid_find_value(active, stack, layer, cell + step)

    if curr != nil && next != nil {
        next^ = curr^
        curr^ = -1
    }
}

movement_grid_change :: proc(self: ^Movement, grids: ^pax.Registry(pax.Grid), stack: int, layer: int, gate: pax.Grid_Gate)
{
    active := pax.registry_find(grids, self.grid)
    dest   := pax.registry_find(grids, gate.grid)

    if self.state != .STILL { return }

    cell := pax.point_to_cell(active, [2]int {
        int(self.point.x), int(self.point.y)
    })

    curr := pax.grid_find_value(active, stack, layer, cell)
    next := pax.grid_find_value(dest,   stack, layer, gate.cell + gate.step)

    point := pax.cell_to_point(dest, gate.cell)
    step  := pax.cell_to_point(dest, gate.step)

    pointf := [2]f32 {f32(point.x), f32(point.y)}
    stepf  := [2]f32 {f32(step.x),  f32(step.y)}

    if next != nil && curr != nil {
        self.point  = pointf
        self.normal = linalg.normalize(stepf)
        self.target = pointf + stepf
        self.grid   = gate.grid

        if gate.step.x != 0 && gate.step.y != 0 {
            self.state = .MOVING
        }

        next^ = curr^
        curr^ = -1
    }
}
