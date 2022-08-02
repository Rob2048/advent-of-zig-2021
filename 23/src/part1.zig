const std = @import("std");
const log = std.log.info;
const assert = std.debug.assert;

const MinHeap = struct {
    allocator: std.mem.Allocator = undefined,
    nodes: std.ArrayList(usize) = undefined,
    backing: *std.ArrayList(State) = undefined,

    pub fn init(allocator: std.mem.Allocator, backing: *std.ArrayList(State)) MinHeap {
        return MinHeap{
            .allocator = allocator,
            .nodes = std.ArrayList(usize).init(allocator),
            .backing = backing,
        };
    }

    pub fn deinit(self: *MinHeap) void {
        self.nodes.deinit();
    }

    pub fn debugPrint(self: MinHeap) void {
        log("Heap info - Size: {}", .{self.nodes.items.len});

        for (self.nodes.items) |node, index| {
            const backing_node = self.backing.items[node];
            log("Node {}({}): Cost: {} Backing: {}", .{ index, backing_node.heap_index, backing_node.cost, node });
        }
    }

    pub fn add(self: *MinHeap, node: usize) !void {
        self.backing.items[node].heap_index = self.nodes.items.len;
        try self.nodes.append(node);
        self.update(node);
    }

    pub fn remove(self: *MinHeap, node: usize) void {
        const last_node = self.nodes.items[self.nodes.items.len - 1];
        self.swapNodes(node, last_node);
        _ = self.nodes.pop();
        self.update(last_node);
    }

    pub fn pop(self: *MinHeap) ?usize {
        if (self.nodes.items.len == 0) {
            return null;
        }

        const top_node = self.nodes.items[0];
        self.remove(top_node);

        return top_node;
    }

    pub fn update(self: *MinHeap, node: usize) void {
        // Has parent?
        if (self.backing.items[node].heap_index > 0) {
            var parent_node = self.getNodeFromIndex((self.backing.items[node].heap_index - 1) / 2).?;

            if (self.backing.items[node].cost < self.backing.items[parent_node].cost) {
                var sift_node_parent: usize = parent_node;
                while (self.backing.items[sift_node_parent].cost > self.backing.items[node].cost) {
                    self.swapNodes(sift_node_parent, node);

                    if (self.backing.items[node].heap_index == 0) {
                        // Balanced.
                        return;
                    }

                    sift_node_parent = self.getNodeFromIndex((self.backing.items[node].heap_index - 1) / 2).?;
                }

                return;
            } else if (self.backing.items[node].cost == self.backing.items[parent_node].cost) {
                // Tree is balanced.
                return;
            }
        }

        // Sift down
        while (true) {
            var child_node_a = self.getNodeFromIndex(self.backing.items[node].heap_index * 2 + 1) orelse {
                // Could not get child A, so balanced.
                return;
            };

            var child_node_b = self.getNodeFromIndex(self.backing.items[node].heap_index * 2 + 2);

            var smallest_child: usize = child_node_a;

            if (child_node_b) |child_b| {
                if (self.backing.items[child_b].cost < self.backing.items[smallest_child].cost) {
                    smallest_child = child_b;
                }
            }

            if (self.backing.items[smallest_child].cost >= self.backing.items[node].cost) {
                // Balanced.
                return;
            }

            self.swapNodes(smallest_child, node);
        }
    }

    pub fn getNodeFromIndex(self: *MinHeap, node_index: usize) ?usize {
        if (node_index >= self.nodes.items.len) {
            return null;
        }

        return self.nodes.items[node_index];
    }

    pub fn swapNodes(self: *MinHeap, a: usize, b: usize) void {
        const a_index = self.backing.items[a].heap_index;
        const b_index = self.backing.items[b].heap_index;

        self.nodes.items[self.backing.items[b].heap_index] = a;
        self.nodes.items[self.backing.items[a].heap_index] = b;

        self.backing.items[a].heap_index = b_index;
        self.backing.items[b].heap_index = a_index;
    }
};

const State = struct {
    const visited: usize = std.math.maxInt(usize);

    index: usize = 0,
    state: i64 = 0,
    cost: i64 = 0,
    heap_index: usize = 0,
    prev_state_index: usize = 0,

    // States (3bit):
    // 0 - empty
    // 1 - A
    // 2 - B
    // 3 - C
    // 4 - D
    // 5 - locked

    pub fn fromStartCondition(values: []const u8) State {
        var result = State{};

        for (values) |value, index| {
            const room = index / 2;
            const cell = index + 7;
            const cell_type = value - 'A';

            if (room == cell_type and index % 2 == 1) {
                result.setCell(cell, 5);
            } else {
                result.setCell(cell, cell_type + 1);
            }
        }

        return result;
    }

    pub fn advance(self: State, src: usize, dst: usize, cost: i64) State {
        const src_value = self.getCell(src);

        var result = State{
            .state = self.state,
            .cost = self.cost + multiplier_table[src_value] * cost,
            .prev_state_index = self.index,
        };

        if (dst > 6) {
            result.setCell(dst, 5);
        } else {
            result.setCell(dst, src_value);
        }

        result.setCell(src, 0);

        return result;
    }

    pub fn debugPrint(self: State) void {
        std.debug.print("State: {} Heap: {} Cost: {}\n", .{ self.state, self.heap_index, self.cost });

        var cells: [15]u8 = undefined;
        for (cells) |*c, index| {
            c.* = @intCast(u8, (self.state >> @intCast(u6, index * 3)) & 0x7);
        }

        for (cells[0..7]) |c, index| {
            if (index >= 2 and index <= 5) {
                std.debug.print("- ", .{});
            }

            std.debug.print("{c} ", .{State.getPrintChar(c)});
        }
        std.debug.print("\n", .{});

        std.debug.print("    {c}   {c}   {c}   {c}\n", .{
            State.getPrintChar(cells[7]),
            State.getPrintChar(cells[9]),
            State.getPrintChar(cells[11]),
            State.getPrintChar(cells[13]),
        });

        std.debug.print("    {c}   {c}   {c}   {c}\n", .{
            State.getPrintChar(cells[8]),
            State.getPrintChar(cells[10]),
            State.getPrintChar(cells[12]),
            State.getPrintChar(cells[14]),
        });
    }

    fn getPrintChar(char: u8) u8 {
        return switch (char) {
            0 => '.',
            1 => 'A',
            2 => 'B',
            3 => 'C',
            4 => 'D',
            5 => 'x',
            else => '#',
        };
    }

    pub inline fn getCell(self: State, index: usize) u8 {
        return @intCast(u8, (self.state >> @intCast(u6, index * 3)) & 0x7);
    }

    pub inline fn setCell(self: *State, index: usize, value: u8) void {
        var new_state = self.state;

        new_state &= ~(@as(i64, 0x7) << @intCast(u6, index * 3));
        new_state |= @as(i64, value) << @intCast(u6, index * 3);

        self.state = new_state;
    }

    pub inline fn isFinishCondition(self: State) bool {
        const value: usize = comptime result: {
            var result: usize = 0;
            var room_iter: usize = 7;
            while (room_iter < 15) : (room_iter += 1) {
                result |= 5 << (room_iter * 3);
            }
            break :result result;
        };

        return (self.state == value);
    }
};

const WalkEntry = struct {
    src: usize = 0,
    dst: usize = 0,
    mask: i64 = 0,
    moves: i64 = 100000,
};

var states: std.ArrayList(State) = undefined;
var state_lookup: std.AutoHashMap(i64, usize) = undefined;
var min_heap: MinHeap = undefined;
const multiplier_table = [_]i64{ 0, 1, 10, 100, 1000 };
var walk_table: std.AutoHashMap(i64, WalkEntry) = undefined;

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    states = std.ArrayList(State).init(allocator);
    defer states.deinit();

    state_lookup = std.AutoHashMap(i64, usize).init(allocator);
    defer state_lookup.deinit();

    min_heap = MinHeap.init(allocator, &states);
    defer min_heap.deinit();

    try generateWalkTable(allocator);
    defer walk_table.deinit();

    // var initial_state = State.fromStartCondition(&[_]u8{'B', 'A', 'C', 'D', 'B', 'C', 'D', 'A'});
    var initial_state = State.fromStartCondition(&[_]u8{'C', 'B', 'D', 'A', 'D', 'B', 'A', 'C'});
    try state_lookup.put(initial_state.state, states.items.len);
    try states.append(initial_state);

    log("Starting state:", .{});
    initial_state.debugPrint();

    var iter_count: usize = 100000;
    var active_state_index: ?usize = 0;
    while (active_state_index) |active_index| {
        const active_state = states.items[active_index];

        // Spawn all possible additional moves as states.
        // log("Start visit:", .{});
        // active_state.debugPrint();

        if (active_state.isFinishCondition()) {
            log("Found end condition {}", .{active_state.cost});

            // Trace states
            var trace_state = active_state;
            while (true) {
                trace_state.debugPrint();

                if (trace_state.index == 0) {
                    break;
                }

                trace_state = states.items[trace_state.prev_state_index];
            }

            break;
        }

        // Check hallwayers.
        const hallwayers_moved = hallwayers: {
            var hall_iter: usize = 0;
            while (hall_iter < 7) : (hall_iter += 1) {
                const src = hall_iter;
                const cell = active_state.getCell(src);

                if (cell > 0 and cell < 5) {
                    // NOTE: Only go home if there are no rogues.
                    const home0 = active_state.getCell(5 + (cell * 2));
                    const home1 = active_state.getCell(6 + (cell * 2));
                    if (home0 == 0 and (home1 == 0 or home1 == 5)) {
                        if (try checkMoveAndPushState(&active_state, src, 6 + (cell * 2))) {
                            break :hallwayers true;
                        }

                        if (try checkMoveAndPushState(&active_state, src, 5 + (cell * 2))) {
                            break :hallwayers true;
                        }
                    }
                }
            }

            break :hallwayers false;
        };

        // Check roomers.
        if (!hallwayers_moved) {
            roomers: {
                var room_iter: usize = 7;
                while (room_iter < 15) : (room_iter += 1) {
                    const src = room_iter;
                    const cell = active_state.getCell(src);

                    if (cell > 0 and cell < 5) {
                        // NOTE: Only go home if there are no rogues.
                        const home0 = active_state.getCell(5 + (cell * 2));
                        const home1 = active_state.getCell(6 + (cell * 2));
                        if (home0 == 0 and (home1 == 0 or home1 == 5)) {
                            if (try checkMoveAndPushState(&active_state, src, 6 + (cell * 2))) {
                                break :roomers;
                            }

                            if (try checkMoveAndPushState(&active_state, src, 5 + (cell * 2))) {
                                break :roomers;
                            }
                        }

                        // Attempt all moves.
                        var hall_iter: usize = 0;
                        while (hall_iter < 7) : (hall_iter += 1) {
                            // log("Try {} to {}", .{ src, hall_iter });
                            _ = try checkMoveAndPushState(&active_state, src, hall_iter);
                        }
                    }
                }
            }
        }

        // Set this state as visited.
        states.items[active_index].heap_index = State.visited;
        // Set the active state to the next best state to visit.
        active_state_index = min_heap.pop();

        iter_count -= 1;
        if (iter_count == 0) {
            break;
        }
    }

    log("Iter: {}", .{iter_count});
    log("Backing node count: {}", .{states.items.len});
    log("Heap count: {}", .{min_heap.nodes.items.len});
}

fn checkMoveAndPushState(state: *const State, src: usize, dst: usize) !bool {
    const path = getWalkTable(src, dst);
    if (state.state & path.mask == 0) {
        // log("Can move from {} to {} for {}", .{ src, dst, path.moves });
        const new_state = state.advance(src, dst, path.moves);
        // new_state.debugPrint();
        try addNewState(new_state);

        return true;
    } else {
        // log("Can't move from {} to {}", .{ src, dst });
    }

    return false;
}

fn addNewState(state: State) !void {
    if (state_lookup.get(state.state)) |existing_state_index| {
        var existing_state = &states.items[existing_state_index];

        if (existing_state.heap_index == State.visited) {
            if (state.cost < existing_state.cost) {
                log("Visited already", .{});
            }
            return;
        } else {
            if (state.cost < existing_state.cost) {
                existing_state.cost = state.cost;
                existing_state.prev_state_index = state.prev_state_index;
                min_heap.update(existing_state_index);
            }
        }
    } else {
        // State doesn't exist, so add.
        var new_state = state;
        new_state.index = states.items.len;
        try states.append(new_state);
        try state_lookup.put(new_state.state, new_state.index);
        try min_heap.add(new_state.index);
    }
}

fn getWalkTable(src: usize, dst: usize) WalkEntry {
    const hash = (@intCast(i64, src) << 32) | @intCast(i64, dst);

    return walk_table.get(hash).?;
}

fn addWalkTableEntry(cells: []const usize, moves: i64) !void {
    {
        const src = cells[0];
        const dst = cells[cells.len - 1];

        var entry = WalkEntry{
            .src = src,
            .dst = dst,
            .moves = moves,
        };

        for (cells[1..]) |cell| {
            entry.mask |= @as(i64, 0x7) << @intCast(u6, (cell * 3));
        }

        const hash = (@intCast(i64, src) << 32) | @intCast(i64, dst);
        try walk_table.put(hash, entry);
    }

    {
        const src = cells[cells.len - 1];
        const dst = cells[0];

        var entry = WalkEntry{
            .src = src,
            .dst = dst,
            .moves = moves,
        };

        for (cells[0 .. cells.len - 1]) |cell| {
            entry.mask |= @as(i64, 0x7) << @intCast(u6, (cell * 3));
        }

        const hash = (@intCast(i64, src) << 32) | @intCast(i64, dst);
        try walk_table.put(hash, entry);
    }
}

fn generateWalkTable(allocator: std.mem.Allocator) !void {
    walk_table = std.AutoHashMap(i64, WalkEntry).init(allocator);

    var total_pairs: usize = 0;

    var cell_list = [_]usize{0} ** 32;
    var cell_count: usize = 0;

    var src_iter: i64 = 0;
    while (src_iter < 15) : (src_iter += 1) {
        var dst_iter: i64 = src_iter + 1;
        while (dst_iter < 15) : (dst_iter += 1) {
            cell_count = 0;

            // Start in hallway.
            if (src_iter < 7 or dst_iter < 7) {
                // Hallway to hallway is banned.
                if (src_iter < 7 and dst_iter < 7) {
                    continue;
                }

                log("Pair {}: {} -> {}", .{ total_pairs, src_iter, dst_iter });
                total_pairs += 1;

                // NOTE: src will always be < dst due to search order.
                var src: i64 = src_iter;
                var dst: i64 = dst_iter;

                const dst_room: i64 = @divTrunc((dst - 7), 2);
                const entry0: i64 = dst_room + 1;
                const entry1: i64 = dst_room + 2;

                var move_count: i64 = std.math.min((try std.math.absInt(entry0 - src)), (try std.math.absInt(entry1 - src))) * 2 + 1;
                if (src == 0 or src == 6) {
                    move_count -= 1;
                }

                var entry_cell: i64 = entry0;
                if ((try std.math.absInt(entry0 - src)) > (try std.math.absInt(entry1 - src))) {
                    entry_cell = entry1;
                }

                var step: i64 = 0;
                if (src < entry_cell) {
                    step = 1;
                }
                if (src > entry_cell) {
                    step = -1;
                }

                var step_iter: i64 = src;
                while (true) : (step_iter += step) {
                    cell_list[cell_count] = @intCast(usize, step_iter);
                    cell_count += 1;

                    if (step_iter == entry_cell) {
                        break;
                    }
                }

                var room_step_count: i64 = @mod((dst - 7), 2) + 1;

                move_count += room_step_count;

                var room_step_iter: i64 = 0;
                while (room_step_iter < room_step_count) : (room_step_iter += 1) {
                    cell_list[cell_count] = @intCast(usize, dst_room * 2 + 7 + room_step_iter);
                    cell_count += 1;
                }

                log("Moves: {any} {}", .{ cell_list[0..cell_count], move_count });
                try addWalkTableEntry(cell_list[0..cell_count], move_count);
            } else {
                // NOTE: src will always be < dst due to search order.
                var src: i64 = src_iter;
                var dst: i64 = dst_iter;

                const src_room: i64 = @divTrunc((src - 7), 2);
                const dst_room: i64 = @divTrunc((dst - 7), 2);

                // Room to same room is banned.
                if (src_room == dst_room) {
                    continue;
                }

                // Room to other room:
                log("Pair {}: {} -> {}", .{ total_pairs, src_iter, dst_iter });
                total_pairs += 1;

                var move_count: i64 = 0;

                var src_exit_iter: i64 = @mod((src - 7), 2);
                while (true) : (src_exit_iter -= 1) {
                    cell_list[cell_count] = @intCast(usize, src_room * 2 + 7 + src_exit_iter);
                    cell_count += 1;
                    move_count += 1;

                    if (src_exit_iter == 0) {
                        break;
                    }
                }

                const src_entry: i64 = src_room + 2;
                const dst_entry: i64 = dst_room + 1;

                var step_iter: i64 = src_entry;
                while (true) : (step_iter += 1) {
                    cell_list[cell_count] = @intCast(usize, step_iter);
                    cell_count += 1;
                    move_count += 2;

                    if (step_iter == dst_entry) {
                        break;
                    }
                }

                var room_step_count: i64 = @mod((dst - 7), 2) + 1;
                var room_step_iter: i64 = 0;
                while (room_step_iter < room_step_count) : (room_step_iter += 1) {
                    cell_list[cell_count] = @intCast(usize, dst_room * 2 + 7 + room_step_iter);
                    cell_count += 1;
                    move_count += 1;
                }

                log("Moves: {any} {}", .{ cell_list[0..cell_count], move_count });
                try addWalkTableEntry(cell_list[0..cell_count], move_count);
            }
        }
    }
}

// 0 1 . 2 . 3 . 4 . 5 6
//     7   9   11  13
//     8   10  12  14

//     0   1   2   3
