### Attori

Gli attori sono suddivisi in gruppi, ogni gruppo non è altro che un raggruppamento di più array dinamici del tipo:

```odin
Trait_A :: struct {}
Trait_B :: struct {}

Group_X :: struct {
    a: [dynamic]Trait_A,
    b: [dynamic]Trait_B,
}
```

Dopodiché nell'aggiornamento delle scene i gruppi vengono aggiornati a mano.

```odin
group_x_step :: proc(group: ^Group_X, delta: f64)
{
    actor: i32

    for ; actor < group.size; actor += 1 {
        a := group.a[actor]
        b := group.b[actor]

        // ecc.
    }
}
```

Ogni attore esiste solamente all'interno del proprio gruppo. Ogni entità quindi è una coppia della forma:

```odin
Actor :: struct {
    group: i32,
    index: i32,
}
```
