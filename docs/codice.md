### Attori

```odin
Trait_A :: struct {}
Trait_B :: struct {}

Group_X :: struct {
    a: [dynamic]Trait_A,
    b: [dynamic]Trait_B,
}

group_x_step :: proc(group: ^Group_X, delta: f64)
{
    for &a, i in group.a {
        b := group.b[i]

        // ...
    }

}

Group_Y :: struct {
    a: [dynamic]Trait_A,
}

group_y_step :: proc(group: ^Group_Y, delta: f64)
{
    for &a, i in group.a {
        // ...
    }
}

Scene_1 :: struct {
    x: Group_X,
    y: Group_Y,

    ground: Grid_Layer,
    object: Grid_Layer,
    entity: Grid_Layer,
    height: Grid_Layer,
}

scene_1_step :: proc(scene: ^Scene_1, delta: f64)
{
    group_x_step(group.x, delta)
    group_y_step(group.y, delta)
}
```
