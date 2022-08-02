const std = @import("std");
const rob = @import("rob.zig");
const assert = std.debug.assert;
const log = std.log.info;

pub fn main() anyerror!void {
    var pos = std.ArrayList(i64).init(std.heap.page_allocator);
    defer pos.deinit();

    // NOTE: Puzzle input:
    // target area: x=135..155, y=-102..-78

    // If you can hit target on x velocity = 0 then:
    // Max y velocity = -(bottom of target) - 1

    //var velocity_x: i64 = 16;
    var velocity_x: i64 = 17;
    
    var velocity_y: i64 = 101;

    var pos_x: i64 = 0;
    var pos_y: i64 = 0;

    var max_steps: usize = 30;
    while (max_steps > 0) : (max_steps -= 1) {
        try pos.append(pos_x);
        pos_x += velocity_x;

        if (velocity_x > 0) {
            velocity_x -= 1;
        }
    }

    pos.clearRetainingCapacity();

    var highest_y: i64 = 0;

    max_steps = 1000;
    while (max_steps > 0) : (max_steps -= 1) {
        try pos.append(pos_y);
        pos_y += velocity_y;
        highest_y = std.math.max(highest_y, pos_y);
        velocity_y -= 1;
    }

    log("Pos: {any}", .{pos.items});

    log("Highest y: {}", .{highest_y});
}
