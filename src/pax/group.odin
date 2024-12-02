package pax

Group :: struct
{

}

group_create :: proc(self: ^Group)
{

}

group_destroy :: proc(self: ^Group)
{

}

Actor :: struct
{

}

group_create_actor :: proc(self: ^Group) -> Actor
{
    return {}
}

group_destroy_actor :: proc(self: ^Group, actor: ^Actor)
{

}
