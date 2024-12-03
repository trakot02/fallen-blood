package pax

import "core:fmt"

Actor :: struct
{
    index: int,
    magic: int,
}

World :: struct
{
    head:  int,
    count: int,
    table: [dynamic]Actor,
}

Group :: struct ($T: typeid)
{
    world: ^World,
    count: int,
    table: [dynamic]Actor,
    value: [dynamic]T,
}

world_create :: proc(self: ^World, allocator := context.allocator)
{
    self.head  = -1
    self.table = make([dynamic]Actor, allocator)
}

world_destroy :: proc(self: ^World)
{
    delete(self.table)

    self.count = 0
    self.head  = -1
}

world_create_actor :: proc(self: ^World) -> (Actor)
{
    index  := len(self.table)
    result := Actor {index, 0}

    if self.count <= 0 || self.head == -1 {
        _, error := append(&self.table, result)

        if error != nil {
            fmt.printf("ERROR: Unable to create a new actor\n")

            return Actor {-1, 0}
        }
    } else {
        next := self.table[self.head]

        result = {self.head, next.magic}

        self.head   = next.index
        self.count -= 1
    }

    return result
}

world_destroy_actor :: proc(self: ^World, actor: Actor)
{
    index := len(self.table)

    if 0 <= actor.index && actor.index < index {
        value := &self.table[actor.index]

        if value.magic != actor.magic { return }

        if self.count + 1 >= 0 && value.magic + 1 >= 0 {
            value.index  = self.head
            value.magic += 1

            self.head   = actor.index
            self.count += 1
        }
    }
}

group_create :: proc(self: ^Group($T), world: ^World, allocator := context.allocator)
{
    self.world = world
    self.table = make([dynamic]Actor, allocator)
    self.value = make([dynamic]T, allocator)
}

group_destroy :: proc(self: ^Group($T))
{
    delete(self.value)
    delete(self.table)

    self.count = 0
    self.world = nil
}

group_create_actor :: proc(self: ^Group($T)) -> (Actor, ^T)
{
    actor := world_create_actor(self.world)

    if actor.index == -1 { return actor, nil }

    if actor.index > self.count - 1 {
        self.count = actor.index + 1

        _, error := append(&self.table, actor)

        if error == nil {
            error = resize(&self.value, self.count)
        }

        if error != nil {
            fmt.printf("ERROR: Unable to create a new actor\n")

            world_destroy_actor(self.world, actor)

            return Actor {-1, 0}, nil
        }
    } else {
        index := actor.index

        self.table[index].index = self.count
        self.table[index].magic = actor.magic

        self.count += 1
    }

    index := &self.table[actor.index].index
    value := &self.value[index^]

    value^ = {}

    return actor, value
}

group_destroy_actor :: proc(self: ^Group($T), actor: Actor)
{
    index := len(self.table)

    if 0 <= actor.index && actor.index < index {
        value := &self.table[actor.index]

        if value.magic != actor.magic { return }

        self.table[index - 1].index  = actor.index
        self.table[index - 1].magic += 1

        self.table[actor.index] = Actor {-1, 0}

        if index - 1 != actor.index {
            self.value[actor.index] = self.value[index - 1]
        }

        self.count -= 1

        world_destroy_actor(self.world, actor)
    }
}

group_find :: proc(self: ^Group($T), actor: Actor) -> ^T
{
    index := len(self.table)

    if 0 <= actor.index && actor.index < index {
        value := &self.table[actor.index]

        if value.magic != actor.magic { return nil }

        index = self.table[actor.index].index

        if 0 <= index && index < self.count {
            return &self.value[index]
        }
    }

    return nil
}
