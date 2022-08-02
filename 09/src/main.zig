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

    var marked_cells: []u8 = try allocator.alloc(u8, grid_width * grid_height);
    defer allocator.free(marked_cells);

    std.mem.set(u8, marked_cells, 0);

    var basins = std.ArrayList(usize).init(allocator);
    defer basins.deinit();

    var flood_stack = std.ArrayList(usize).init(allocator);
    defer flood_stack.deinit();

    for (heightmap.items) |cell, cell_index| {
        const flood_index: usize = cell_index;

        if (marked_cells[flood_index] == 1 or cell == 9) {
            continue;
        }

        try flood_stack.append(flood_index);
        
        var current_basin: usize = 0;
        
        while (flood_stack.items.len > 0) {
            const index = flood_stack.pop();
            // log("Flood {}", .{index});

            if (marked_cells[index] == 1) {
                continue;
            }

            // log("Process", .{});

            marked_cells[index] = 1;
            current_basin += 1;
            
            const x = index % grid_width;
            const y = index / grid_width;
            
            if (x > 0) {
                if (heightmap.items[index - 1] != 9) {
                    try flood_stack.append(index - 1);
                }
            }

            if (x < grid_width - 1) {
                if (heightmap.items[index + 1] != 9) {
                    try flood_stack.append(index + 1);
                }
            }

            if (y > 0) {
                if (heightmap.items[index - grid_width] != 9) {
                    try flood_stack.append(index - grid_width);
                }
            }

            if (y < grid_height - 1) {
                if (heightmap.items[index + grid_width] != 9) {
                    try flood_stack.append(index + grid_width);
                }
            }
        }

        try basins.append(current_basin);
    }

    log("Basin count: {}", .{basins.items.len});

    std.sort.sort(usize, basins.items, {}, comptime std.sort.asc(usize));

    for (basins.items) |basin, index| {
        log("Basin {} size: {}", .{index, basin});
    }

    var final_value = basins.pop() * basins.pop() * basins.pop();

    log("Final value: {}", .{final_value});
}
