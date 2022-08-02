// NOTE: Run in release-fast or you will be here forever ;D.

const std = @import("std");
const rob = @import("rob.zig");
const assert = std.debug.assert;
const log = std.log.info;
pub const log_level: std.log.Level = .info;

pub fn main() anyerror!void {
    const file = try rob.File.loadFromPath("puzzle.txt");
    defer file.deinit();

    log("File data: {s}", .{file.bytes});

    const input = file.bytes;
    // const input = "3,4,3,1,2";
    
    // NOTE: Consumes 8GB of RAM ;D.
    const fish_size_max: usize = 8_000_000_000;

    log("Alloc start...", .{});
    var fish_list: []u8 = try std.heap.page_allocator.alloc(u8, fish_size_max);
    defer std.heap.page_allocator.free(fish_list);
    log("Alloc done", .{});
    var fish_list_size: usize = 0;

    var input_list = std.ArrayList(u8).init(std.heap.page_allocator);
    defer input_list.deinit();

    var num_iter = std.mem.split(u8, input, ",");
    while (num_iter.next()) |numStr| {
        const num = try std.fmt.parseInt(u8, numStr, 0);

        try input_list.append(num);
    }

    // Simulate fishes.
    fish_list[0] = 0;
    fish_list_size = 1;

    const total_days = 256;

    var last_days_of_fish: [8]usize = undefined;

    var day_iter: usize = 0;
    while (day_iter < total_days) : (day_iter += 1) {
        var fish_iter: usize = 0;
        var fish_iter_target: usize = fish_list_size;
        while (fish_iter < fish_iter_target) : (fish_iter += 1) {
            var fish_timer = fish_list[fish_iter];

            if (fish_timer > 0) {
                fish_timer -= 1;
            } else {
                fish_timer = 6;
                fish_list[fish_list_size] = 8;
                fish_list_size += 1;
                assert(fish_list_size < fish_size_max);
            }

            fish_list[fish_iter] = fish_timer;
        }

        if (day_iter >= total_days - 8) {
            last_days_of_fish[day_iter - (total_days - 8)] = fish_list_size;
        }

        log("Day {}: Fishes: {}", .{ day_iter + 1, fish_list_size });
    }

    log("Last days: {any}", .{last_days_of_fish});

    var final_count: usize = 0;

    for (input_list.items) |item| {
        final_count += last_days_of_fish[7 - item];
    }

    log("Total fishes: {}", .{final_count});
}
