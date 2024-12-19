package pax

import "core:log"

World :: struct
{
    first:  int,
    count:  int,
    actors: [dynamic]int,
}

world_init :: proc(self: ^World, allocator := context.allocator)
{
    self.actors = make([dynamic]int, allocator)
}

world_destroy :: proc(self: ^World)
{
    delete(self.actors)

    self.count = 0
    self.first = 0
}

world_create_actor :: proc(self: ^World) -> int
{
    count := len(self.actors)

    if self.count > 0 {
        index := self.first - 1
        next  := self.actors[index]

        self.actors[index] = index

        self.first  = next + 1
        self.count -= 1

        return index + 1
    }

    _, error := append(&self.actors, count)

    if error != nil {
        log.errorf("Unable to create a new actor\n")

        return 0
    }

    return count + 1
}

world_delete_actor :: proc(self: ^World, actor: int)
{
    count := len(self.actors)
    index := actor - 1

    if 0 < actor && actor <= count {
        value := &self.actors[index]

        if value^ == index {
            value^ = self.first

            self.first  = actor
            self.count += 1
        }
    }
}

Group :: struct ($T: typeid)
{
    count:  int,
    actors: [dynamic]int,
    values: [dynamic]T,
}

group_init :: proc(self: ^Group($T), allocator := context.allocator)
{
    self.actors = make([dynamic]int, allocator)
    self.values = make([dynamic]T,   allocator)
}

group_destroy :: proc(self: ^Group($T))
{
    delete(self.values)
    delete(self.actors)

    self.count = 0
}

group_insert :: proc(self: ^Group($T), actor: int) -> ^T
{
    if actor <= 0 { return nil }

    if actor > self.count {
        error := resize(&self.actors, actor)

        if error == nil {
            error = resize(&self.values, self.count + 1)
        }

        if error != nil {
            log.errorf("Unable to insert a value for the actor %v\n",
                actor)

            return nil
        }
    }

    index := self.count

    self.count += 1

    self.actors[actor - 1] = index + 1
    self.values[index]     = {}

    return &self.values[index]
}

group_remove :: proc(self: ^Group($T), actor: int)
{
    assert(false, "Not implemented yet")
}

group_clear :: proc(self: ^Group($T))
{
    clear(&self.values)
    clear(&self.actors)

    self.count = 0
}

group_find :: proc(self: ^Group($T), actor: int) -> ^T
{
    count := len(self.actors)
    index := actor - 1

    if 0 < actor && actor <= count {
        index = self.actors[index] - 1

        if 0 <= index && index < self.count {
            return &self.values[index]
        }
    }

    return nil
}
