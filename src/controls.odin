package main

Controls :: struct
{
    east:  bool,
    north: bool,
    west:  bool,
    south: bool,
}

controls_angle :: proc(self: ^Controls) -> [2]int
{
    return {
        int(self.east)  - int(self.west),
        int(self.south) - int(self.north),
    }
}
