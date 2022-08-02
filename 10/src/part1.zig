const std = @import("std");
const assert = std.debug.assert;
const log = std.log.info;
const rob = @import("rob.zig");

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    // const file = try rob.File.loadFromPath("example.txt");
    const file = try rob.File.loadFromPath("puzzle.txt");
    defer file.deinit();

    log("File size: {}", .{file.bytes.len});

    var final_score: usize = 0;

    var line_iter = std.mem.split(u8, file.bytes, "\r\n");
    while (line_iter.next()) |line_str| {
        log("Line: {s}", .{line_str});

        var stack = std.ArrayList(u8).init(allocator);
        defer stack.deinit();

        var fail_score: usize = 0;

        for (line_str) |char| {
            switch (char) {
                '(' => {
                    try stack.append('(');
                },
                '[' => {
                    try stack.append('[');
                },
                '{' => {
                    try stack.append('{');
                },
                '<' => {
                    try stack.append('<');
                },
                ')' => {
                    if (stack.items[stack.items.len - 1] != '(') {
                        fail_score += 3;
                        break;
                    } else {
                        _ = stack.pop();
                    }
                },
                ']' => {
                    if (stack.items[stack.items.len - 1] != '[') {
                        fail_score += 57;
                        break;
                    } else {
                        _ = stack.pop();
                    }
                },
                '}' => {
                    if (stack.items[stack.items.len - 1] != '{') {
                        fail_score += 1197;
                        break;
                    } else {
                        _ = stack.pop();
                    }
                },
                '>' => {
                    if (stack.items[stack.items.len - 1] != '<') {
                        fail_score += 25137;
                        break;
                    } else {
                        _ = stack.pop();
                    }
                },
                else => {},
            }
        }

        log("Score: {}", .{fail_score});
        final_score += fail_score;

        // If fail_score == 0 but stack still has items, then incomplete line, but not corrupted.
    }

    log("Final score: {}", .{final_score});
}
