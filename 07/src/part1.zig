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

    // Get median.
    std.sort.sort(i64, crabs.items, {}, comptime std.sort.asc(i64));

    var median: i64 = 0;

    if (crabs.items.len % 2 == 0) {
        const midpoint = crabs.items.len / 2;
        log("{} Even {}", .{crabs.items.len, midpoint});
        median = crabs.items[midpoint - 1] + crabs.items[midpoint];
        median = @divTrunc(median, 2);
    } else {
        const midpoint = crabs.items.len / 2;
        log("{} Odd {}", .{crabs.items.len, midpoint});
        median = crabs.items[midpoint];
    }

    log("{any} {}", .{crabs.items, median});

    // Fuel costs.
    var total_fuel_cost: i64 = 0;
    for (crabs.items) |crab| {
        total_fuel_cost += try std.math.absInt(crab - median);
    }

    log("Total fuel: {}", .{total_fuel_cost});
}
