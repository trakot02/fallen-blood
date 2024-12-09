package pax

Handler :: struct ($T: typeid)
{
    instance:  rawptr,
    call_proc: proc(self: rawptr, event: T) -> bool,
}

handler_init_proc :: proc(procedure: proc(_: rawptr, _: $T) -> bool) -> Handler(T)
{
    value := Handler(T) {}

    value.call_proc = procedure

    return value
}

handler_init_pair :: proc(procedure: proc(_: rawptr, _: $T) -> bool, instance: rawptr) -> Handler(T)
{
    value := Handler(T) {}

    value.instance  = instance
    value.call_proc = procedure

    return value
}

Channel :: struct ($T: typeid)
{
    items: [dynamic]Handler(T),
}

handler_call :: proc(self: ^Handler($T), value: T) -> bool
{
    return self.call_proc(self.instance, value)
}

channel_init :: proc(self: ^Channel($T), allocator := context.allocator)
{
    self.items = make([dynamic]Handler(T), allocator)
}

channel_destroy :: proc(self: ^Channel($T))
{
    delete(self.items)
}

channel_connect_full :: proc(self: ^Channel($T), handler: Handler(T))
{
    append(&self.items, handler)
}

channel_connect_proc :: proc(self: ^Channel($T), procedure: proc(_: rawptr, _: T) -> bool)
{
    append(&self.items, handler_init_proc(procedure))
}

channel_connect_pair :: proc(self: ^Channel($T), procedure: proc(_: rawptr, _: T) -> bool, instance: rawptr)
{
    append(&self.items, handler_init_pair(procedure, instance))
}

channel_connect :: proc {
    channel_connect_full,
    channel_connect_proc,
    channel_connect_pair,
}

// TODO: disconnect stuff with linear search

channel_send :: proc(self: ^Channel($T), event: T) -> bool
{
    for &handler in self.items {
        result := handler_call(&handler, event)

        if result == false {
            return result
        }
    }

    return true
}
