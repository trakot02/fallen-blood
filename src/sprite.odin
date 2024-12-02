package main

import "pax"

Sprite :: struct
{
    texture: pax.Texture,
    frame:   [4]i32,
}

sprite_draw :: proc(self: ^Sprite, camera: ^pax.Camera, point: [2]f32)
{
    pax.camera_draw(camera, self.texture, self.frame, {
        point.x, point.y, f32(self.frame.z), f32(self.frame.w),
    })
}
