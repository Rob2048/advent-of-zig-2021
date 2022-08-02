const std = @import("std");
const assert = std.debug.assert;

pub const File = struct {
    bytes: []u8 = undefined,

    pub fn loadFromPath(file_path: []const u8) !File {
        const file = try std.fs.cwd().openFile(file_path, .{ .mode = std.fs.File.OpenMode.read_only });
        defer file.close();

        try file.seekFromEnd(0);
        const file_size = try file.getPos();
        try file.seekTo(0);

        var result = File{};

        result.bytes = try std.heap.page_allocator.alloc(u8, file_size);
        const read_bytes = try file.readAll(result.bytes);

        assert(read_bytes == file_size);

        return result;
    }

    pub fn deinit(self: File) void {
        std.heap.page_allocator.free(self.bytes);
    }
};