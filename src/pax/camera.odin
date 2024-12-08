package pax

import sdl  "vendor:sdl2"
import sdli "vendor:sdl2/image"

Camera :: struct {
    size:   [2]int,
    follow: [2]int,
    offset: [2]int,
    zoom:   [2]f32,
}

camera_draw_part :: proc(self: ^Camera, renderer: ^Renderer, texture: int, rect: [4]int, part: [4]int)
{
    rect := rect

    rect.x += self.offset.x - self.follow.x
    rect.y += self.offset.y - self.follow.y

    rect = {
        int(self.zoom.x * f32(rect.x)),
        int(self.zoom.y * f32(rect.y)),
        int(self.zoom.x * f32(rect.z)),
        int(self.zoom.y * f32(rect.w)),
    }

    renderer_draw(renderer, texture, rect, part)
}

camera_draw_full :: proc(self: ^Camera, renderer: ^Renderer, texture: int, rect: [4]int)
{
    rect := rect

    rect.x += self.offset.x - self.follow.x
    rect.y += self.offset.y - self.follow.y

    rect = {
        int(self.zoom.x * f32(rect.x)),
        int(self.zoom.y * f32(rect.y)),
        int(self.zoom.x * f32(rect.z)),
        int(self.zoom.y * f32(rect.w)),
    }

    renderer_draw(renderer, texture, rect)
}

camera_draw_sprite :: proc(self: ^Camera, renderer: ^Renderer, sprite: Sprite, point: [2]int)
{
    sprite := sprite
    point  := point

    point.x += self.offset.x - self.follow.x
    point.y += self.offset.y - self.follow.y

    point = {
        int(self.zoom.x * f32(point.x - sprite.origin.x)),
        int(self.zoom.y * f32(point.y - sprite.origin.y)),
    }

    sprite.size = {
        int(self.zoom.x * f32(sprite.size.x)),
        int(self.zoom.y * f32(sprite.size.y)),
    }

    renderer_draw(renderer, sprite, point)
}

camera_draw :: proc {
    camera_draw_part,
    camera_draw_full,
    camera_draw_sprite,
}
