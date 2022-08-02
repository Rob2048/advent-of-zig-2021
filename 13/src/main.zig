const std = @import("std");
const assert = std.debug.assert;
const rob = @import("rob.zig");
const log_level: std.log.Level = .info;
const log = std.log.info;

const Vec2 = struct {
    x: usize = 0,
    y: usize = 0,
};

const Instruction = struct {
    const Direction = enum {
        x,
        y,
    };

    direction: Direction,
    position: usize = 0,
};

pub fn main() anyerror!void {
    // const file = try rob.File.loadFromPath("example.txt");
    const file = try rob.File.loadFromPath("puzzle.txt");
    defer file.deinit();

    log("File size: {}", .{file.bytes.len});

    var points = std.ArrayList(Vec2).init(std.heap.page_allocator);
    defer points.deinit();

    var instructions = std.ArrayList(Instruction).init(std.heap.page_allocator);
    defer instructions.deinit();

    var section_iter = std.mem.split(u8, file.bytes, "\r\n\r\n");
    if (section_iter.next()) |section| {
        var line_iter = std.mem.split(u8, section, "\r\n");
        while (line_iter.next()) |line| {
            // log("SectionA: {s}", .{line});

            var num_iter = std.mem.split(u8, line, ",");
            const x = try std.fmt.parseInt(usize, num_iter.next().?, 0);
            const y = try std.fmt.parseInt(usize, num_iter.next().?, 0);

            try points.append(Vec2{
                .x = x,
                .y = y,
            });
        }
    }

    if (section_iter.next()) |section| {
        var line_iter = std.mem.split(u8, section, "\r\n");
        while (line_iter.next()) |line| {
            // log("SectionB: {s}", .{line});

            var num_iter = std.mem.split(u8, line, "=");
            const direction_str = num_iter.next().?;
            const value = try std.fmt.parseInt(usize, num_iter.next().?, 0);

            try instructions.append(Instruction{
                .direction = if (std.mem.eql(u8, direction_str, "fold along x"))
                    Instruction.Direction.x
                else
                    Instruction.Direction.y,
                .position = value,
            });
        }
    }

    // log("Instructions: {any}", .{instructions.items});

    for (instructions.items) |instruction| {
        const target_instruction = instruction;

        var point_iter: usize = 0;
        while (point_iter < points.items.len) {
            const point = &points.items[point_iter];
            point_iter += 1;

            var modified_point: bool = false;

            if (target_instruction.direction == Instruction.Direction.y and point.y > target_instruction.position) {
                point.y = (target_instruction.position * 2) - point.y;
                modified_point = true;
            } else if (target_instruction.direction == Instruction.Direction.x and point.x > target_instruction.position) {
                point.x = (target_instruction.position * 2) - point.x;
                modified_point = true;
            }

            if (modified_point) {
                // Determine if point already exists.
                const found_point = for (points.items) |*check_point| {
                    if (check_point != point and check_point.x == point.x and check_point.y == point.y) {
                        break true;
                    }
                } else false;

                if (found_point) {
                    point_iter -= 1;
                    _ = points.swapRemove(point_iter);
                }
            }
        }

        log("Remaining points: {}", .{points.items.len});
    }

    var max_x: usize = 0;
    var max_y: usize = 0;

    for (points.items) |point| {
        max_x = std.math.max(max_x, point.x + 1);
        max_y = std.math.max(max_y, point.y + 1);
    }

    log("Max grid size: {}, {}", .{max_x, max_y});

    var grid = try std.heap.page_allocator.alloc(u8, max_x * max_y);
    defer std.heap.page_allocator.free(grid);
    std.mem.set(u8, grid, ' ');

    for (points.items) |point| {
        grid[point.y * max_x + point.x] = '#';
    }

    for (grid) |cell, index| {
        if (index % max_x == 0) {
            std.debug.print("\n", .{});
        }
        std.debug.print("{c}", .{cell});
        
    }
}
