const std = @import("std");
const rob = @import("rob.zig");
const assert = std.debug.assert;
const log = std.log.info;

pub fn main() anyerror!void {
    var pos = std.ArrayList(i64).init(std.heap.page_allocator);
    defer pos.deinit();

    // NOTE: Example input:
    // target area: x=20..30, y=-10..-5

    // NOTE: Puzzle input:
    // target area: x=135..155, y=-102..-78

    // const target_left: i64 = 20;
    // const target_right: i64 = 30;
    // const target_top: i64 = -5;
    // const target_bottom: i64 = -10;
    const target_left: i64 = 135;
    const target_right: i64 = 155;
    const target_top: i64 = -78;
    const target_bottom: i64 = -102;

    var total_hits: usize = 0;

    var velocity_x_iter: i64 = 1;
    while (velocity_x_iter <= target_right) : (velocity_x_iter += 1) {
        var velocity_y_iter: i64 = target_bottom;
        while (velocity_y_iter <= try std.math.absInt(target_bottom) - 1) : (velocity_y_iter += 1) {
            var velocity_x: i64 = velocity_x_iter;
            var velocity_y: i64 = velocity_y_iter;

            var pos_x: i64 = 0;
            var pos_y: i64 = 0;

            // Simluate trajectory.
            while (true) {
                if (pos_x > target_right or pos_y < target_bottom) {
                    // NOTE: Out of bounds, did not hit target.
                    break;
                } else if (pos_x >= target_left and pos_x <= target_right and pos_y <= target_top and pos_y >= target_bottom) {
                    // NOTE: Hit target.
                    log("Hit target at {}, {}", .{ pos_x, pos_y });
                    total_hits += 1;
                    break;
                }

                pos_x += velocity_x;
                pos_y += velocity_y;

                if (velocity_x > 0) {
                    velocity_x -= 1;
                }

                velocity_y -= 1;
            }
        }
    }

    log("Total hits: {}", .{total_hits});
}
