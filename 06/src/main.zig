const std = @import("std");
const rob = @import("rob.zig");
const assert = std.debug.assert;
const log = std.log.info;
pub const log_level: std.log.Level = .info;

pub fn main() anyerror!void {
    const file = try rob.File.loadFromPath("puzzle.txt");
    defer file.deinit();

    log("File data: {s}", .{file.bytes});

    const input = file.bytes;
    // const input = "3,4,3,1,2";

    var fish_buckets = [_]i64{0} ** 9;

    var num_iter = std.mem.split(u8, input, ",");
    while (num_iter.next()) |numStr| {
        const num = try std.fmt.parseInt(usize, numStr, 0);

        fish_buckets[num] += 1;
    }

    // Simulate fishes.
    const total_days: usize = 256;

    var day_iter: usize = 0;
    while (day_iter < total_days) : (day_iter += 1) {
        const zero_fishes = fish_buckets[0];

        var bucket_iter: usize = 0;
        while (bucket_iter < fish_buckets.len - 1) : (bucket_iter += 1) {
            fish_buckets[bucket_iter] = fish_buckets[bucket_iter + 1];
        }

        fish_buckets[6] += zero_fishes;
        fish_buckets[8] = zero_fishes;

        var total_fishes: i64 = 0;
        for (fish_buckets) |bucket| {
            total_fishes += bucket;
        }

        log("Day {}: {any} {}", .{ day_iter + 1, fish_buckets, total_fishes });
    }
}
