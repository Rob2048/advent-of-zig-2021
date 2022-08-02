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

    var score_list = std.ArrayList(usize).init(allocator);
    defer score_list.deinit();

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

        // If fail_score == 0 but stack still has items, then incomplete line, but not corrupted.
        if (fail_score == 0 and stack.items.len != 0) {
            log("Incomplete line {any}", .{stack.items});

            for (stack.items) |char| {
                std.debug.print("{c}", .{char});
            }

            std.debug.print("\n", .{});

            fail_score = 0;

            while (stack.items.len > 0) {
                const char = stack.pop();

                log("Popped {}", .{char});

                fail_score *= 5;

                switch (char) {
                    '(' => fail_score += 1,
                    '[' => fail_score += 2,
                    '{' => fail_score += 3,
                    '<' => fail_score += 4,
                    else => {},
                }
            }

            try score_list.append(fail_score);
        }
    }

    // Median of scores.
    std.sort.sort(usize, score_list.items, {}, comptime std.sort.asc(usize));

    log("Scores: {any}", .{score_list.items});

    const median = score_list.items[score_list.items.len / 2];

    log("Median: {}", .{median});
}
