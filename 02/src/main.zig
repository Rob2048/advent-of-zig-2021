const std = @import("std");
const assert = std.debug.assert;
const log = std.log.info;

fn getFileBytes(file_path: []const u8) ![]u8 {
    const file = try std.fs.cwd().openFile(file_path, .{ .mode = std.fs.File.OpenMode.read_only });
    defer file.close();

    try file.seekFromEnd(0);
    const file_size = try file.getPos();
    try file.seekTo(0);

    std.log.info("File size: {}", .{file_size});

    var file_bytes = try std.heap.page_allocator.alloc(u8, file_size);

    const bytes_read = try file.readAll(file_bytes);
    assert(bytes_read == file_size);

    return file_bytes;
}

fn freeFileBytes(file_bytes: []u8) void {
    std.heap.page_allocator.free(file_bytes);
}

pub fn main() anyerror!void {
    const file_bytes = try getFileBytes("puzzle.txt");
    defer freeFileBytes(file_bytes);

    std.log.info("File size: {}", .{file_bytes.len});

    var horz: i32 = 0;
    var depth: i32 = 0;
    var aim: i32 = 0;

    var line_iter = std.mem.split(u8, file_bytes, "\r\n");

    while (line_iter.next()) |line| {
        log("Line: {s}", .{line});

        var param_iter = std.mem.split(u8, line, " ");

        var direction: []const u8 = undefined;
        var units: i32 = undefined;

        if (param_iter.next()) |param| {
            direction = param;
        } else {
            return error.Overflow;
        }

        if (param_iter.next()) |param| {
            units = try std.fmt.parseInt(i32, param, 0);
        } else {
            return error.Overflow;
        }

        log("Direction: \"{s}\" Units: {}", .{ direction, units });

        if (std.mem.eql(u8, direction, "forward")) {
            horz += units;
            depth += aim * units;
        } else if (std.mem.eql(u8, direction, "down")) {
            aim += units;
        } else if (std.mem.eql(u8, direction, "up")) {
            aim -= units;
        } else {
            unreachable;
        }
    }

    const final_value = horz * depth;
    log("Horz: {} Depth: {} Final: {}", .{ horz, depth, final_value });
}
