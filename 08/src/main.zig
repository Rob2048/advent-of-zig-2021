const std = @import("std");
const assert = std.debug.assert;
const log = std.log.info;
const rob = @import("rob.zig");

const Display = struct {
    segments: [10][]const u8 = undefined,
    output_digits: [4][]const u8 = undefined,
    digits: [10]u8 = [_]u8{0} ** 10,

    pub fn findStartingDigits(self: *Display) void {
        // Looking for 1, 4, 7, 8
        // 1 = 2
        // 4 = 4
        // 7 = 3
        // 8 = 7

        for (self.segments) |segment| {
            if (segment.len == 2) {
                self.digits[1] = charsToBits(segment);
            } else if (segment.len == 4) {
                self.digits[4] = charsToBits(segment);
            } else if (segment.len == 3) {
                self.digits[7] = charsToBits(segment);
            } else if (segment.len == 7) {
                self.digits[8] = charsToBits(segment);
            }
        }
    }

    pub fn getFiveSegs(self: Display) [3]u8 {
        var index: usize = 0;
        var result: [3]u8 = undefined;

        for (self.segments) |segment| {
            if (segment.len == 5) {
                result[index] = charsToBits(segment);
                index += 1;
            }
        }

        assert(index == 3);

        return result;
    }

    pub fn getSixSegs(self: Display) [3]u8 {
        var index: usize = 0;
        var result: [3]u8 = undefined;

        for (self.segments) |segment| {
            if (segment.len == 6) {
                result[index] = charsToBits(segment);
                index += 1;
            }
        }

        assert(index == 3);

        return result;
    }

    fn charsToBits(chars: []const u8) u8 {
        var result: u8 = 0;

        for (chars) |char| {
            result |= @intCast(u8, 1) << @intCast(u3, (char - 'a'));
        }

        return result;
    }

    pub fn findDigitMapping(self: *Display) i64 {
        self.findStartingDigits();

        const six_segs: [3]u8 = self.getSixSegs();
        const five_segs: [3]u8 = self.getFiveSegs();

        var segs: [7]u8 = [_]u8{0} ** 7;

        // Segment counts:
        // 1 = 2
        // 4 = 4
        // 7 = 3
        // 8 = 7

        // 0 = 6
        // 6 = 6
        // 9 = 6

        // 2 = 5
        // 3 = 5
        // 5 = 5

        segs[0] = self.digits[1] ^ self.digits[7];
        segs[6] = self.digits[4] & five_segs[0] & five_segs[1] & five_segs[2];

        // Zero must be 1 of the 6 segments that does not have seg[6] set.
        if (six_segs[0] & segs[6] == 0) {
            self.digits[0] = six_segs[0];
        } else if (six_segs[1] & segs[6] == 0) {
            self.digits[0] = six_segs[1];
        } else if (six_segs[2] & segs[6] == 0) {
            self.digits[0] = six_segs[2];
        }

        // 9 contains all the chars that 4 does, must be one of the 6 seg.
        if (six_segs[0] & self.digits[4] == self.digits[4]) {
            self.digits[9] = six_segs[0];
        } else if (six_segs[1] & self.digits[4] == self.digits[4]) {
            self.digits[9] = six_segs[1];
        } else if (six_segs[2] & self.digits[4] == self.digits[4]) {
            self.digits[9] = six_segs[2];
        }

        // 6 does not equal 4 and is not 0
        if (six_segs[0] & self.digits[4] != self.digits[4] and six_segs[0] & segs[6] != 0) {
            self.digits[6] = six_segs[0];
        } else if (six_segs[1] & self.digits[4] != self.digits[4] and six_segs[1] & segs[6] != 0) {
            self.digits[6] = six_segs[1];
        } else if (six_segs[2] & self.digits[4] != self.digits[4] and six_segs[2] & segs[6] != 0) {
            self.digits[6] = six_segs[2];
        }

        segs[2] = self.digits[1] & self.digits[6];
        segs[1] = self.digits[1] - segs[2];

        // 3 contains 1
        if (five_segs[0] & self.digits[1] == self.digits[1]) {
            self.digits[3] = five_segs[0];
        } else if (five_segs[1] & self.digits[1] == self.digits[1]) {
            self.digits[3] = five_segs[1];
        } else if (five_segs[2] & self.digits[1] == self.digits[1]) {
            self.digits[3] = five_segs[2];
        }

        // 2 contains seg 1 and does not equal 3
        if (five_segs[0] & segs[1] != 0 and five_segs[0] != self.digits[3]) {
            self.digits[2] = five_segs[0];
        } else if (five_segs[1] & segs[1] != 0 and five_segs[1] != self.digits[3]) {
            self.digits[2] = five_segs[1];
        } else if (five_segs[2] & segs[1] != 0 and five_segs[2] != self.digits[3]) {
            self.digits[2] = five_segs[2];
        }

        // 5 contains seg 2 and does not equal 3
        if (five_segs[0] & segs[2] != 0 and five_segs[0] != self.digits[3]) {
            self.digits[5] = five_segs[0];
        } else if (five_segs[1] & segs[2] != 0 and five_segs[1] != self.digits[3]) {
            self.digits[5] = five_segs[1];
        } else if (five_segs[2] & segs[2] != 0 and five_segs[2] != self.digits[3]) {
            self.digits[5] = five_segs[2];
        }

        segs[3] = self.digits[3] - segs[0] - segs[1] - segs[2] - segs[6];
        segs[4] = self.digits[2] - segs[0] - segs[1] - segs[3] - segs[6];
        segs[5] = self.digits[4] - segs[1] - segs[2] - segs[6];

        log("Seg mapping: {any}", .{segs});
        log("New digit mapping: {any}", .{self.digits});

        var result: i64 = 0;

        // Match outputs to digits.
        for (self.output_digits) |digitStr| {
            const output_digit = charsToBits(digitStr);

            for (self.digits) |digit, index| {
                if (digit == output_digit) {
                    result = result * 10 + @intCast(i64, index);
                    break;
                }
            }
        }

        log("Result {}", .{result});

        return result;
    }
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

    var display_sum: i64 = 0;
    
    for (displays.items) |*display| {
        display_sum += display.findDigitMapping();
    }

    log("Display sum: {}", .{display_sum});
}
