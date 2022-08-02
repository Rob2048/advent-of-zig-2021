const std = @import("std");
const assert = std.debug.assert;
const rob = @import("rob.zig");
const log = std.log.info;
pub const log_level: std.log.Level = .info;

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    // const file = try rob.File.loadFromPath("example.txt");
    const file = try rob.File.loadFromPath("puzzle.txt");
    defer file.deinit();
    const input = file.bytes;

    var heightmap = std.ArrayList(u8).init(allocator);
    defer heightmap.deinit();
    var grid_width: usize = 0;
    var grid_height: usize = 0;

    var line_iter = std.mem.split(u8, input, "\r\n");
    while (line_iter.next()) |lineStr| {
        assert(lineStr.len != 0);

        if (grid_width == 0) {
            grid_width = lineStr.len;
        }

        assert(grid_width == lineStr.len);

        for (lineStr) |char| {
            const height = char - '0';
            try heightmap.append(height);
            // log("{d}", .{height});
        }

        grid_height += 1;
    }

    log("Grid size: {} {}", .{ grid_width, grid_height });

    var low_sum: i64 = 0;

    // Find low points
    for (heightmap.items) |height, index| {
        const x = index % grid_width;
        const y = index / grid_width;

        var min_height: u8 = std.math.maxInt(u8);

        if (x > 0) {
            min_height = std.math.min(min_height, heightmap.items[index - 1]);
        }

        if (x < grid_width - 1) {
            min_height = std.math.min(min_height, heightmap.items[index + 1]);
        }

        if (y > 0) {
            min_height = std.math.min(min_height, heightmap.items[index - grid_width]);
        }

        if (y < grid_height - 1) {
            min_height = std.math.min(min_height, heightmap.items[index + grid_width]);
        }

        if (height < min_height) {
            low_sum += height + 1;
            log("{} {} {} *", .{ height, x, y });
        } else {
            log("{} {} {}", .{ height, x, y });
        }
    }

    log("Lowest point sum: {}", .{low_sum});
}
