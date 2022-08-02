const std = @import("std");
const rob = @import("rob.zig");
const log = std.log.info;
const assert = std.debug.assert;

const Vec3 = struct {
    x: i64 = 0,
    y: i64 = 0,
    z: i64 = 0,

    pub fn set(self: *Vec3, index: usize, value: i64) void {
        @ptrCast(*[3]i64, self)[index] = value;
    }
};

const Rule = struct {
    value: u8 = 0,
    min: Vec3 = Vec3{},
    max: Vec3 = Vec3{},
};

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    // const file = try rob.File.loadFromPath("example.txt");
    const file = try rob.File.loadFromPath("puzzle.txt");
    defer file.deinit();

    log("File size: {}", .{file.bytes.len});

    var rules = std.ArrayList(Rule).init(allocator);
    defer rules.deinit();

    var line_iter = std.mem.split(u8, file.bytes, "\r\n");
    while (line_iter.next()) |line| {
        var section_iter = std.mem.split(u8, line, " ");

        const on_off = section_iter.next().?;
        // log("{s}", .{on_off});

        const coords = section_iter.next().?;

        var rule = Rule{
            .value = if (on_off[1] == 'n') 1 else 0,
        };

        var coords_iter = std.mem.split(u8, coords, ",");
        while (coords_iter.next()) |coord| {
            const coord_id: u8 = coord[0] - 'x';
            var num_iter = std.mem.split(u8, coord[2..], "..");
            const min = try std.fmt.parseInt(i64, num_iter.next().?, 10);
            const max = try std.fmt.parseInt(i64, num_iter.next().?, 10);

            // log("{s} {} {} {}", .{ coord, coord_id, min, max });
            rule.min.set(coord_id, min);
            rule.max.set(coord_id, max);
        }

        try rules.append(rule);
    }

    // log("Rules: {any}", .{rules.items});

    const grid_size: usize = 102;
    const grid_total_cells = grid_size * grid_size * grid_size;
    var grid = try allocator.alloc(u8, grid_total_cells);
    defer allocator.free(grid);

    std.mem.set(u8, grid, 0);

    // Apply all the rules.
    for (rules.items) |rule| {
        if (rule.max.x < -50 or rule.max.y < -50 or rule.max.z < -50 or rule.min.x > 50 or rule.min.y > 50 or rule.min.z > 50) {
            continue;
        }

        const min = Vec3{
            .x = rule.min.x + 50,
            .y = rule.min.y + 50,
            .z = rule.min.z + 50,
        };

        const max = Vec3{
            .x = rule.max.x + 50,
            .y = rule.max.y + 50,
            .z = rule.max.z + 50,
        };

        log("RULE: {any} {any}", .{ rule.min, rule.max });
        log("MINM: {any} {any}", .{ min, max });
        log("", .{});

        var x_iter = min.x;
        while (x_iter <= max.x) : (x_iter += 1) {
            var y_iter = min.y;
            while (y_iter <= max.y) : (y_iter += 1) {
                var z_iter = min.z;
                while (z_iter <= max.z) : (z_iter += 1) {
                    const index = x_iter + (y_iter * grid_size) + (z_iter * grid_size * grid_size);
                    // log("{} {} {}", .{x_iter, y_iter, z_iter});
                    grid[@intCast(usize, index)] = rule.value;
                }
            }
        }
    }

    // Count cells that are on.
    var on_cells: usize = 0;
    for (grid) |cell| {
        on_cells += cell;
    }
    log("On cells: {}", .{on_cells});
}
