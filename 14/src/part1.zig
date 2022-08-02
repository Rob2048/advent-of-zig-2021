const std = @import("std");
const rob = @import("rob.zig");
const log = std.log.info;
const assert = std.debug.assert;

pub fn printChainAsAscii(chain: []const u8) void {
    std.debug.print("({})", .{chain.len});
    for (chain) |char| {
        std.debug.print("{c}", .{char + 'A'});
    }
    std.debug.print("\n", .{});
}

pub fn main() anyerror!void {
    const allocator = std.heap.page_allocator;
    
    // const file = try rob.File.loadFromPath("example.txt");
    const file = try rob.File.loadFromPath("puzzle.txt");
    defer file.deinit();

    log("File size: {}", .{file.bytes.len});

    const max_buffer_size: usize = 1024 * 1024;

    var chain_buffer = try allocator.alloc(u8, max_buffer_size);
    defer allocator.free(chain_buffer);
    var chain_buffer_size: usize = 0;

    var scratch_buffer = try allocator.alloc(u8, max_buffer_size);
    defer allocator.free(scratch_buffer);

    var rule_table = [_]u8{0} ** (26 * 26);

    var section_iter = std.mem.split(u8, file.bytes, "\r\n\r\n");

    const starting_str = section_iter.next().?;
    log("Starting condition: {s}", .{starting_str});

    for (starting_str) |char| {
        chain_buffer[chain_buffer_size] = char - 'A';
        chain_buffer_size += 1;
    }

    const rule_section = section_iter.next().?;
    var rule_iter = std.mem.split(u8, rule_section, "\r\n");
    while (rule_iter.next()) |rule_str| {
        // log("Rule: {s}", .{rule_str});

        var param_iter = std.mem.split(u8, rule_str, " -> ");
        const pair_str = param_iter.next().?;
        const value_str = param_iter.next().?;

        assert(pair_str.len == 2 and value_str.len == 1);

        log("Pair: {s} Value: {s}", .{ pair_str, value_str });

        const rule_table_index: usize = @as(usize, pair_str[0] - 'A') * 26 + @as(usize, pair_str[1] - 'A');
        rule_table[rule_table_index] = value_str[0] - 'A';
    }

    printChainAsAscii(chain_buffer[0..chain_buffer_size]);

    const step_count: usize = 10;
    var step_iter: usize = 0;

    while (step_iter < step_count) : (step_iter += 1) {
        var scratch_size: usize = 0;

        assert(chain_buffer_size > 0);
        scratch_buffer[scratch_size] = chain_buffer[0];
        scratch_size += 1;

        var char_iter: usize = 1;
        while (char_iter < chain_buffer_size) : (char_iter += 1) {
            const char_a = chain_buffer[char_iter - 1];
            const char_b = chain_buffer[char_iter];
            const rule_index = @as(usize, char_a) * 26 + char_b;

            const rule_result = rule_table[rule_index];
            if (rule_result != 0) {
                scratch_buffer[scratch_size] = rule_result;
                scratch_size += 1;
            }

            scratch_buffer[scratch_size] = char_b;
            scratch_size += 1;
        }

        const temp_buffer = chain_buffer;
        chain_buffer = scratch_buffer;
        scratch_buffer = temp_buffer;
        chain_buffer_size = scratch_size;

        log("Step {}: Size: {}", .{step_iter + 1, chain_buffer_size});

        // std.debug.print("Step {}:", .{step_iter + 1});
        // printChainAsAscii(chain_buffer[0..chain_buffer_size]);
    }

    var histogram = [_]usize{0} ** 26;

    for(chain_buffer[0..chain_buffer_size]) |char| {
        histogram[char] += 1;
    }

    log("Hisogram: {any}", .{histogram});

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
    log("Least: {} Most: {} Final: {}", .{least, most, final});
}
