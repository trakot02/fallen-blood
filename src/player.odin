package main

import "pax"

Player :: struct
{
    visible:  pax.Visible,
    movement: Movement,
    controls: Controls,

    camera: ^pax.Camera,
}
