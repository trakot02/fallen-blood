package pax

import "core:mem"

Resource :: struct
{
    name: string,
    path: string,
}

Registry_Item :: struct ($T: typeid)
{
    path:  string,
    value: T,
}

Registry :: struct ($T: typeid)
{
    table: map[string]Registry_Item(T),

    instance: rawptr,

    proc_create:  proc(self: rawptr),
    proc_destroy: proc(self: rawptr),
    proc_load:    proc(self: rawptr, name: string) -> (T, bool),
    proc_unload:  proc(self: rawptr, name: string),
}

registry_create :: proc(self: ^Registry($T), allocator := context.allocator)
{
    self.table = make(map[string]Registry_Item(T),
        allocator)

    self.proc_create(self.instance)
}

registry_destroy :: proc(self: ^Registry($T))
{
    self.proc_destroy(self.instance)

    delete(self.table)
}

registry_load :: proc(self: ^Registry($T), resource: Resource) -> bool
{
    value, state := self.proc_load(self.instance, resource.path)

    if state == true {
        self.table[resource.name] = {resource.path, value}
    }

    return state
}

registry_find :: proc(self: ^Registry($T), name: string) -> ^T
{
    item, state := &self.table[name]

    if state == true {
        return &item.value
    }

    return nil
}

registry_unload :: proc(self: ^Registry($T), name: string)
{
    item, state := &self.table[name]

    if state == true {
        self.proc_unload(self.instance, name)

        delete_key(&self.table, name)
    }
}
