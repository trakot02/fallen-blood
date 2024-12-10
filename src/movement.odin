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

movement_step :: proc(self: ^Movement, grid: ^pax.Grid_Table, angle: [2]int, delta: f32)
{
    if self.state == .STILL {
        tile := pax.cell_to_point(grid, angle)

        if angle.x == 0 && angle.y == 0 { return }

        diff := [2]f32 {f32(tile.x), f32(tile.y)}

        self.target = self.point + diff
        self.normal = linalg.normalize(diff)
        self.state  = .MOVING
    }

    if self.state == .MOVING {
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
