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

fn findBitsSet(num_list: std.ArrayList([]const u8), bit_pos: usize) u32 {
    var result: u32 = 0;

    for (num_list.items) |num| {
        if (num[bit_pos] == '1') {
            result += 1;
        }
    }

    return result;
}

fn getNumberFromBinary(binary: []const u8) u32 {
    var result: u32 = 0;

    for (binary) |bit, index| {
        if (bit == '1') {
            result += std.math.pow(u32, 2, @intCast(u32, binary.len - 1 - index));
        }
    }

    return result;
}

pub fn main() anyerror!void {
    const file_bytes = try getFileBytes("puzzle.txt");
    defer freeFileBytes(file_bytes);
    log("File size: {}", .{file_bytes.len});

    const bit_total = 12;
    // var bit_sets = [_]i32{0} ** bit_total;
    var total_lines: i32 = 0;

    var num_list = std.ArrayList([]const u8).init(std.heap.page_allocator);
    defer num_list.deinit();

    var line_iter = std.mem.split(u8, file_bytes, "\r\n");
    while (line_iter.next()) |line| {
        log("Line: {s}", .{line});
        total_lines += 1;

        assert(line.len == bit_total);

        try num_list.append(line);
    }

    log("Total lines: {}", .{total_lines});

    var oxygen_list = std.ArrayList([]const u8).init(std.heap.page_allocator);
    defer oxygen_list.deinit();
    var co2_list = std.ArrayList([]const u8).init(std.heap.page_allocator);
    defer co2_list.deinit();

    for (num_list.items) |item| {
        try oxygen_list.append(item);
        try co2_list.append(item);
    }

    // Find oxygen list
    var bit_pos: i32 = 0;
    outer: while (bit_pos < bit_total) : (bit_pos += 1) {
        const bit_pos_u: usize = @intCast(usize, bit_pos);
        log("Bit pos: {}", .{bit_pos_u});

        log("List size: {}", .{oxygen_list.items.len});

        const bit_count = findBitsSet(oxygen_list, bit_pos_u);
        log("Bit set count: {}", .{bit_count});

        // Most common bit.
        var search_bit: u8 = '0';
        const remaining_elements = oxygen_list.items.len - bit_count;
        if (bit_count >= remaining_elements) {
            search_bit = '1';
        }
        log("Keep bit: '{c}'", .{search_bit});

        // Remove least common bit.
        var list_idx: usize = 0;
        while (list_idx < oxygen_list.items.len) {
            if (oxygen_list.items.len == 1) {
                break :outer;
            }

            if (oxygen_list.items[list_idx][bit_pos_u] != search_bit) {
                _ = oxygen_list.swapRemove(list_idx);
            } else {
                list_idx += 1;
            }
        }
    }

    assert(oxygen_list.items.len == 1);
    log("Oxygen value: {s}", .{oxygen_list.items[0]});
    var oxygen_generator_rating: u32 = getNumberFromBinary(oxygen_list.items[0]);
    log("Oxygen value: {}", .{oxygen_generator_rating});

    // Find co2 list
    bit_pos = 0;
    outer: while (bit_pos < bit_total) : (bit_pos += 1) {
        const bit_pos_u: usize = @intCast(usize, bit_pos);
        log("Bit pos: {}", .{bit_pos_u});

        log("List size: {}", .{co2_list.items.len});

        const bit_count = findBitsSet(co2_list, bit_pos_u);
        log("Bit set count: {}", .{bit_count});

        // Most common bit.
        var search_bit: u8 = '1';
        const remaining_elements = co2_list.items.len - bit_count;
        if (bit_count >= remaining_elements) {
            search_bit = '0';
        }
        log("Keep bit: '{c}'", .{search_bit});

        // Remove least common bit.
        var list_idx: usize = 0;
        while (list_idx < co2_list.items.len) {
            if (co2_list.items.len == 1) {
                break :outer;
            }

            if (co2_list.items[list_idx][bit_pos_u] != search_bit) {
                _ = co2_list.swapRemove(list_idx);
            } else {
                list_idx += 1;
            }
        }
    }

    assert(co2_list.items.len == 1);
    log("CO2 value: {s}", .{co2_list.items[0]});
    var co2_scrubber_rating: u32 = getNumberFromBinary(co2_list.items[0]);
    log("CO2 value: {}", .{co2_scrubber_rating});

    const life_support_rating: u32 = oxygen_generator_rating * co2_scrubber_rating;
    log("Life support rating: {}", .{life_support_rating});
}
