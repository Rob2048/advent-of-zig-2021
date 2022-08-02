const std = @import("std");
const rob = @import("rob.zig");
const log = std.log.info;
const assert = std.debug.assert;
pub const log_level: std.log.Level = .info;

var histogram = [_]usize{0} ** 26;
var rule_table = [_]u8{0} ** (26 * 26);

pub fn main() anyerror!void {
    const allocator = std.heap.page_allocator;

    const file = try rob.File.loadFromPath("example.txt");
    // const file = try rob.File.loadFromPath("puzzle.txt");
    defer file.deinit();

    log("File size: {}", .{file.bytes.len});

    var section_iter = std.mem.split(u8, file.bytes, "\r\n\r\n");

    const starting_str = section_iter.next().?;
    log("Starting condition: {s}", .{starting_str});

    var starting_chain = try allocator.alloc(u8, starting_str.len);
    defer allocator.free(starting_chain);
    for (starting_str) |char, index| {
        starting_chain[index] = char - 'A';
    }

    const rule_section = section_iter.next().?;
    var rule_iter = std.mem.split(u8, rule_section, "\r\n");
    while (rule_iter.next()) |rule_str| {
        var param_iter = std.mem.split(u8, rule_str, " -> ");
        const pair_str = param_iter.next().?;
        const value_str = param_iter.next().?;

        assert(pair_str.len == 2 and value_str.len == 1);

        log("Rule: {s} to {s}", .{ pair_str, value_str });

        const rule_table_index: usize = @as(usize, pair_str[0] - 'A') * 26 + @as(usize, pair_str[1] - 'A');
        rule_table[rule_table_index] = value_str[0] - 'A';
    }

    for (starting_chain) |char| {
        histogram[char] += 1;
    }

    const step_count: usize = 40;

    var char_iter: usize = 0;
    while (char_iter < starting_chain.len - 1) : (char_iter += 1) {
        const char_a = starting_chain[char_iter];
        const char_b = starting_chain[char_iter + 1];
        log("Start pair: {c} {c}", .{char_a + 'A', char_b + 'A'});
        recurse(char_a, char_b, step_count - 1);
    }

    std.debug.print("Histogram: ", .{});
    for (histogram) |value, index| {
        std.debug.print("{c}:{} ", .{ @intCast(u8, index + 'A'), value });
    }
    std.debug.print("\n", .{});

    var least: usize = std.math.maxInt(usize);
    var most: usize = std.math.minInt(usize);

    for (histogram) |bucket| {
        if (bucket == 0) {
            continue;
        }

        least = std.math.min(least, bucket);
        most = std.math.max(most, bucket);
    }

    const final = most - least;
    log("Least: {} Most: {} Final: {}", .{ least, most, final });
}

fn recurse(a: u8, b: u8, depth: usize) void {
    // log("Check pair: {c} {c} Depth: {}", .{ a + 'A', b + 'A', depth });
    const new_char = rule_table[@as(usize, a) * 26 + b];

    if (new_char == 0) {
        return;
    }

    histogram[new_char] += 1;

    if (depth == 0) {
        return;
    }

    recurse(a, new_char, depth - 1);
    recurse(new_char, b, depth - 1);
}
