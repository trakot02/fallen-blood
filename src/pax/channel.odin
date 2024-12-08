package pax

Handler :: struct ($T: typeid)
{
    instance: rawptr,

    handle_proc: proc(self: rawptr, event: T) -> bool,
}

Channel :: struct ($T: typeid)
{
    items: [dynamic]Handler(T),
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

channel_connect_proc :: proc(self: ^Channel($T), handler: proc(_: rawptr, _: T) -> bool)
{
    value := Handler(T) {
        instance = nil, handle_proc = handler,
    }

    append(&self.items, value)
}

channel_connect_pair :: proc(self: ^Channel($T), handler: proc(_: rawptr, _: T) -> bool, subject: rawptr)
{
    value := Handler(T) {
        instance = subject, handle_proc = handler,
    }

    append(&self.items, value)
}

channel_connect :: proc {
    channel_connect_full,
    channel_connect_proc,
    channel_connect_pair,
}

// TODO: disconnect stuff with linear search

channel_send :: proc(self: ^Channel($T), event: T) -> bool
{
    for handler in self.items {
        result := handler.handle_proc(handler.instance, event)

        if result == false {
            return result
        }
    }

    return true
}
