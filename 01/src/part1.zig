const std = @import("std");

pub fn main() anyerror!void {
    std.log.info("Advent 01", .{});

    const file = try std.fs.cwd().openFile("puzzle.txt", .{ .mode = std.fs.File.OpenMode.read_only });
    defer file.close();

    try file.seekFromEnd(0);
    const fileSize = try file.getPos();
    try file.seekTo(0);

    const contents = try file.reader().readAllAlloc(std.heap.page_allocator, fileSize);
    defer std.heap.page_allocator.free(contents);

    std.log.info("File contents: {}", .{contents.len});

    var number_list_iter = std.mem.split(u8, contents, "\r\n");

    var last_depth: i32 = undefined;
    var first_num: bool = true;
    var depth_index: i32 = 0;
    var increased_count: i32 = 0;

    while (number_list_iter.next()) |entry| {
        const current_depth: i32 = try std.fmt.parseInt(i32, entry, 0);
        std.debug.print("{}: {} ", .{ depth_index, current_depth });
        depth_index += 1;

        if (first_num == true) {
            first_num = false;
            std.debug.print("(no previous value)\n", .{});
        } else {
            const depth_delta = current_depth - last_depth;
            std.debug.print("({})\n", .{depth_delta});

            if (depth_delta > 0) {
                increased_count += 1;
            }
        }

        last_depth = current_depth;
    }

    std.debug.print("Increased count: {}", .{increased_count});
}
