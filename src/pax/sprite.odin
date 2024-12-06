package pax

import sdl  "vendor:sdl2"
import sdli "vendor:sdl2/image"

Sprite :: struct
{
    texture: Texture,
    frame:   [4]int,
    pixel:   [2]int,
    offset:  [2]int,
}

sprite_draw :: proc(self: ^Sprite, camera: ^Camera, render: ^sdl.Renderer)
{
    rect := [4]int {
        self.pixel.x + self.offset.x,
        self.pixel.y + self.offset.y,
        self.frame.z,
        self.frame.w,
    }

    camera_draw(camera, self.texture, render, self.frame, rect)
}
