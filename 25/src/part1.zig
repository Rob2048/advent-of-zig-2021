const std = @import("std");
const rob = @import("rob.zig");
const log = std.log.info;
const assert = std.debug.assert;
pub const log_level: std.log.Level = .info;

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    // const file = try rob.File.loadFromPath("example.txt");
    const file = try rob.File.loadFromPath("puzzle.txt");
    defer file.deinit();

    var grid: []u8 = undefined;
    defer allocator.free(grid);

    var grid_width: usize = 0;
    var grid_height: usize = 0;

    var line_iter = std.mem.split(u8, file.bytes, "\r\n");
    var line_count: usize = 0;
    while (line_iter.next()) |line| {
        if (grid_width == 0) {
            grid_width = line.len;
            grid_height = (file.bytes.len + grid_width + 1) / (grid_width + 2);
            log("{} {}", .{ grid_width, grid_height });

            grid = try allocator.alloc(u8, grid_width * grid_height);
        }

        // log("{s}", .{line});

        // 0 = blank
        // 1 = >
        // 2 = v

        for (line) |char, index| {
            const grid_index = index + line_count * grid_width;
            switch (char) {
                '.' => grid[grid_index] = 0,
                '>' => grid[grid_index] = 1,
                'v' => grid[grid_index] = 2,
                else => unreachable,
            }
        }

        line_count += 1;
    }

    // log("{any}", .{grid});
    // printGrid(grid, grid_width, grid_height);

    var scratch_grid = try allocator.alloc(u8, grid_width * grid_height);
    defer allocator.free(scratch_grid);
    std.mem.set(u8, scratch_grid, 0);

    var step_iter: usize = 0;
    while (true) : (step_iter += 1) {
        var move_count: usize = 0;

        // Run a simulation step.
        var y_iter: usize = 0;
        while (y_iter < grid_height) : (y_iter += 1) {
            var x_iter: usize = 0;
            while (x_iter < grid_width) : (x_iter += 1) {
                const src_index = x_iter + y_iter * grid_width;
                const dst_index = (x_iter + 1) % grid_width + y_iter * grid_width;

                if (grid[src_index] == 1) {
                    // East boi.
                    if (grid[dst_index] == 0) {
                        scratch_grid[dst_index] = 1;
                        move_count += 1;
                    } else {
                        scratch_grid[src_index] = 1;
                    }
                } else if (grid[src_index] == 2) {
                    // South boi.
                    scratch_grid[src_index] = 2;
                }
            }
        }

        var temp_grid = grid;
        grid = scratch_grid;
        scratch_grid = temp_grid;
        std.mem.set(u8, scratch_grid, 0);

        y_iter = 0;
        while (y_iter < grid_height) : (y_iter += 1) {
            var x_iter: usize = 0;
            while (x_iter < grid_width) : (x_iter += 1) {
                const src_index = x_iter + y_iter * grid_width;
                const dst_index = x_iter + ((y_iter + 1) % grid_height) * grid_width;

                if (grid[src_index] == 1) {
                    // East boi.
                    scratch_grid[src_index] = 1;
                } else if (grid[src_index] == 2) {
                    // South boi.
                    if (grid[dst_index] == 0) {
                        scratch_grid[dst_index] = 2;
                        move_count += 1;
                    } else {
                        scratch_grid[src_index] = 2;
                    }
                }
            }
        }

        temp_grid = grid;
        grid = scratch_grid;
        scratch_grid = temp_grid;
        std.mem.set(u8, scratch_grid, 0);

        std.debug.print("Step: {} Moves: {}\n", .{step_iter + 1, move_count});
        // printGrid(grid, grid_width, grid_height);

        if (move_count == 0) {
            break;
        }
    }
}

fn printGrid(grid: []const u8, grid_width: usize, grid_height: usize) void {
    _ = grid_height;

    for (grid) |cell, index| {
        const char = if (cell == 0) @as(u8, '.') else if (cell == 1) @as(u8, '>') else @as(u8, 'v');

        if (index != 0 and index % grid_width == 0) {
            std.debug.print("\n", .{});
        }
        std.debug.print("{c}", .{char});
    }
    std.debug.print("\n", .{});
}
