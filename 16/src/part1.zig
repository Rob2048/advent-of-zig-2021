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

var total_version_count: usize = 0;

pub fn main() anyerror!void {
    const file = try rob.File.loadFromPath("puzzle.txt");
    defer file.deinit();

    log("File size: {}", .{file.bytes.len});
    const input_str = file.bytes;
    // var input_str = "EE00D40C823060";
    // var input_str = "8A004A801A8002F478";
    // var input_str = "620080001611562C8802118E34";
    // var input_str = "C0015000016115A2E0802F182340";
    // var input_str = "A0016C880162017C3686B18A3D4780";

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

    var bit: usize = 0;
    total_version_count = 0;
    _ = parsePacket(byte_str, &bit);

    log("Done - Version sum: {}", .{total_version_count});
}

fn parsePacket(input: []const u8, bit: *usize) usize {
    const starting_bit = bit.*;

    const packet_version = readValue(input, bit, 3);
    const packet_type = readValue(input, bit, 3);
    log("New packet - Version: {} Type: {}", .{ packet_version, packet_type });
    total_version_count += packet_version;

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

        log("Literal: {}", .{literal_value});
    } else {
        // Operator packet.
        const length_type_id = readValue(input, bit, 1);
        log("Operator packet: {}", .{length_type_id});

        if (length_type_id == 0) {
            const subpacket_bit_count = readValue(input, bit, 15);
            log("subpacket_bit_count: {}", .{subpacket_bit_count});

            var read_packet_bits: usize = 0;

            while (read_packet_bits < subpacket_bit_count) {
                read_packet_bits += parsePacket(input, bit);
            }
        } else {
            var subpacket_count = readValue(input, bit, 11);
            log("subpacket_count: {}", .{subpacket_count});

            while (subpacket_count > 0) : (subpacket_count -= 1) {
                _ = parsePacket(input, bit);
            }
        }
    }

    return bit.* - starting_bit;
}
