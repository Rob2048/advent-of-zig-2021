const std = @import("std");
const rob = @import("rob.zig");
const log = std.log.info;
const assert = std.debug.assert;

const Vec3 = struct {
    x: i64 = 0,
    y: i64 = 0,
    z: i64 = 0,

    pub fn init(x: i64, y: i64, z: i64) Vec3 {
        return Vec3{ .x = x, .y = y, .z = z };
    }

    pub fn set(self: *Vec3, index: usize, value: i64) void {
        @ptrCast(*[3]i64, self)[index] = value;
    }

    pub fn getMin(self: Vec3, b: Vec3) Vec3 {
        return Vec3{
            .x = std.math.min(self.x, b.x),
            .y = std.math.min(self.y, b.y),
            .z = std.math.min(self.z, b.z),
        };
    }

    pub fn getMax(self: Vec3, b: Vec3) Vec3 {
        return Vec3{
            .x = std.math.max(self.x, b.x),
            .y = std.math.max(self.y, b.y),
            .z = std.math.max(self.z, b.z),
        };
    }

    pub fn sub(a: Vec3, b: Vec3) Vec3 {
        return Vec3{
            .x = a.x - b.x,
            .y = a.y - b.y,
            .z = a.z - b.z,
        };
    }
};

const Cuboid = struct {
    value: usize = 0,
    min: Vec3 = .{},
    max: Vec3 = .{},

    pub fn getIntersection(self: *const Cuboid, b: *const Cuboid) ?Cuboid {
        if (self.min.x > b.max.x or self.min.y > b.max.y or self.min.z > b.max.z or
            self.max.x < b.min.x or self.max.y < b.min.y or self.max.z < b.min.z) {
            return null;
        }

        const min = self.min.getMax(b.min);
        const max = self.max.getMin(b.max);

        return Cuboid{
            .min = min,
            .max = max,
        };
    }

    pub fn getVolume(self: *const Cuboid) i64 {
        const delta = Vec3.sub(self.max, self.min);

        return (delta.x + 1) * (delta.y + 1) * (delta.z + 1);
    }
};

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const file = try rob.File.loadFromPath("puzzle.txt");
    // const file = try rob.File.loadFromPath("example.txt");
    defer file.deinit();

    log("File size: {}", .{file.bytes.len});

    var cuboids = std.ArrayList(Cuboid).init(allocator);
    defer cuboids.deinit();

    var line_iter = std.mem.split(u8, file.bytes, "\r\n");
    while (line_iter.next()) |line| {
        const value: usize = if (line[1] == 'n') 1 else 0;

        var cuboid = Cuboid{
            .value = value,
        };

        var section_iter = std.mem.split(u8, line, " ");
        _ = section_iter.next().?;

        var coord_iter = std.mem.split(u8, section_iter.next().?, ",");
        while (coord_iter.next()) |coord| {
            const coord_index: usize = coord[0] - 'x';

            var num_iter = std.mem.split(u8, coord[2..], "..");
            const min = try std.fmt.parseInt(i64, num_iter.next().?, 10);
            const max = try std.fmt.parseInt(i64, num_iter.next().?, 10);

            cuboid.min.set(coord_index, min);
            cuboid.max.set(coord_index, max);
        }

        log("New: {any}", .{cuboid});

        // if (cuboid.min.x > 50 or cuboid.min.y > 50 or cuboid.min.z > 50 or
        //     cuboid.max.x < -50 or cuboid.max.y < -50 or cuboid.max.z < -50)
        // {
        //     log("Skip", .{});
        //     continue;
        // }

        try cuboids.append(cuboid);
    }

    var volumes = std.ArrayList(Cuboid).init(allocator);
    defer volumes.deinit();

    for (cuboids.items) |cuboid| {
        for (volumes.items) |volume| {
            var intersection_wrap = cuboid.getIntersection(&volume);

            if (intersection_wrap) |*intersection| {
                if (cuboid.value == 1) {
                    if (volume.value == 1) {
                        intersection.value = 0;
                    } else {
                        intersection.value = 1;
                    }

                    try volumes.append(intersection.*);
                } else {
                    if (volume.value == 1) {
                        intersection.value = 0;
                    } else {
                        intersection.value = 1;
                    }

                    try volumes.append(intersection.*);
                }
            }
        }

        if (cuboid.value == 1) {
            try volumes.append(cuboid);
        }
    }

    var total_volume: i64 = 0;
    for (volumes.items) |volume| {
        const vol = volume.getVolume();
        if (volume.value == 1) {
            total_volume += vol;
        } else {
            total_volume -= vol;
        }

        // log("Vol: {any}", .{volume});
    }

    log("Volume: {} (Volumes: {})", .{ total_volume, volumes.items.len });
}
