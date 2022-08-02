const std = @import("std");
const assert = std.debug.assert;
const log = std.log.info;
pub const log_level: std.log.Level = .info;
const rob = @import("rob.zig");

fn printGrid(grid: []u8, size: usize) void {
    var cell_iter: usize = 0;
    while (cell_iter < size * size) : (cell_iter += 1) {
        if (cell_iter / size != 0 and cell_iter % size == 0) {
            std.debug.print("\n", .{});
        }
        std.debug.print("{d: ^2} ", .{grid[cell_iter]});
    }

    std.debug.print("\n", .{});
}

inline fn incrementCell(grid: *u8) void {
    if (grid.* < 10) {
        grid.* += 1;
    }
}

pub fn main() anyerror!void {
    // const file = try rob.File.loadFromPath("example.txt");
    const file = try rob.File.loadFromPath("puzzle.txt");
    defer file.deinit();

    log("File size: {}", .{file.bytes.len});

    const grid_size: usize = 10;

    var grid: [grid_size * grid_size]u8 = undefined;

    var line_iter = std.mem.split(u8, file.bytes, "\r\n");
    var line_count: usize = 0;
    while (line_iter.next()) |lineStr| {
        assert(line_count < 10);
        assert(lineStr.len == 10);

        const grid_index: usize = line_count * grid_size;

        for (lineStr) |char, char_index| {
            grid[grid_index + char_index] = char - '0';
        }

        line_count += 1;
    }

    log("Initial:", .{});
    printGrid(&grid, grid_size);

    const sim_steps: usize = 100;
    var total_flashes: usize = 0;

    var sim_iter: usize = 0;
    while (sim_iter < sim_steps) : (sim_iter += 1) {

        // Increase all by 1.
        for (grid) |*cell| {
            cell.* += 1;
        }

        var step_flash_count: usize = 0;

        // Iterate the grid until there are no more 10s
        while (true) {
            var flash_count: usize = 0;

            for (grid) |*cell, cell_index| {
                if (cell.* == 10) {
                    // Initiate flash.
                    cell.* = 69;
                    flash_count += 1;

                    const x: usize = cell_index % grid_size;
                    const y: usize = cell_index / grid_size;

                    // 0 1 2
                    // 3 4 5
                    // 6 7 8

                    if (x > 0) {
                        // 0
                        if (y > 0) {
                            incrementCell(&grid[cell_index - grid_size - 1]);
                        }

                        // 3
                        incrementCell(&grid[cell_index - 1]);

                        // 6
                        if (y < grid_size - 1) {
                            incrementCell(&grid[cell_index + grid_size - 1]);
                        }
                    }

                    // 1
                    if (y > 0) {
                        incrementCell(&grid[cell_index - grid_size]);
                    }

                    // 7
                    if (y < grid_size - 1) {
                        incrementCell(&grid[cell_index + grid_size]);
                    }

                    if (x < grid_size - 1) {
                        // 0
                        if (y > 0) {
                            incrementCell(&grid[cell_index - grid_size + 1]);
                        }

                        // 3
                        incrementCell(&grid[cell_index + 1]);

                        // 6
                        if (y < grid_size - 1) {
                            incrementCell(&grid[cell_index + grid_size + 1]);
                        }
                    }
                }
            }

            if (flash_count == 0) {
                break;
            }

            step_flash_count += flash_count;
        }

        // Set all flashed to 0.
        for (grid) |cell, cell_index| {
            if (cell == 69) {
                grid[cell_index] = 0;
            }
        }

        total_flashes += step_flash_count;

        log("Step {}: {} {}", .{ sim_iter + 1, step_flash_count, total_flashes });
        // printGrid(&grid, grid_size);
    }

    log("Total flashes: {}", .{total_flashes});
}
