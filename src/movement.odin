package main

Movement_State :: enum
{
    STILL,
    MOVING,
}

Movement :: struct
{
    point:  [2]f32,
    delta:  [2]i32,
    angle:  [2]f32,
    target: [2]f32,
    speed:  f32,
    state:  Movement_State,
}
