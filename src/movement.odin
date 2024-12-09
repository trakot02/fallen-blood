package main

import "core:math/linalg"

import "pax"

Movement_State :: enum
{
    STILL, MOVING,
}

Movement :: struct
{
    delta:  [2]int,
    point:  [2]int,
    target: [2]int,
    angle:  [2]f32,
    speed:  f32,
    state:  Movement_State,
}

movement_step :: proc(self: ^Movement, grid: ^pax.Grid_Table, angle: [2]int, delta: f32)
{
    if self.state == .STILL {
        self.delta = angle

        if angle.x == 0 && angle.y == 0 { return }

        next := pax.cell_to_point(grid, self.delta)

        self.angle = linalg.normalize0([2]f32 {
            f32(self.delta.x), f32(self.delta.y)
        })

        self.target = self.point + next
        self.state  = .MOVING
    }

    if self.state == .MOVING {
        self.point += {
            int(self.angle.x * self.speed * delta),
            int(self.angle.y * self.speed * delta),
        }

        diff := self.target - self.point

        if diff.x * self.delta.x <= 0 {
            self.point.x = self.target.x
        }

        if diff.y * self.delta.y <= 0 {
            self.point.y = self.target.y
        }

        if self.target == self.point {
            self.state = .STILL
        }
    }
}
