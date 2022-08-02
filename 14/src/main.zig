const std = @import("std");
const rob = @import("rob.zig");
const log = std.log.info;
const assert = std.debug.assert;
pub const log_level: std.log.Level = .info;

const Histogram = struct {
    values: [26]usize = [_]usize{0} ** (26),

    pub fn print(self: *Histogram) void {
        std.debug.print("Histogram: ", .{});
        for (self.values) |value, index| {
            std.debug.print("{c}:{} ", .{ @intCast(u8, index + 'A'), value });
        }
        std.debug.print("\n", .{});
    }

    pub fn add(self: *Histogram, target: *Histogram) void {
        for (self.values) |*value, index| {
            value.* += target.values[index];
        }
    }
};

const Rule = struct {
    value: u8 = 0,
    index_a: usize = 0,
    index_b: usize = 0,
};

fn getRuleIndex(a: u8, b: u8) usize {
    return @as(usize, a) * 26 + b;
}

pub fn main() anyerror!void {
    const allocator = std.heap.page_allocator;

    // const file = try rob.File.loadFromPath("example.txt");
    const file = try rob.File.loadFromPath("puzzle.txt");
    defer file.deinit();

    log("File size: {}", .{file.bytes.len});

    var histogram = Histogram{};

    var rule_table: [26 * 26]Rule = [_]Rule{Rule{}} ** (26 * 26);

    var pair_counts: [26 * 26]Histogram = [_]Histogram{Histogram{}} ** (26 * 26);
    var scratch_counts: [26 * 26]Histogram = [_]Histogram{Histogram{}} ** (26 * 26);

    var section_iter = std.mem.split(u8, file.bytes, "\r\n\r\n");

    var starting_str = section_iter.next().?;
    log("Starting condition: {s}", .{starting_str});
    // starting_str = "NN";

    var starting_chain = try allocator.alloc(u8, starting_str.len);
    defer allocator.free(starting_chain);
    for (starting_str) |char, index| {
        const char_value = char - 'A';
        starting_chain[index] = char_value;

        histogram.values[char_value] += 1;
    }

    const rule_section = section_iter.next().?;
    var rule_iter = std.mem.split(u8, rule_section, "\r\n");
    while (rule_iter.next()) |rule_str| {
        var param_iter = std.mem.split(u8, rule_str, " -> ");
        const pair_str = param_iter.next().?;
        const value_str = param_iter.next().?;

        assert(pair_str.len == 2 and value_str.len == 1);

        log("Rule: {s} to {s}", .{ pair_str, value_str });

        const char_a = pair_str[0] - 'A';
        const char_b = pair_str[1] - 'A';
        const char_v = value_str[0] - 'A';

        const self_index = getRuleIndex(char_a, char_b);

        rule_table[self_index] = Rule{
            .value = char_v,
            .index_a = getRuleIndex(char_a, char_v),
            .index_b = getRuleIndex(char_v, char_b),
        };

        // Level1 of pair counts.
        pair_counts[self_index].values[char_v] += 1;
    }

    // Finish the rest of the levels.
    const level_count: usize = 40;
    var level_iter: usize = 0;
    while (level_iter < level_count - 1) : (level_iter += 1) {
        log("Create level {}", .{level_iter + 2});

        for (rule_table) |rule, rule_index| {
            if (rule.value == 0) {
                continue;
            }
            
            scratch_counts[rule_index] = Histogram{};
            scratch_counts[rule_index].values[rule.value] += 1;
            scratch_counts[rule_index].add(&pair_counts[rule.index_a]);
            scratch_counts[rule_index].add(&pair_counts[rule.index_b]);
        }

        // Swap buffers.
        var temp_counts = pair_counts;
        pair_counts = scratch_counts;
        scratch_counts = temp_counts;
    }

    var pair_iter: usize = 0;
    while (pair_iter < starting_chain.len - 1) : (pair_iter += 1) {
        const char_a = starting_chain[pair_iter + 0];
        const char_b = starting_chain[pair_iter + 1];
        const pair_index = getRuleIndex(char_a, char_b);

        log("Check pair: {c}{c}", .{ char_a + 'A', char_b + 'A' });

        histogram.add(&pair_counts[pair_index]);
    }

    histogram.print();

    var least: usize = std.math.maxInt(usize);
    var most: usize = std.math.minInt(usize);
    var total: usize = 0;

    for (histogram.values) |value| {
        if (value == 0) {
            continue;
        }

        total += value;
        least = std.math.min(least, value);
        most = std.math.max(most, value);
    }

    const final = most - least;
    log("Total: {} Least: {} Most: {} Final: {}", .{ total, least, most, final });
}

// NN
// 1 NCN        N=2 C=1
// 2 NBCCN      N=2 C=2 B=1
// 3 NBBBCNCCN
// 4 NBBNBNBBCCNBCNCCN

// NN
// NCN
// NBCCN
// NBBBCNCCN

// 0
// NN -> C : C1
// NC -> B : B1
// CN -> C : C1
// NB -> B : B1
// BC -> B : B1
// CC -> N : N1
// BB -> N : B1
// BN -> B : B1

// 1
// NN -> C : B1 : C2
// NC -> B : B1 : B2
// CN -> C : N1 : C2
// NB -> B : B1 : B1
// BC -> B : B1 : B1
// CC -> N : C1 : B1
// BB -> B : B1 : B1
// BN -> B : B1 : B1

// 2
// NN -> C : B3 : N1 C3
// NC -> B : 
// CN -> C : 
// NB -> B : 
// BC -> B : 
// CC -> N : 
// BB -> B : 
// BN -> B : 