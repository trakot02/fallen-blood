package pax

import "core:log"

Resource :: struct ($T: typeid)
{
    instance: rawptr,

    clear_proc: proc(self: rawptr, value: ^T),
    read_proc:  proc(self: rawptr, name: string) -> (T, bool),
    write_proc: proc(),
}

resource_clear :: proc(self: ^Resource($T), value: ^T)
{
    self.clear_proc(self.instance, value)
}

resource_read :: proc(self: ^Resource($T), name: string) -> (T, bool)
{
    return self.read_proc(self.instance, name)
}

resource_write :: proc(self: ^Resource($T))
{
    assert(false, "Not implemented yet")
}

Registry :: struct ($T: typeid)
{
    resource: Resource(T),

    values: [dynamic]T,
}

registry_init :: proc(self: ^Registry($T), resource: Resource(T), allocator := context.allocator)
{
    self.resource = resource
    self.values   = make([dynamic]T, allocator)
}

registry_destroy :: proc(self: ^Registry($T))
{
    delete(self.values)

    self.resource = {}
}

registry_insert :: proc(self: ^Registry($T), resource: T) -> int
{
    index, error := append(&self.values, resource)

    if error != nil {
        log.errorf("Unable to insert a resource\n")

        return 0
    }

    return index + 1
}

registry_remove :: proc(self: ^Registry($T), resource: int)
{
    assert(false, "Not implemented yet")
}

registry_clear :: proc(self: ^Registry($T))
{
    for &value in self.values {
        resource_clear(&self.resource, &value)
    }

    clear(&self.values)
}

registry_find :: proc(self: ^Registry($T), resource: int) -> ^T
{
    count := len(self.values)
    index := resource - 1

    if 0 <= index && index < count {
        return &self.values[index]
    }

    return nil
}

registry_read :: proc(self: ^Registry($T), names: []string) -> bool
{
    for name in names {
        value, state := resource_read(&self.resource, name)

        if state == false {
            return false
        }

        registry_insert(self, value)
    }

    return true
}

registry_write :: proc()
{
    assert(false, "Not implemented yet")
}
