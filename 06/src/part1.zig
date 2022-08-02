const std = @import("std");
const rob = @import("rob.zig");
const assert = std.debug.assert;
const log = std.log.info;

pub fn main() anyerror!void {
    const file = try rob.File.loadFromPath("puzzle.txt");
    defer file.deinit();

    log("File data: {s}", .{file.bytes});

    // const input = file.bytes;
    const input = "3,4,3,1,2";

    var fish_list = std.ArrayList(i32).init(std.heap.page_allocator);
    defer fish_list.deinit();

    var num_iter = std.mem.split(u8, input, ",");
    while (num_iter.next()) |numStr| {
        const num = try std.fmt.parseInt(i32, numStr, 0);

        try fish_list.append(num);
    }

    log("Fishes: {any}", .{fish_list.items});

    // Simulate fishes.
    const total_days = 80;

    var day_iter: usize = 0;
    while (day_iter < total_days) : (day_iter += 1) {
        var last_len = fish_list.items.len;
        
        var fish_iter: usize = 0;
        var fish_iter_target: usize = fish_list.items.len;
        while (fish_iter < fish_iter_target) : (fish_iter += 1) {
            var fish_timer = fish_list.items[fish_iter];
            
            if (fish_timer > 0) {
                fish_timer -= 1;
            } else {
                fish_timer = 6;
                try fish_list.append(8);
            }

            fish_list.items[fish_iter] = fish_timer;
        }

        // log("Day {}: {any}", .{ day_iter + 1, fish_list.items });
        log("Day {}: Fishes: {}", .{ day_iter + 1, fish_list.items.len});
    }

    log("Total fishes: {}", .{fish_list.items.len});
}
