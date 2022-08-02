const std = @import("std");
const rob = @import("rob.zig");
const log = std.log.info;
const assert = std.debug.assert;

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    // const file = try rob.File.loadFromPath("example.txt");
    const file = try rob.File.loadFromPath("puzzle.txt");
    defer file.deinit();

    log("File size: {}", .{file.bytes.len});

    var line_iter = std.mem.split(u8, file.bytes, "\r\n");

    const algo_str = line_iter.next().?;

    var algo: [512]u8 = undefined;
    assert(algo_str.len == 512);
    for (algo_str) |char, index| {
        algo[index] = if (char == '.') 0 else 1;
    }

    // Skip empty line.
    _ = line_iter.next().?;

    var starting_grid_size: usize = 0;
    var starting_grid_mem: ?[]u8 = null;
    defer if (starting_grid_mem) |grid| allocator.free(grid);

    var line_index: usize = 0;
    while (line_iter.next()) |line| {
        if (starting_grid_size == 0) {
            starting_grid_size = line.len;
            starting_grid_mem = try allocator.alloc(u8, starting_grid_size * starting_grid_size);
        }

        assert(starting_grid_size == line.len);

        for (line) |char, index| {
            starting_grid_mem.?[index + line_index * starting_grid_size] = char;
        }

        line_index += 1;
    }

    log("String grid size: {}", .{starting_grid_size});

    const starting_grid = starting_grid_mem.?;

    // Create starting grid with double padding.
    var grid_size = starting_grid_size + 4;
    var grid = try allocator.alloc(u8, grid_size * grid_size);
    std.mem.set(u8, grid, 0);
    defer allocator.free(grid);

    for (starting_grid) |char, index| {
        const src_x = index % starting_grid_size;
        const src_y = index / starting_grid_size;

        const dst_x = src_x + 2;
        const dst_y = src_y + 2;
        const dst_index = dst_x + dst_y * grid_size;

        grid[dst_index] = if (char == '.') 0 else 1;
    }

    drawGrid(grid, grid_size);
    log("Start enhancement:", .{});

    const enchance_step_count: usize = 50;

    var infinity_value: u8 = 0;

    // Perform an enhancement step
    var step_iter: usize = 0;
    while (step_iter < enchance_step_count) : (step_iter += 1) {
        var set_count: usize = 0;

        const scratch_size = grid_size + 2;
        var scratch_grid = try allocator.alloc(u8, scratch_size * scratch_size);

        infinity_value = algo[@as(usize, infinity_value) * 511];
        std.mem.set(u8, scratch_grid, infinity_value);
        
        var y_iter: usize = 1;
        while (y_iter < grid_size - 1) : (y_iter += 1) {
            var x_iter: usize = 1;
            while (x_iter < grid_size - 1) : (x_iter += 1) {
                const src_index = x_iter + y_iter * grid_size;
                const dst_index = x_iter + 1 + (y_iter + 1) * scratch_size;

                const b0: usize = grid[src_index - grid_size - 1];
                const b1: usize = grid[src_index - grid_size + 0];
                const b2: usize = grid[src_index - grid_size + 1];

                const b3: usize = grid[src_index - 1];
                const b4: usize = grid[src_index + 0];
                const b5: usize = grid[src_index + 1];

                const b6: usize = grid[src_index + grid_size - 1];
                const b7: usize = grid[src_index + grid_size + 0];
                const b8: usize = grid[src_index + grid_size + 1];

                const algo_index: usize = (b0 << 8) | (b1 << 7) | (b2 << 6) | (b3 << 5) | (b4 << 4) | (b5 << 3) | (b6 << 2) | (b7 << 1) | (b8 << 0);

                if (algo[algo_index] == 1) {
                    // NOTE: Ignores changes to the rest of the infinite grid.
                    set_count += 1;
                }

                scratch_grid[dst_index] = algo[algo_index];
            }
        }

        allocator.free(grid);
        grid_size = scratch_size;
        grid = scratch_grid;

        // drawGrid(grid, grid_size);
        log("Set count: {}", .{set_count});
    }
}

fn drawGrid(grid: []const u8, size: usize) void {
    for (grid) |cell, index| {
        const x = index % size;
        const y = index / size;

        if (x == 0 and y > 0) {
            std.debug.print("\n", .{});
        }

        const output: u8 = if (cell == 0) '.' else '#';
        std.debug.print("{c}", .{output});
    }

    std.debug.print("\n", .{});
}
