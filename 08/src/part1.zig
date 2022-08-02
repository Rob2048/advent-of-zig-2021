const std = @import("std");
const assert = std.debug.assert;
const log = std.log.info;
const rob = @import("rob.zig");

const Display = struct {
    segments: [10][]const u8 = undefined,
    output_digits: [4][]const u8 = undefined,
};

pub fn main() anyerror!void {
    // const file = try rob.File.loadFromPath("example.txt");
    const file = try rob.File.loadFromPath("puzzle.txt");
    defer file.deinit();

    const input = file.bytes;

    log("Input: {s}", .{input});

    var displays = std.ArrayList(Display).init(std.heap.page_allocator);
    defer displays.deinit();

    var display_iter = std.mem.split(u8, input, "\r\n");
    while (display_iter.next()) |display_str| {
        var new_display = Display{};

        var context_iter = std.mem.split(u8, display_str, "|");
        if (context_iter.next()) |contextStr| {
            var segment_iter = std.mem.split(u8, contextStr, " ");
            var segment_count: usize = 0;
            while (segment_iter.next()) |segmentStr| {
                if (segmentStr.len == 0) {
                    continue;
                }
                new_display.segments[segment_count] = segmentStr;
                segment_count += 1;
            }

            assert(segment_count == 10);
        } else {
            unreachable;
        }

        if (context_iter.next()) |contextStr| {
            var segment_iter = std.mem.split(u8, contextStr, " ");
            var segment_count: usize = 0;
            while (segment_iter.next()) |segmentStr| {
                if (segmentStr.len == 0) {
                    continue;
                }
                new_display.output_digits[segment_count] = segmentStr;
                segment_count += 1;
            }

            assert(segment_count == 4);
        } else {
            unreachable;
        }

        try displays.append(new_display);
    }

    log("Display count: {}", .{displays.items.len});
    log("Displays: {any}", .{displays.items[0]});

    // Looking for 1, 4, 7, 8
    // 1 = 2
    // 4 = 4
    // 7 = 3
    // 8 = 7

    var digit_count: usize = 0;

    for (displays.items) |display| {
        for (display.output_digits) |digit| {
            if (digit.len == 2 or digit.len == 4 or digit.len == 3 or digit.len == 7) {
                digit_count += 1;
            }
        }
    }

    log("Digit count: {}", .{digit_count});
}
