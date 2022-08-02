const std = @import("std");
const assert = std.debug.assert;
const log = std.log.info;

fn getFileBytes(file_path: []const u8) ![]u8 {
    const file = try std.fs.cwd().openFile(file_path, .{ .mode = std.fs.File.OpenMode.read_only });
    defer file.close();

    try file.seekFromEnd(0);
    const file_size = try file.getPos();
    try file.seekTo(0);

    var file_bytes = try std.heap.page_allocator.alloc(u8, file_size);
    const read_bytes = try file.readAll(file_bytes);

    assert(read_bytes == file_size);

    return file_bytes;
}

fn freeFileBytes(file_bytes: []u8) void {
    std.heap.page_allocator.free(file_bytes);
}

pub fn main() anyerror!void {
    const file_bytes = try getFileBytes("puzzle.txt");
    defer freeFileBytes(file_bytes);
    log("File size: {}", .{file_bytes.len});

    const bit_count = 12;
    var bit_sets = [_]i32{0} ** bit_count;
    var total_lines: i32 = 0;

    var line_iter = std.mem.split(u8, file_bytes, "\r\n");

    while (line_iter.next()) |line| {
        log("Line: {s}", .{line});
        total_lines += 1;

        assert(line.len == bit_count);

        for (line) |bit, index| {
            if (bit == '1') {
                bit_sets[index] += 1;
            }
        }
    }

    log("Total lines: {}", .{total_lines});

    var gamma: u32 = 0;
    var epsilon: u32 = 0;

    for (bit_sets) |bits, index| {
        const bit_pos = (bit_count - 1) - index;

        log("Bits {}: {} ({})", .{ index, bits, bit_pos });

        const bit_value: u32 = @shlExact(@intCast(u32, 1), @intCast(u5, bit_pos));

        if (bits > @divTrunc(total_lines, 2)) {
            gamma += bit_value;
        } else {
            epsilon += bit_value;
        }
    }

    const power_consumption: u32 = gamma * epsilon;

    log("Gamma: {} Epsilon: {} Power: {}", .{ gamma, epsilon, power_consumption });
}
