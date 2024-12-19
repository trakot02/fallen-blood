package main

import "core:fmt"

import "pax"

Render_State :: struct
{
    renderer: ^pax.Renderer,
    camera:   ^pax.Camera,
    images:   ^pax.Registry(pax.Image),
    sprites:  ^pax.Registry(pax.Sprite),
}

render_state_draw_sprite :: proc(self: ^Render_State, animation: Animation, transform: Transform)
{
    point := [2]int {0, 0}
    scale := [2]f32 {1, 1}

    sprite := pax.registry_find(self.sprites, animation.sprite)

    if sprite == nil { return }

    if animation.chain <= 0 ||
       animation.chain  > len(sprite.chains) { return }

    chain := sprite.chains[animation.chain - 1]
    frame := sprite.frames[chain.frames[chain.frame] - 1]

    image := pax.registry_find(self.images, sprite.image)

    if image == nil { return }

    if self.camera != nil {
        point = pax.camera_point(self.camera) - frame.base
        scale = pax.camera_scale(self.camera) + transform.scale
    }

    pax.renderer_draw_image(self.renderer, image^, frame.rect, [4]int {
        int(scale.x * f32(transform.point.x + point.x)),
        int(scale.y * f32(transform.point.y + point.y)),
        int(scale.x * f32(frame.rect.z)),
        int(scale.y * f32(frame.rect.w)),
    })
}
