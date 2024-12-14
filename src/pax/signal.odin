package pax

import "core:log"

Empty_Event :: struct {}

Listener :: struct
{
    instance:  rawptr,
    proc_call: rawptr,
}

Signal :: struct ($T: typeid)
{
    chain: [dynamic]Listener,
}

signal_init :: proc(self: ^Signal($T), allocator := context.allocator)
{
    self.chain = make([dynamic]Listener, allocator)
}

signal_destroy :: proc(self: ^Signal($T))
{
    delete(self.chain)
}

signal_insert_proc :: proc(self: ^Signal($T), call: proc(T)) -> bool
{
    _, error := append(&self.chain, Listener {
        proc_call = auto_cast call,
    })

    if error != nil {
        log.errorf("Unable to connect to a signal\n")
    }

    return error == nil
}

signal_insert_proc_empty :: proc(self: ^Signal(Empty_Event), call: proc()) -> bool
{
    _, error := append(&self.chain, Listener {
        proc_call = auto_cast call,
    })

    if error != nil {
        log.errorf("Unable to connect to a signal\n")
    }

    return error == nil
}

signal_insert_pair :: proc(self: ^Signal($T), instance: ^$U, call: proc(T, ^U)) -> bool
{
    _, error := append(&self.chain, Listener {
        instance  = auto_cast instance,
        proc_call = auto_cast call,
    })

    if error != nil {
        log.errorf("Unable to connect to a signal\n")
    }

    return error == nil
}

signal_insert_pair_empty :: proc(self: ^Signal(Empty_Event), instance: ^$U, call: proc(^U)) -> bool
{
    _, error := append(&self.chain, Listener {
        instance  = auto_cast instance,
        proc_call = auto_cast call,
    })

    if error != nil {
        log.errorf("Unable to connect to a signal\n")
    }

    return error == nil
}

signal_insert :: proc {
    signal_insert_proc,
    signal_insert_proc_empty,
    signal_insert_pair,
    signal_insert_pair_empty,
}

signal_remove_proc :: proc(self: ^Signal($T), call: proc(T))
{
    for value, index in self.chain {
        if value.proc_call == rawptr(call) {
            unordered_remove(&self.chain, index)

            return
        }
    }
}

signal_remove_proc_empty :: proc(self: ^Signal(Empty_Event), call: proc())
{
    for value, index in self.chain {
        if value.proc_call == rawptr(call) {
            unordered_remove(&self.chain, index)

            return
        }
    }
}

signal_remove_pair :: proc(self: ^Signal($T), instance: ^$U, call: proc(T, ^U))
{
    for value, index in self.chain {
        if value.proc_call == rawptr(call) &&
           value.instance  == rawptr(instance) {
            unordered_remove(&self.chain, index)

            return
        }
    }
}

signal_remove_pair_empty :: proc(self: ^Signal(Empty_Event), instance: ^$U, call: proc(^U))
{
    for value, index in self.chain {
        if value.proc_call == rawptr(call) &&
           value.instance  == rawptr(instance) {
            unordered_remove(&self.chain, index)

            return
        }
    }
}

signal_remove :: proc {
    signal_remove_proc,
    signal_remove_proc_empty,
    signal_remove_pair,
    signal_remove_pair_empty,
}

signal_emit_event :: proc(self: ^Signal($T), event: T)
{
    Type :: proc(T, rawptr)

    for value in self.chain {
        Type(value.proc_call)(event, value.instance)
    }
}

signal_emit_empty :: proc(self: ^Signal(Empty_Event))
{
    Type :: proc(rawptr)

    for value in self.chain {
        Type(value.proc_call)(value.instance)
    }
}

signal_emit :: proc {
    signal_emit_event,
    signal_emit_empty,
}
