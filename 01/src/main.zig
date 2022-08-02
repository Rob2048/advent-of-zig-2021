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

    std.log.info("File size: {}", .{contents.len});

    var number_list_iter = std.mem.split(u8, contents, "\r\n");

    var number_list = std.ArrayList(i32).init(std.heap.page_allocator);
    defer number_list.deinit();

    while (number_list_iter.next()) |entry| {
        const current_depth: i32 = try std.fmt.parseInt(i32, entry, 0);
        try number_list.append(current_depth);
    }

    std.log.info("Total entries: {}", .{number_list.items.len});

    var increased_count: i32 = 0;
    var last_depth: i32 = undefined;

    var num_iter: usize = 0;
    while (num_iter < number_list.items.len - 2) : (num_iter += 1) {
        var current_depth: i32 = 0;
        current_depth += number_list.items[num_iter + 0];
        current_depth += number_list.items[num_iter + 1];
        current_depth += number_list.items[num_iter + 2];

        if (num_iter == 0) {
            last_depth = current_depth;
            continue;
        } else {
            if (current_depth > last_depth) {
                increased_count += 1;
            }

            last_depth = current_depth;
        }
    }

    std.log.info("Increased count: {}", .{increased_count});
}
