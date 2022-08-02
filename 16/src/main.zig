const std = @import("std");
const rob = @import("rob.zig");
const assert = std.debug.assert;
const log = std.log.info;

fn getBit(input: []const u8, bit: usize) usize {
    const byte_index = bit / 4;
    const bit_index = 3 - bit % 4;
    const result = input[byte_index] & (@as(u8, 1) << @intCast(u3, bit_index));

    return if (result > 0) 1 else 0;
}

fn readValue(input: []const u8, bit_start: *usize, digits: usize) usize {
    var result: usize = 0;

    var digit_iter: usize = 0;
    while (digit_iter < digits) : (digit_iter += 1) {
        result |= getBit(input, bit_start.*) << @intCast(u6, (digits - digit_iter - 1));
        bit_start.* += 1;
    }

    return result;
}

var op_stack: std.ArrayList(usize) = undefined;

pub fn main() anyerror!void {
    const file = try rob.File.loadFromPath("puzzle.txt");
    defer file.deinit();

    log("File size: {}", .{file.bytes.len});
    const input_str = file.bytes;
    // var input_str = "C200B40A82";
    // var input_str = "04005AC33890";
    // var input_str = "880086C3E88112";
    // var input_str = "CE00C43D881120";
    // var input_str = "D8005AC2A8F0";
    // var input_str = "F600BC2D8F";
    // var input_str = "9C005AC2F8F0";
    // var input_str = "9C0141080250320F1802104A08";

    log("Input: {s}", .{input_str});

    const byte_str = try std.heap.page_allocator.alloc(u8, input_str.len);
    defer std.heap.page_allocator.free(byte_str);

    for (input_str) |char, index| {
        if (char < 'A') {
            byte_str[index] = char - '0';
        } else {
            byte_str[index] = char - 'A' + 10;
        }
    }

    op_stack = std.ArrayList(usize).init(std.heap.page_allocator);
    defer op_stack.deinit();

    var bit: usize = 0;
    _ = try parsePacket(byte_str, &bit);
    log("{any}", .{op_stack.items});

    assert(op_stack.items.len == 1);

    log("Result: {}", .{op_stack.items[0]});
}

fn parsePacket(input: []const u8, bit: *usize) anyerror!usize {
    const starting_bit = bit.*;

    const packet_version = readValue(input, bit, 3);
    const packet_type = readValue(input, bit, 3);
    log("New packet - Version: {} Type: {}", .{ packet_version, packet_type });
    
    if (packet_type == 4) {
        // Literal packet.
        var literal_value: usize = 0;

        while (true) {
            const group_prefix = readValue(input, bit, 1);
            const group_value = readValue(input, bit, 4);

            literal_value <<= 4;
            literal_value |= group_value;

            if (group_prefix == 0) {
                break;
            }
        }

        try op_stack.append(literal_value);

        log("Literal: {}", .{literal_value});
    } else {
        // Operator packet.
        const length_type_id = readValue(input, bit, 1);
        log("Operator packet: {}", .{length_type_id});

        const current_stack_len = op_stack.items.len;

        if (length_type_id == 0) {
            const subpacket_bit_count = readValue(input, bit, 15);
            log("subpacket_bit_count: {}", .{subpacket_bit_count});

            var read_packet_bits: usize = 0;

            while (read_packet_bits < subpacket_bit_count) {
                read_packet_bits += try parsePacket(input, bit);
            }
        } else {
            var subpacket_count = readValue(input, bit, 11);
            log("subpacket_count: {}", .{subpacket_count});

            while (subpacket_count > 0) : (subpacket_count -= 1) {
                _ = try parsePacket(input, bit);
            }
        }

        if (packet_type == 0) {
            // Sum packet.
            var result: usize = 0;

            while (op_stack.items.len > current_stack_len) {
                result += op_stack.pop();
            }

            try op_stack.append(result);
        } else if (packet_type == 1) {
            // Product packet.
            var result: usize = 1;

            while (op_stack.items.len > current_stack_len) {
                result *= op_stack.pop();
            }

            try op_stack.append(result);
        } else if (packet_type == 2) {
            // Min packet.
            var result: usize = std.math.maxInt(usize);

            while (op_stack.items.len > current_stack_len) {
                result = std.math.min(result, op_stack.pop());
            }

            try op_stack.append(result);
        } else if (packet_type == 3) {
            // Max packet.
            var result: usize = 0;

            while (op_stack.items.len > current_stack_len) {
                result = std.math.max(result, op_stack.pop());
            }

            try op_stack.append(result);
        } else if (packet_type == 5) {
            // Greater than packet.
            const b = op_stack.pop();
            const a = op_stack.pop();

            if (a > b) {
                try op_stack.append(1);
            } else {
                try op_stack.append(0);
            }
        } else if (packet_type == 6) {
            // Less than packet.
            const b = op_stack.pop();
            const a = op_stack.pop();

            if (a < b) {
                try op_stack.append(1);
            } else {
                try op_stack.append(0);
            }
        } else if (packet_type == 7) {
            // Equal to packet.
            const b = op_stack.pop();
            const a = op_stack.pop();

            if (a == b) {
                try op_stack.append(1);
            } else {
                try op_stack.append(0);
            }
        }
    }

    return bit.* - starting_bit;
}
