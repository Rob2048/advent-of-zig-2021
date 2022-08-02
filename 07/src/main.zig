const std = @import("std");
const rob = @import("rob.zig");
const assert = std.debug.assert;
const log = std.log.info;
pub const log_level: std.log.Level = .info;

pub fn main() anyerror!void {
    const file = try rob.File.loadFromPath("puzzle.txt");
    defer file.deinit();

    // const input = "16,1,2,0,4,2,7,1,2,14";
    const input = file.bytes;

    var crabs = std.ArrayList(i64).init(std.heap.page_allocator);
    defer crabs.deinit();

    var input_iter = std.mem.split(u8, input, ",");
    while (input_iter.next()) |numStr| {
        const pos = try std.fmt.parseInt(i64, numStr, 0);
        try crabs.append(pos);
    }

    std.sort.sort(i64, crabs.items, {}, comptime std.sort.asc(i64));

    const min_value = crabs.items[0];
    const max_value = crabs.items[crabs.items.len - 1];

    log("{any}", .{crabs.items});
    log("{} {}", .{ min_value, max_value });

    // Check every possible pos (This algo could be immediately improved with a binary search).
    var min_fuel: f64 = -1.0;
    var min_pos: usize = 0;

    var pos_iter: usize = @intCast(usize, min_value);
    var pos_end: usize = @intCast(usize, max_value);
    while (pos_iter <= pos_end) : (pos_iter += 1) {
        var total_fuel_cost: f64 = 0;

        for (crabs.items) |crab| {
            const steps: f64 = @intToFloat(f64, try std.math.absInt(@intCast(i64, pos_iter) - crab));
            const fuel_cost: f64 = (steps * 0.5 + 0.5) * steps;

            total_fuel_cost += fuel_cost;
        }

        if (total_fuel_cost < min_fuel or min_fuel == -1) {
            min_fuel = total_fuel_cost;
            min_pos = pos_iter;
        }

        log("Pos {}: {d:.3}", .{ pos_iter, total_fuel_cost });
    }

    log("Min pos: {} Min fuel: {d:.3}", .{ min_pos, min_fuel });
}
