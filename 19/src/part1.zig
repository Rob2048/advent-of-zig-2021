const std = @import("std");
const rob = @import("rob.zig");
const log = std.log.info;
const assert = std.debug.assert;
pub const log_level: std.log.Level = .info;

const Vec3 = struct {
    x: i64 = 0,
    y: i64 = 0,
    z: i64 = 0,

    pub inline fn set(self: *Vec3, index: usize, value: i64) void {
        @ptrCast(*[3]i64, self)[index] = value;
    }

    pub inline fn get(self: *Vec3, index: usize) i64 {
        return @ptrCast(*[3]i64, self)[index];
    }

    pub inline fn swizzle(self: *Vec3, src: usize, dst: usize, mul: i64) void {
        @ptrCast(*[3]i64, self)[dst] = @ptrCast(*[3]i64, self)[src] * mul;
    }

    pub inline fn getKey(self: *const Vec3) i64 {
        return (((self.x + 250000) << 0) | ((self.y + 250000) << 20) | ((self.y + 250000) << 40));
    }

    pub inline fn getTransformedByRule(self: *const Vec3, rule: TransformRule, offset: Vec3) Vec3 {
        var result = Vec3{};

        var arr = @ptrCast(*const [3]i64, self);

        result.x = arr[rule.x] * rule.mul_x + offset.x;
        result.y = arr[rule.y] * rule.mul_y + offset.y;
        result.z = arr[rule.z] * rule.mul_z + offset.z;

        return result;
    }

    pub inline fn sub(a: Vec3, b: Vec3) Vec3 {
        return Vec3{
            .x = a.x - b.x,
            .y = a.y - b.y,
            .z = a.z - b.z,
        };
    }
};

const Scanner = struct {
    index: usize,
    beacons: std.ArrayList(Vec3) = undefined,
    transform: TransformRule = TransformRule{},
    offset: Vec3 = Vec3{},

    pub fn init(allocator: std.mem.Allocator, index: usize) Scanner {
        return Scanner{
            .index = index,
            .beacons = std.ArrayList(Vec3).init(allocator),
        };
    }

    pub fn deinit(self: *Scanner) void {
        self.beacons.deinit();
    }

    pub fn createBeacon(self: *Scanner) !*Vec3 {
        try self.beacons.append(Vec3{});
        return &self.beacons.items[self.beacons.items.len - 1];
    }
};

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var world_space_beacons = std.AutoHashMap(i64, Vec3).init(allocator);
    defer world_space_beacons.deinit();

    // const file = try rob.File.loadFromPath("example.txt");
    const file = try rob.File.loadFromPath("puzzle.txt");
    defer file.deinit();

    var scanners = std.ArrayList(Scanner).init(allocator);
    defer {
        for (scanners.items) |*scanner| {
            scanner.deinit();
        }
        scanners.deinit();
    }

    {
        var current_scanner: ?*Scanner = null;
        var line_iter = std.mem.split(u8, file.bytes, "\r\n");
        while (line_iter.next()) |line| {
            if (line.len == 0) {
                continue;
            } else if (std.mem.startsWith(u8, line, "---")) {
                log("Create scanner", .{});
                try scanners.append(Scanner.init(allocator, scanners.items.len));
                current_scanner = &scanners.items[scanners.items.len - 1];
            } else {
                var param_iter = std.mem.split(u8, line, ",");
                const x_str = param_iter.next().?;
                const y_str = param_iter.next().?;
                const z_str = param_iter.next().?;

                var scanner = current_scanner.?;
                var beacon = try scanner.createBeacon();
                beacon.x = try std.fmt.parseInt(i64, x_str, 0);
                beacon.y = try std.fmt.parseInt(i64, y_str, 0);
                beacon.z = try std.fmt.parseInt(i64, z_str, 0);
            }
        }
    }

    log("Scanners: {}", .{scanners.items.len});

    // Add scanner 0 initial beacons.
    for (scanners.items[0].beacons.items) |vec| {
        const key = vec.getKey();
        try world_space_beacons.put(key, vec);
    }

    log("World beacons count: {}", .{world_space_beacons.count()});

    var scanner_queue = std.ArrayList(*Scanner).init(allocator);
    defer scanner_queue.deinit();

    for (scanners.items) |*scanner, scanner_index| {
        if (scanner_index == 0) {
            continue;
        }

        try scanner_queue.append(scanner);
    }

    // Check each scanner against the current world beacons.
    while (scanner_queue.items.len > 0) {
        var current_scanner = scanner_queue.orderedRemove(0);
        log("Checking scanner {}", .{current_scanner.index});

        // Check every possible transform.
        outer: for (transform_rules) |transform_rule, rule_index| {
            // Get point offset for every combination of world points and scanner points.
            var world_beacons_iter = world_space_beacons.iterator();
            while (world_beacons_iter.next()) |beacon| {
                for (current_scanner.beacons.items) |*point_a| {
                    const point_src = point_a.getTransformedByRule(transform_rule, Vec3{});
                    const offset = Vec3.sub(beacon.value_ptr.*, point_src);

                    // Align each point in scanner to current transform and origin, then check if it exists in global points.
                    var match_count: usize = 0;
                    for (current_scanner.beacons.items) |*point_b| {
                        const trans_point = point_b.getTransformedByRule(transform_rule, offset);

                        // Compare this point against all global points.
                        const key = trans_point.getKey();
                        if (world_space_beacons.contains(key)) {
                            match_count += 1;
                        }
                    }

                    if (match_count >= 12) {
                        log("Matches: {} Transform: {} at {any}", .{ match_count, rule_index, offset });

                        current_scanner.transform = transform_rule;
                        current_scanner.offset = offset;

                        // Add these points to the global list.
                        for (current_scanner.beacons.items) |*point_b| {
                            const trans_point = point_b.getTransformedByRule(transform_rule, offset);
                            const key = trans_point.getKey();

                            if (world_space_beacons.contains(key)) {
                                // log("Matched: {any}", .{trans_point});
                            } else {
                                try world_space_beacons.put(key, trans_point);
                            }
                        }

                        break :outer;
                    }
                }
            }
        } else {
            // Did not find any matching transform or offset.
            try scanner_queue.append(current_scanner);
        }
    }

    log("World beacons count: {}", .{world_space_beacons.count()});
}

const TransformRule = struct {
    x: usize = 0,
    y: usize = 1,
    z: usize = 2,
    mul_x: i64 = 1,
    mul_y: i64 = 1,
    mul_z: i64 = 1,

    pub fn init(x: usize, y: usize, z: usize, mul_x: i64, mul_y: i64, mul_z: i64) TransformRule {
        return TransformRule{
            .x = x,
            .y = y,
            .z = z,
            .mul_x = mul_x,
            .mul_y = mul_y,
            .mul_z = mul_z,
        };
    }
};

const transform_rules = [_]TransformRule{
    TransformRule.init(0, 1, 2, 1, 1, 1),
    TransformRule.init(0, 1, 2, 1, -1, -1),
    TransformRule.init(0, 1, 2, -1, 1, -1),
    TransformRule.init(0, 1, 2, -1, -1, 1),

    TransformRule.init(0, 2, 1, 1, 1, -1),
    TransformRule.init(0, 2, 1, 1, -1, 1),
    TransformRule.init(0, 2, 1, -1, 1, 1),
    TransformRule.init(0, 2, 1, -1, -1, -1),

    TransformRule.init(1, 2, 0, 1, 1, 1),
    TransformRule.init(1, 2, 0, 1, -1, -1),
    TransformRule.init(1, 2, 0, -1, 1, -1),
    TransformRule.init(1, 2, 0, -1, -1, 1),

    TransformRule.init(1, 0, 2, 1, 1, -1),
    TransformRule.init(1, 0, 2, 1, -1, 1),
    TransformRule.init(1, 0, 2, -1, 1, 1),
    TransformRule.init(1, 0, 2, -1, -1, -1),

    TransformRule.init(2, 0, 1, 1, 1, 1),
    TransformRule.init(2, 0, 1, 1, -1, -1),
    TransformRule.init(2, 0, 1, -1, 1, -1),
    TransformRule.init(2, 0, 1, -1, -1, 1),

    TransformRule.init(2, 1, 0, 1, 1, -1),
    TransformRule.init(2, 1, 0, 1, -1, 1),
    TransformRule.init(2, 1, 0, -1, 1, 1),
    TransformRule.init(2, 1, 0, -1, -1, -1),
};

// Possible transforms (24):

// Forward
// x y z
// y -x z
// -x -y z
// -y x z

// Right
// z y -x
// z -x -y
// z -y x
// z x y

// Back
// -x y -z
// -y -x -z
// x -y -z
// y x -z

// Left
// -z y x
// -z -x y
// -z -y -x
// -z x -y

// Up
// x z -y
// -y z -x
// -x z y
// y z x

// Down
// x -z y
// y -z -x
// -x -z -y
// -y -z x

// Reduced
// 0 1 2
// x y z
// x -y -z
// -x y -z
// -x -y z

// 0 2 1
// x z -y
// x -z y
// -x z y
// -x -z -y

// 1 2 0
// y z x
// y -z -x
// -y z -x
// -y -z x

// 1 0 2
// y x -z
// y -x z
// -y x z
// -y -x -z

// 2 0 1
// z x y
// z -x -y
// -z x -y
// -z -x y

// 2 1 0
// z y -x
// z -y x
// -z y x
// -z -y -x

// + + +
// + - -
// - + -
// - - +
// + + -
// + - +
// - + +
// - - -

// - - -
// - - +
// - + -
// - + +
// + - -
// + - +
// + + -
// + + +
