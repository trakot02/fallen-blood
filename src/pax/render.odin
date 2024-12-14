package pax

import sdl  "vendor:sdl2"
import sdli "vendor:sdl2/image"

Render_State :: struct
{
    renderer: ^sdl.Renderer,

    camera: ^Camera,

    images: [dynamic]Image,
    sheets: [dynamic]Image_Sheet,
}

render_init :: proc(self: ^Render_State, allocator := context.allocator)
{
    self.images = make([dynamic]Image, allocator)
    self.sheets = make([dynamic]Image_Sheet, allocator)
}

render_destroy :: proc(self: ^Render_State)
{
    delete(self.sheets)
    delete(self.images)
}

render_draw_sprite :: proc(self: ^Render_State, sprite: Sprite)
{
    if sprite.sheet < 0 || sprite.sheet >= len(self.sheets) { return }

    sheet := &self.sheets[sprite.sheet]

    if sheet == nil ||
       sprite.frame < 0 || sprite.frame >= len(sheet.frames) ||
       sheet.image  < 0 || sheet.image  >= len(self.images) { return }

    frame := &sheet.frames[sprite.frame]
    image := &self.images[sheet.image]

    displ := [2]int {0, 0}
    scale := [2]f32 {1, 1}

    if self.camera != nil {
        displ = camera_displ(self.camera) - frame.base
        scale = camera_scale(self.camera) + sprite.scale
    }

    part := sdl.Rect {
        i32(frame.rect.x), i32(frame.rect.y),
        i32(frame.rect.z), i32(frame.rect.w),
    }

    rect := sdl.Rect {
        i32(scale.x * f32(sprite.point.x + displ.x)),
        i32(scale.y * f32(sprite.point.y + displ.y)),
        i32(scale.x * f32(frame.rect.z)),
        i32(scale.y * f32(frame.rect.w)),
    }

    assert(sdl.RenderCopy(self.renderer, image.data, &part, &rect) == 0,
        sdl.GetErrorString())
}
