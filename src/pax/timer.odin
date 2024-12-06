package pax

Timer :: struct
{
    total: f32,
    count: f32,
}

timer_update :: proc(self: ^Timer, delta: f32) -> bool
{
    self.count += delta

    if self.count >= self.total {
        self.count -= self.total

        return true
    }

    return false
}
