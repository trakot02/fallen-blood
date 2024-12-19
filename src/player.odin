package main

import "pax"

Player :: struct
{
    camera:   ^pax.Camera,

    animation: Animation,
    transform: Transform,
    movement:  Movement,
    controls:  Controls,
}
