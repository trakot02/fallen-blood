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
    self.first  = -1
    self.actors = make([dynamic]int, allocator)
}

world_destroy :: proc(self: ^World)
{
    delete(self.actors)

    self.count = 0
    self.first = -1
}

world_create_actor :: proc(self: ^World) -> int
{
    actor := len(self.actors)

    if self.count <= 0 || self.first == -1 {
        _, error := append(&self.actors, actor)

        if error != nil {
            log.errorf("Unable to create a new actor\n")

            actor = -1
        }
    } else {
        next := self.actors[self.first]

        actor = self.first

        self.actors[self.first] = actor

        self.first  = next
        self.count -= 1
    }

    return actor
}

world_destroy_actor :: proc(self: ^World, actor: int)
{
    index := len(self.actors)

    if 0 <= actor && actor < index {
        value := &self.actors[actor]

        if actor == value^ {
            value^ = self.first

            self.first   = actor
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
    if actor < 0 { return nil }

    if actor > self.count - 1 {
        error := resize(&self.actors, actor + 1)

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

    self.actors[actor] = index + 1
    self.values[index] = {}

    return &self.values[index]
}

group_remove :: proc(self: ^Group($T), actor: int)
{
    index := len(self.actors)

    if 0 <= actor && actor < index {
        other := self.actors[actor] - 1

        if other < 0 { return }

        assert(false)

        // TODO: fix the swap
        // self.actors[self.count - 1] = self.actors[actor]
        // self.actors[actor] = 0

        // if index - 1 != actor {
        //     self.values[actor] = self.values[index - 1]
        // }

        self.count -= 1
    }
}

group_find :: proc(self: ^Group($T), actor: int) -> ^T
{
    index := len(self.actors)

    if 0 <= actor && actor < index {
        other := self.actors[actor] - 1

        if 0 <= other && other < self.count {
            return &self.values[other]
        }
    }

    return nil
}
