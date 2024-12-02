package pax

import "core:mem"

Load_Config :: enum
{
    SIMPLE,
    STORED,
}

Load_Error :: enum
{
    SOME,
}

Registry :: struct ($T: typeid)
{
    values: map[string]T,

    instance: rawptr,

    proc_create:  proc(self: rawptr),
    proc_destroy: proc(self: rawptr),
    proc_load:    proc(self: rawptr, name: string) -> (T, Load_Error),
    proc_unload:  proc(self: rawptr, name: string),
}

registry_create :: proc(self: ^Registry($T), allocator := context.allocator)
{
    self.values = make(map[string]T, allocator)

    self.proc_create(self.instance)
}

registry_destroy :: proc(self: ^Registry($T))
{
    self.proc_destroy(self.instance)

    delete(self.values)
}

registry_load :: proc(self: ^Registry($T), name: string, config: Load_Config = .STORED) -> (T, Load_Error)
{
    if config == .STORED && name in self.values {
        value, _ := self.values[name]

        return value, nil
    }

    value, error := self.proc_load(self.instance, name)

    if error == nil {
        self.values[name] = value
    }

    return value, error
}

registry_unload :: proc(self: ^Registry($T), name: string)
{
    value, state := self.values[name]

    if state == true {
        self.proc_unload(self.instance, value)
    }
}
