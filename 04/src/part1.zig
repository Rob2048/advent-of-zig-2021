const std = @import("std");
const assert = std.debug.assert;
const log = std.log.info;

const board_width: u32 = 5;
const board_height: u32 = 5;

const Board = struct {
    numbers: [board_width * board_height]u32 = [_]u32{0} ** (board_width * board_height),
    marked: [board_width * board_height]bool = [_]bool{false} ** (board_width * board_height),

    pub fn mark(self: *Board, num: u32) void {
        for (self.numbers) |number, index| {
            if (number == num) {
                self.marked[index] = true;
            }
        }
    }

    pub fn hasWon(self: *Board) bool {
        var row_iter: u32 = 0;
        outer: while (row_iter < board_height) : (row_iter += 1) {
            var num_iter: u32 = 0;
            while (num_iter < board_width) : (num_iter += 1) {
                if (self.marked[row_iter * board_width + num_iter] == false) {
                    continue :outer;
                }
            }

            return true;
        }

        var column_iter: u32 = 0;
        outer: while (column_iter < board_width) : (column_iter += 1) {
            var num_iter: u32 = 0;
            while (num_iter < board_height) : (num_iter += 1) {
                if (self.marked[num_iter * board_width + column_iter] == false) {
                    continue :outer;
                }
            }

            return true;
        }

        return false;
    }

    pub fn sumUnmarked(self: *Board) u32 {
        var result: u32 = 0;

        for (self.numbers) |num, index| {
            if (self.marked[index] == false) {
                result += num;
            }
        }

        return result;
    }
};

fn getFileBytes(file_path: []const u8) ![]u8 {
    const file = try std.fs.cwd().openFile(file_path, .{ .mode = std.fs.File.OpenMode.read_only });
    defer file.close();

    try file.seekFromEnd(0);
    const file_size = try file.getPos();
    try file.seekTo(0);

    var file_bytes = try std.heap.page_allocator.alloc(u8, file_size);

    const read_bytes = try file.readAll(file_bytes);
    assert(read_bytes == file_size);

    return file_bytes;
}

fn freeFileBytes(file_bytes: []u8) void {
    std.heap.page_allocator.free(file_bytes);
}

pub fn main() anyerror!void {
    const file_bytes = try getFileBytes("puzzle.txt");
    defer freeFileBytes(file_bytes);

    var number_calls = std.ArrayList(u32).init(std.heap.page_allocator);
    defer number_calls.deinit();

    var line_iter = std.mem.split(u8, file_bytes, "\r\n");

    // Number calls.
    if (line_iter.next()) |line| {
        var num_iter = std.mem.split(u8, line, ",");
        while (num_iter.next()) |numStr| {
            try number_calls.append(try std.fmt.parseInt(u32, numStr, 0));
        }
    }

    // Boards.
    var boards = std.ArrayList(Board).init(std.heap.page_allocator);
    defer boards.deinit();

    var current_board = Board{};
    var current_entries: u32 = 0;

    while (line_iter.next()) |line| {
        var num_iter = std.mem.split(u8, line, " ");
        while (num_iter.next()) |numStr| {
            // log("{s} {}", .{numStr, numStr.len});

            if (numStr.len == 0) {
                continue;
            }

            const num = try std.fmt.parseInt(u32, numStr, 0);

            current_board.numbers[current_entries] = num;
            current_entries += 1;

            if (current_entries == board_width * board_height) {
                try boards.append(current_board);
                current_entries = 0;
            }
        }
    }

    assert(current_entries == 0);

    outer: for (number_calls.items) |num| {
        log("Number call: {}", .{num});

        for (boards.items) |*board, board_index| {
            board.mark(num);

            if (board.hasWon()) {
                var final_sum = board.sumUnmarked();
                final_sum *= num;

                log("Board {} won with {} ({})", .{ board_index, num, final_sum });

                break :outer;
            }
        }
    }
}
