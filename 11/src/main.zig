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

inline fn incrementCell(grid: []u8, x: isize, y: isize, grid_size: isize) void {
    if (x < 0 or x >= grid_size or y < 0 or y >= grid_size) {
        return;
    }

    const cell_index = y * grid_size + x;
    var cell = &grid[@intCast(usize, cell_index)];

    if (cell.* < 10) {
        cell.* += 1;
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

    var total_flashes: usize = 0;

    var sim_iter: usize = 0;
    while (true) : (sim_iter += 1) {

        // Increase all by 1.
        for (grid) |*cell| {
            cell.* += 1;
        }

        var step_flash_count: usize = 0;

        // Iterate the grid until there are no more 10s.
        while (true) {
            var flash_count: usize = 0;

            for (grid) |*cell, cell_index| {
                if (cell.* == 10) {
                    // Initiate flash.
                    cell.* = 69;
                    flash_count += 1;

                    const x: isize = @intCast(isize, cell_index % grid_size);
                    const y: isize = @intCast(isize, cell_index / grid_size);
                    const s_gs: isize = @intCast(isize, grid_size);

                    incrementCell(&grid, x - 1, y - 1, s_gs);
                    incrementCell(&grid, x, y - 1, s_gs);
                    incrementCell(&grid, x + 1, y - 1, s_gs);

                    incrementCell(&grid, x - 1, y, s_gs);
                    incrementCell(&grid, x + 1, y, s_gs);

                    incrementCell(&grid, x - 1, y + 1, s_gs);
                    incrementCell(&grid, x, y + 1, s_gs);
                    incrementCell(&grid, x + 1, y + 1, s_gs);
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

        if (step_flash_count == grid_size * grid_size) {
            log("All flashed on step {}", .{sim_iter + 1});
            break;
        }
        // printGrid(&grid, grid_size);
    }

    log("Total flashes: {}", .{total_flashes});
}
