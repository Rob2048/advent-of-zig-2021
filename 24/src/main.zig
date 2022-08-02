const std = @import("std");
const rob = @import("rob.zig");
const log = std.log.info;
const assert = std.debug.assert;
pub const log_level: std.log.Level = .info;

const VirtualMachine = struct {
    program: std.ArrayList(Instruction),
    pc: usize = 0,
    reg: [4]i64 = [_]i64{0} ** 4,
    input: [14]u8 = [_]u8{0} ** 14,
    input_ptr: usize = 0,

    pub fn init(allocator: std.mem.Allocator) VirtualMachine {
        return VirtualMachine{
            .program = std.ArrayList(Instruction).init(allocator),
        };
    }

    pub fn deinit(self: *VirtualMachine) void {
        self.program.deinit();
    }

    pub fn reset(self: *VirtualMachine) void {
        self.pc = 0;
        self.reg = [_]i64{0} ** 4;
        self.input_ptr = 0;
    }

    pub fn printRegs(self: VirtualMachine) void {
        std.debug.print("Regs: PC={d:<6} X={d:<6} Y={d:<6} Z={d:<6} W={d:<6}\n", .{ self.pc, self.reg[1], self.reg[2], self.reg[3], self.reg[0] });
    }

    pub fn pushInstruction(self: *VirtualMachine, instruction: Instruction) !void {
        try self.program.append(instruction);
    }

    pub fn step(self: *VirtualMachine) void {
        if (self.pc >= self.program.items.len) {
            return;
        }

        const inst = self.program.items[self.pc];
        switch (inst.opcode) {
            .inp => {
                self.reg[inst.operand_a] = self.input[self.input_ptr];
                self.input_ptr += 1;
                self.printRegs();
            },
            .add => {
                self.reg[inst.operand_a] = self.reg[inst.operand_a] + self.getOperandB(inst);
            },
            .mul => {
                self.reg[inst.operand_a] = self.reg[inst.operand_a] * self.getOperandB(inst);
            },
            .div => {
                self.reg[inst.operand_a] = @divTrunc(self.reg[inst.operand_a], self.getOperandB(inst));
            },
            .mod => {
                self.reg[inst.operand_a] = @mod(self.reg[inst.operand_a], self.getOperandB(inst));
            },
            .eql => {
                self.reg[inst.operand_a] = if (self.reg[inst.operand_a] == self.getOperandB(inst)) 1 else 0;
            },
        }

        self.pc += 1;
    }

    pub fn run(self: *VirtualMachine, trace: bool) void {
        while (self.pc < self.program.items.len) {
            if (trace) {
                self.program.items[self.pc].print();
            }

            self.step();

            if (trace) {
                self.printRegs();
            }
        }
    }

    fn getOperandB(self: VirtualMachine, instruction: Instruction) i64 {
        if (instruction.operand_b_literal) {
            return instruction.operand_b;
        } else {
            assert(instruction.operand_b >= 0 and instruction.operand_b <= 3);
            return self.reg[@intCast(usize, instruction.operand_b)];
        }
    }
};

const Instruction = struct {
    pub const Opcode = enum { inp, add, mul, div, mod, eql };

    opcode: Opcode,
    operand_a: usize = 0,
    operand_b_literal: bool = false,
    operand_b: i64 = 0,

    pub fn createOne(opcode: Opcode, operand_a: u8) Instruction {
        return Instruction{
            .opcode = opcode,
            .operand_a = operand_a - 'w',
        };
    }

    pub fn createReg(opcode: Opcode, operand_a: u8, operand_b: u8) Instruction {
        assert(operand_b >= 'w' and operand_b <= 'z');

        return Instruction{
            .opcode = opcode,
            .operand_a = operand_a - 'w',
            .operand_b = operand_b - 'w',
        };
    }

    pub fn createLit(opcode: Opcode, operand_a: u8, operand_b: i64) Instruction {
        return Instruction{
            .opcode = opcode,
            .operand_a = operand_a - 'w',
            .operand_b_literal = true,
            .operand_b = operand_b,
        };
    }

    pub fn print(self: Instruction) void {
        if (self.operand_b_literal) {
            std.debug.print("{} {c} {}\n", .{ self.opcode, @intCast(u8, self.operand_a + 'w'), self.operand_b });
        } else {
            std.debug.print("{} {c} {c}\n", .{ self.opcode, @intCast(u8, self.operand_a + 'w'), @intCast(u8, self.operand_b + 'w') });
        }
    }
};

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var vm = VirtualMachine.init(allocator);
    defer vm.deinit();

    const file = try rob.File.loadFromPath("puzzle.txt");
    defer file.deinit();

    var line_iter = std.mem.split(u8, file.bytes, "\r\n");
    while (line_iter.next()) |line| {
        var param_iter = std.mem.split(u8, line, " ");

        const op_str = param_iter.next().?;
        const op_a = param_iter.next().?;
        const op_b_str = param_iter.next();

        if (std.mem.eql(u8, op_str, "inp")) {
            try vm.pushInstruction(Instruction.createOne(.inp, op_a[0]));
        } else {
            const opcode = std.meta.stringToEnum(Instruction.Opcode, op_str).?;
            const op_b = op_b_str.?;

            if (op_b[0] == 'w' or op_b[0] == 'x' or op_b[0] == 'y' or op_b[0] == 'z') {
                try vm.pushInstruction(Instruction.createReg(opcode, op_a[0], op_b[0]));
            } else {
                try vm.pushInstruction(Instruction.createLit(opcode, op_a[0], try std.fmt.parseInt(i64, op_b, 10)));
            }
        }

        // log("{s} {s} {any}", .{ op_str, op_a, op_b });
    }

    log("Program size: {}", .{vm.program.items.len});
    // for (vm.program.items) |instruction| {
    //     instruction.print();
    // }

    // var input_iter0: usize = 1;
    // while (input_iter0 <= 9) : (input_iter0 += 1) {
    //     const input = @intCast(u8, input_iter0);
    //     vm.reset();
    //     // vm.input = [_]u8{ 9, 1, 1, 3, 1, 1, 5, 1, 9, 1, 7, 8, 9, 3 };

    //     // vm.input = [_]u8{ 1, 1, 1, 3, 1, 1, 5, 1, 9, 1, 4, 1, 7, 9 };
    //     // vm.input = [_]u8{ 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9 };

    //     // vm.input = [_]u8{ 9, 9, 9, 9, 7, 3, 9, 5, 9, 1, 9, 3, 9, 1 };
    //     // vm.input = [_]u8{ 9, 9, 9, 9, 7, 3, 9, 5, 9, 1, 9, 3, 9, 1 };
    //                  9, 1, 2, 9, 7, 3, 9, 5, 9, 1, 9, 9, 9, 3

    //     // vm.input = [_]u8{ 8, 1, 1, 3, 1, 1, 5, 1, 9, 1, 7, 8, 9, input };

    //     vm.input = [_]u8{ 9, 1, 1, 3, 1, 1, 5, 1, 9, 1, 7, 8, 9, input };

    //     // Valid:
    //     // 9, 1, 1, 3, 1, 1, 5, 1, 9, 1, 7, 8, 9, 3

    //        9, 1, 2, 9, 7, 3, 9, 5, 9, 1, 9, 9, 9, 3

    //     //.input = [_]u8{ ^, ^, ^, 3, ^, ^, 5, ^, 9, -, 4/5, -, 7, 9 (but incs?) };

    //     std.debug.print("\nInput: {d:<4}   \n", .{input});
    //     vm.run(false);
    //     vm.printRegs();
    // }

    // all 1's   470 309 775
    // all 9's 3 040 489 031

    // 779225551

    // var found: bool = false;

    // var input_iter0: usize = 1;
    // while (input_iter0 <= 9) : (input_iter0 += 1) {
    //     var z_iter: i64 = -1000000;
    //     while (z_iter <= 1000000) : (z_iter += 1) {
    //         // std.debug.print("Input: {d:<4} Z={d:<4}  ", .{input_iter0, z_iter});
    //         vm.reset();
    //         vm.input[0] = @intCast(u8, input_iter0);
    //         vm.reg[3] = z_iter;
    //         vm.run(false);

    //         if (vm.reg[3] == -11) {
    //             std.debug.print("Input: {d:<4} Z={d:<4}  ", .{ input_iter0, z_iter });
    //             vm.printRegs();
    //             // log("FOUND", .{});
    //             found = true;
    //         }
    //     }
    // }

    // log("Found: {}", .{found});

    // var it_count: i64 = 0;
    var iter: i64 = 1;
    while (iter <= 1) : (iter += 1) {
        var output: i64 = 0;
        output = progSection(9, output, 1, 14, 0); //o * 26 + inp + c
        log("{}", .{output});
        output = progSection(9, output, 1, 13, 12);
        log("{}", .{output});
        output = progSection(9, output, 1, 15, 14);
        log("{}", .{output});
        output = progSection(9, output, 1, 13, 0);
        log("{}", .{output});
        output = progSection(1, output, 26, -2, 3);
        log("{}", .{output});
        output = progSection(1, output, 1, 10, 15);
        log("{}", .{output});
        output = progSection(1, output, 1, 13, 11);
        log("{}", .{output});
        output = progSection(1, output, 26, -15, 12);
        log("{}", .{output});
        output = progSection(1, output, 1, 11, 1);
        log("{}", .{output});
        output = progSection(1, output, 26, -9, 12);
        log("{}", .{output});
        output = progSection(1, output, 26, -9, 3);
        log("{}", .{output});
        output = progSection(1, output, 26, -7, 10);
        log("{}", .{output});
        output = progSection(1, output, 26, -4, 14);
        log("{}", .{output});
        output = progSection(1, output, 26, -6, 12);
        log("{}", .{output});

        log("", .{});
    }

    // 9, 9, 9, 9, 7, 3, 9, 5, 9, 1, 9, 3, 9, 1
    // 9, 1, 2, 9, 7, 3, 9, 5, 9, 1, 9, 9, 9, 3
    // 9, 1, 1, 3, 1, 1, 5, 1, 9, 1, 7, 8, 9, 3

    // log("Full {}", .{progFullSection()});

    // var digit_iter: usize = 2541865828329;
    // while (digit_iter >= 0) : (digit_iter -= 1) {
    //     const dig1 = @intCast(i64, digit_iter % 9 + 1);
    //     const dig2 = @intCast(i64, (digit_iter / 9) % 9 + 1);
    //     const dig3 = @intCast(i64, (digit_iter / 81) % 9 + 1);
    //     const dig4 = @intCast(i64, (digit_iter / 729) % 9 + 1);
    //     const dig5 = @intCast(i64, (digit_iter / 6561) % 9 + 1);
    //     const dig6 = @intCast(i64, (digit_iter / 59049) % 9 + 1);
    //     const dig7 = @intCast(i64, (digit_iter / 531441) % 9 + 1);
    //     const dig8 = @intCast(i64, (digit_iter / 4782969) % 9 + 1);
    //     const dig9 = @intCast(i64, (digit_iter / 43046721) % 9 + 1);
    //     const dig10 = @intCast(i64, (digit_iter / 387420489) % 9 + 1);
    //     const dig11 = @intCast(i64, (digit_iter / 3486784401) % 9 + 1);
    //     const dig12 = @intCast(i64, (digit_iter / 31381059609) % 9 + 1);
    //     const dig13 = @intCast(i64, (digit_iter / 282429536481) % 9 + 1);

    //     // 2541865828329

    //     const result = progFullSection(&[_]i64{9, dig13, dig12, dig11, dig10, dig9, dig8, dig7, dig6, dig5, dig4, dig3, dig2, dig1});

    //     if (digit_iter % 1000000000 == 0) {
    //         log("{} = 9 {} {} {} {} {} {} {} {} {} {} {} {} {}", .{digit_iter, dig13, dig12, dig11, dig10, dig9, dig8, dig7, dig6, dig5, dig4, dig3, dig2, dig1});
    //     }

    //     if (result == 0) {
    //         log("RESULT = 9 {} {} {} {} {} {} {} {} {} {} {} {} {}", .{dig13, dig12, dig11, dig10, dig9, dig8, dig7, dig6, dig5, dig4, dig3, dig2, dig1});
    //     }
    // }

    // NOTE: Brute force ^_^'.
    const thread_count: usize = 20;

    //  1 =  38 500 000
    //  4 = 150 700 000
    //  8 = 292 300 000
    // 16 = 424 800 000
    // 20 = 497 400 000
    // 24 = 582 700 000
    var thread_iter: usize = 0;
    var threads: [thread_count]std.Thread = undefined;

    while (thread_iter < thread_count) : (thread_iter += 1) {
        const batch_size: usize = 22876792454961 / thread_count;
        const start: usize = batch_size * thread_iter;
        const end: usize = start + batch_size;
        log("Thread ({}): {} {}", .{ thread_iter, start, end });
        threads[thread_iter] = try std.Thread.spawn(.{}, runBatch, .{ start, end, thread_iter });
    }

    while (true) {
        std.time.sleep(std.time.ns_per_s * 60);
        const progress = getCounter();
        log("{}/{} = {d:.3} %", .{ progress, 22876792454961, (@intToFloat(f64, progress) / 22876792454961.0) * 100 });

        if (progress >= 22876792454961 - 1000000) {
            break;
        }
    }

    // while (true) {
    //     std.time.sleep(std.time.ns_per_s);
    //     log("{} hashes/s", .{getAndResetCounter()});
    // }

    // thread_iter = 0;
    // while (thread_iter < thread_count) : (thread_iter += 1) {
    //     threads[thread_iter].join();
    // }

    // Largest valid: 9 1 2 9 7 3 9 5 9 1 9 9 9 3
}

var counter_lock = std.Thread.Mutex{};
var counter: usize = 0;

fn updateCounter(inc: usize) void {
    counter_lock.lock();
    defer counter_lock.unlock();

    counter += inc;
}

fn getCounter() usize {
    counter_lock.lock();
    defer counter_lock.unlock();
    return counter;
}

fn getAndResetCounter() usize {
    counter_lock.lock();
    defer counter_lock.unlock();
    var result = counter;
    counter = 0;
    return result;
}

fn runBatch(start: usize, end: usize, thread_id: usize) void {
    var digit_iter: usize = start;
    _ = thread_id;

    while (digit_iter < end) : (digit_iter += 1) {
        const dig1 = @intCast(i64, digit_iter % 9 + 1);
        const dig2 = @intCast(i64, (digit_iter / 9) % 9 + 1);
        const dig3 = @intCast(i64, (digit_iter / 81) % 9 + 1);
        const dig4 = @intCast(i64, (digit_iter / 729) % 9 + 1);
        const dig5 = @intCast(i64, (digit_iter / 6561) % 9 + 1);
        const dig6 = @intCast(i64, (digit_iter / 59049) % 9 + 1);
        const dig7 = @intCast(i64, (digit_iter / 531441) % 9 + 1);
        const dig8 = @intCast(i64, (digit_iter / 4782969) % 9 + 1);
        const dig9 = @intCast(i64, (digit_iter / 43046721) % 9 + 1);
        const dig10 = @intCast(i64, (digit_iter / 387420489) % 9 + 1);
        const dig11 = @intCast(i64, (digit_iter / 3486784401) % 9 + 1);
        const dig12 = @intCast(i64, (digit_iter / 31381059609) % 9 + 1);
        const dig13 = @intCast(i64, (digit_iter / 282429536481) % 9 + 1);
        const dig14 = @intCast(i64, (digit_iter / 2541865828329) % 9 + 1);

        const result = progFullSection(&[_]i64{ dig14, dig13, dig12, dig11, dig10, dig9, dig8, dig7, dig6, dig5, dig4, dig3, dig2, dig1 });

        const hashes: usize = digit_iter - start;
        const report_size: usize = 10_000_000;
        if (hashes % report_size == 0) {
            // log("({}) {} = {} {} {} {} {} {} {} {} {} {} {} {} {} {}", .{ thread_id, digit_iter, dig14, dig13, dig12, dig11, dig10, dig9, dig8, dig7, dig6, dig5, dig4, dig3, dig2, dig1 });
            updateCounter(report_size);
        }

        if (result == 0) {
            log("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX = {} {} {} {} {} {} {} {} {} {} {} {} {} {}", .{ dig14, dig13, dig12, dig11, dig10, dig9, dig8, dig7, dig6, dig5, dig4, dig3, dig2, dig1 });
        }
    }
}

fn progSection(input_w: i64, input_z: i64, var_a: i64, var_b: i64, var_c: i64) i64 {
    if (@mod(input_z, 26) + var_b == input_w) {
        return @divTrunc(input_z, var_a);
    } else {
        return @divTrunc(input_z, var_a) * 26 + input_w + var_c;
    }
}

inline fn progFullSection(num: []const i64) i64 {
    var input_z: i64 = 0;

    // 1, 14, 0
    input_z = num[0];

    // 1, 13, 12
    input_z = input_z * 26 + num[1] + 12;

    // 1, 15, 14
    if (@mod(input_z, 26) + 15 != num[2]) {
        input_z = input_z * 26 + num[2] + 14;
    }

    // 1, 13, 0
    if (@mod(input_z, 26) + 13 != num[3]) {
        input_z = input_z * 26 + num[3];
    }

    // 26, -2, 3
    if (@mod(input_z, 26) + -2 == num[4]) {
        input_z = @divTrunc(input_z, 26);
    } else {
        input_z = input_z + num[4] + 3;
    }

    // 1, 10, 15
    if (@mod(input_z, 26) + 10 != num[5]) {
        input_z = input_z * 26 + num[5] + 15;
    }

    // 1, 13, 11
    if (@mod(input_z, 26) + 13 != num[6]) {
        input_z = input_z * 26 + num[6] + 11;
    }

    // 26, -15, 12
    if (@mod(input_z, 26) + -15 == num[7]) {
        input_z = @divTrunc(input_z, 26);
    } else {
        input_z = input_z + num[7] + 12;
    }

    // 1, 11, 1
    if (@mod(input_z, 26) + 11 != num[8]) {
        input_z = input_z * 26 + num[8] + 1;
    }

    // 26, -9, 12
    if (@mod(input_z, 26) + -9 == num[9]) {
        input_z = @divTrunc(input_z, 26);
    } else {
        input_z = input_z + num[9] + 12;
    }

    // 26, -9, 3
    if (@mod(input_z, 26) + -9 == num[10]) {
        input_z = @divTrunc(input_z, 26);
    } else {
        input_z = input_z + num[10] + 3;
    }

    // 26, -7, 10
    if (@mod(input_z, 26) + -7 == num[11]) {
        input_z = @divTrunc(input_z, 26);
    } else {
        input_z = input_z + num[11] + 10;
    }

    // 26, -4, 14
    if (@mod(input_z, 26) + -4 == num[12]) {
        input_z = @divTrunc(input_z, 26);
    } else {
        input_z = input_z + num[12] + 14;
    }

    // 26, -6, 12
    if (@mod(input_z, 26) + -6 == num[13]) {
        input_z = @divTrunc(input_z, 26);
    } else {
        input_z = input_z + num[13] + 12;
    }

    return input_z;
}
