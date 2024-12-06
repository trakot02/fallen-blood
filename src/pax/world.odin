package pax

import "core:fmt"

World :: struct
{
    head:  int,
    count: int,
    table: [dynamic]int,
}

Group :: struct ($T: typeid)
{
    count: int,
    table: [dynamic]int,
    value: [dynamic]T,
}

world_create :: proc(self: ^World, allocator := context.allocator)
{
    self.head  = -1
    self.table = make([dynamic]int, allocator)
}

world_destroy :: proc(self: ^World)
{
    delete(self.table)

    self.count = 0
    self.head  = -1
}

world_create_actor :: proc(self: ^World) -> int
{
    actor := len(self.table)

    if self.count <= 0 || self.head == -1 {
        _, error := append(&self.table, actor)

        if error != nil {
            fmt.printf("ERROR: Unable to create a new actor\n")

            return -1
        }
    } else {
        next := &self.table[self.head]

        actor = self.head

        self.head   = next^
        self.count -= 1

        next^ = actor
    }

    return actor
}

world_destroy_actor :: proc(self: ^World, actor: int)
{
    index := len(self.table)

    if 0 <= actor && actor < index {
        value := &self.table[actor]

        assert(value^ == actor)

        value^ = self.head

        self.head   = actor
        self.count += 1
    }
}

group_create :: proc(self: ^Group($T), allocator := context.allocator)
{
    self.table = make([dynamic]int, allocator)
    self.value = make([dynamic]T,   allocator)
}

group_destroy :: proc(self: ^Group($T))
{
    delete(self.value)
    delete(self.table)

    self.count = 0
}

group_insert :: proc(self: ^Group($T), actor: int) -> ^T
{
    if actor < 0 { return nil }

    if actor > self.count - 1 {
        error := resize(&self.table, actor + 1)

        if error == nil {
            error = resize(&self.value, self.count + 1)
        }

        if error != nil {
            fmt.printf("ERROR: Unable to insert a value for the actor %v\n",
                actor)

            return nil
        }
    }

    index := self.count

    self.count += 1

    self.table[actor] = index + 1
    self.value[index] = {}

    return &self.value[index]
}

// todo: fix the removal
group_remove :: proc(self: ^Group($T), actor: int)
{
    index := len(self.table)

    if 0 <= actor && actor < index {
        other := self.table[actor] - 1

        if other < 0 { return }

        self.table[self.count - 1] = self.table[actor]
        self.table[actor] = 0

        if index - 1 != actor {
            self.value[actor] = self.value[index - 1]
        }

        self.count -= 1
    }
}

group_find :: proc(self: ^Group($T), actor: int) -> ^T
{
    index := len(self.table)

    if 0 <= actor && actor < index {
        other := self.table[actor] - 1

        if 0 <= other && other < self.count {
            return &self.value[other]
        }
    }

    return nil
}
