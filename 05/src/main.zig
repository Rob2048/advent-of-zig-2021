const std = @import("std");
const assert = std.debug.assert;
const log = std.log.info;

const Line = struct {
    x1: i32 = 0,
    y1: i32 = 0,
    x2: i32 = 0,
    y2: i32 = 0,
};

pub fn main() anyerror!void {
    log("Hello world", .{});

    const file = try std.fs.cwd().openFile("puzzle.txt", .{ .mode = std.fs.File.OpenMode.read_only });
    defer file.close();
    const file_reader = file.reader();
    const file_bytes = try file_reader.readAllAlloc(std.heap.page_allocator, std.math.maxInt(usize));
    defer std.heap.page_allocator.free(file_bytes);

    log("File size: {}", .{file_bytes.len});

    var world_map = std.AutoHashMap(u32, u32).init(std.heap.page_allocator);
    defer world_map.deinit();

    var lines = std.ArrayList(Line).init(std.heap.page_allocator);
    defer lines.deinit();

    var line_iter = std.mem.split(u8, file_bytes, "\r\n");

    var total_adds: u32 = 0;

    while (line_iter.next()) |file_line| {
        log("Line {s}", .{file_line});

        var line = Line{};

        var point_iter = std.mem.split(u8, file_line, " -> ");
        if (point_iter.next()) |point| {
            log("Point 1: {s}", .{point});
            var num_iter = std.mem.split(u8, point, ",");

            if (num_iter.next()) |num| {
                line.x1 = try std.fmt.parseInt(i32, num, 0);
            }

            if (num_iter.next()) |num| {
                line.y1 = try std.fmt.parseInt(i32, num, 0);
            }
        }

        if (point_iter.next()) |point| {
            log("Point 2: {s}", .{point});
            var num_iter = std.mem.split(u8, point, ",");

            if (num_iter.next()) |num| {
                line.x2 = try std.fmt.parseInt(i32, num, 0);
            }

            if (num_iter.next()) |num| {
                line.y2 = try std.fmt.parseInt(i32, num, 0);
            }
        }

        log("Line: {any}", .{line});

        try lines.append(line);

        var curr_x: i32 = line.x1;
        var curr_y: i32 = line.y1;

        var x_inc: i32 = 0;
        var y_inc: i32 = 0;

        if (line.x2 - line.x1 > 0) {
            x_inc = 1;
        } else if (line.x2 - line.x1 < 0) {
            x_inc = -1;
        }

        if (line.y2 - line.y1 > 0) {
            y_inc = 1;
        } else if (line.y2 - line.y1 < 0) {
            y_inc = -1;
        }

        while (true) {
            const key: u32 = @intCast(u32, curr_x * 10000 + curr_y);
            if (world_map.get(key)) |value| {
                try world_map.put(key, value + 1);
            } else {
                try world_map.put(key, 1);
            }

            total_adds += 1;

            if (curr_x == line.x2 and curr_y == line.y2) {
                break;
            }

            curr_x += x_inc;
            curr_y += y_inc;
        }
    }

    log("Line count: {} {}", .{ lines.items.len, total_adds });

    var point_overlap_count: u32 = 0;

    var map_iter = world_map.iterator();
    while (map_iter.next()) |value| {
        const point_value = value.value_ptr.*;
        
        if (point_value >= 2) {
            point_overlap_count += 1;
        }
    }

    log("Point overlaps: {}", .{point_overlap_count});
}
