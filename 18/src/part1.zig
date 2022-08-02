const std = @import("std");
const rob = @import("rob.zig");
const log = std.log.info;
const assert = std.debug.assert;

const NodeEntry = struct {
    literal: usize = 0,
    node: ?*Node = null,
};

const Node = struct {
    index: usize = undefined,
    left: NodeEntry = NodeEntry{},
    right: NodeEntry = NodeEntry{},
    parent: ?*Node = null,

    pub fn debugPrint(self: *Node) void {
        std.debug.print("[", .{});

        if (self.left.node) |entry| {
            debugPrint(entry);
        } else {
            std.debug.print("{}", .{self.left.literal});
        }

        std.debug.print(",", .{});

        if (self.right.node) |entry| {
            debugPrint(entry);
        } else {
            std.debug.print("{}", .{self.right.literal});
        }

        std.debug.print("]", .{});

        if (self.parent == null) {
            std.debug.print("\n", .{});
        }
    }

    pub fn debugTree(self: *Node, depth: usize) void {
        if (self.parent) |parent| {
            printSpaces(depth);
            std.debug.print("Node ({}) Parent: {}\n", .{ self.index, parent.index });
        } else {
            printSpaces(depth);
            std.debug.print("Node ({}) Parent: -\n", .{self.index});
        }

        const new_depth = depth + 4;

        if (self.left.node) |entry| {
            debugTree(entry, new_depth);
        } else {
            printSpaces(new_depth);
            std.debug.print("literal: {}\n", .{self.left.literal});
        }

        if (self.right.node) |entry| {
            debugTree(entry, new_depth);
        } else {
            printSpaces(new_depth);
            std.debug.print("literal: {}\n", .{self.right.literal});
        }
    }

    fn addleft(self: *Node, literal: usize) void {
        var parent = self.parent orelse return; // Nothing found.

        if (parent.left.node == null) {
            parent.left.literal += literal;
            // Done.
        } else {
            if (parent.left.node == self) {
                // Leads back to us, so go up one.
                parent.addleft(literal);
            } else {
                parent.left.node.?.addRightDown(literal);
            }
        }
    }

    fn addRightDown(self: *Node, literal: usize) void {
        if (self.right.node == null) {
            self.right.literal += literal;
            // Done.
        } else {
            self.right.node.?.addRightDown(literal);
        }
    }

    fn addRight(self: *Node, literal: usize) void {
        var parent = self.parent orelse return; // Nothing found.

        if (parent.right.node == null) {
            parent.right.literal += literal;
            // Done.
        } else {
            if (parent.right.node == self) {
                // Leads back to us, so go up one.
                parent.addRight(literal);
            } else {
                parent.right.node.?.addLeftDown(literal);
            }
        }
    }

    fn addLeftDown(self: *Node, literal: usize) void {
        if (self.left.node == null) {
            self.left.literal += literal;
            // Done.
        } else {
            self.left.node.?.addLeftDown(literal);
        }
    }

    fn explode(self: *Node, entry: ?*NodeEntry, depth: usize) bool {
        const new_depth = depth + 1;

        if (depth == 4) {
            // Explode.
            // NOTE: Both entries should be literals.
            self.addleft(self.left.literal);
            self.addRight(self.right.literal);

            entry.?.node = null;
            entry.?.literal = 0;
            return true;
        }

        if (self.left.node) |node| {
            if (node.explode(&self.left, new_depth) == true) {
                return true;
            }
        }

        if (self.right.node) |node| {
            if (node.explode(&self.right, new_depth) == true) {
                return true;
            }
        }

        return false;
    }

    fn splitEntry(self: *Node, entry: *NodeEntry) anyerror!bool {
        if (entry.node == null) {
            if (entry.literal >= 10) {
                var new_node = try createNode();
                entry.node = new_node;
                new_node.parent = self;
                new_node.left.literal = entry.literal / 2;
                new_node.right.literal = (entry.literal + 1) / 2;
                return true;
            }
        } else {
            return try entry.node.?.split();
        }

        return false;
    }

    fn split(self: *Node) anyerror!bool {
        if (try self.splitEntry(&self.left)) {
            return true;
        }

        if (try self.splitEntry(&self.right)) {
            return true;
        }

        return false;
    }

    fn getMagnitude(self: *Node) usize {
        var result: usize = 0;

        if (self.left.node) |node| {
            result += 3 * getMagnitude(node);
        } else {
            result += 3 * self.left.literal;
        }

        if (self.right.node) |node| {
            result += 2 * getMagnitude(node);
        } else {
            result += 2 * self.right.literal;
        }

        return result;
    }
};

var nodes: std.ArrayList(Node) = undefined;

fn createNode() !*Node {
    try nodes.append(Node{ .index = nodes.items.len });

    return &nodes.items[nodes.items.len - 1];
}

fn printSpaces(num: usize) void {
    var iter: usize = 0;
    while (iter < num) : (iter += 1) {
        std.debug.print(" ", .{});
    }
}

fn createTree(input: []const u8) !*Node {
    var active_node: ?*Node = null;
    var current_entry: ?*NodeEntry = null;

    for (input) |char| {
        if (char == '[') {
            var new_node = try createNode();
            new_node.parent = active_node;

            if (current_entry) |entry| {
                entry.node = new_node;
            }

            active_node = new_node;
            current_entry = &new_node.left;
        } else if (char == ']') {
            if (active_node.?.parent) |parent| {
                active_node = parent;
            }
        } else if (char == ',') {
            current_entry = &active_node.?.right;
        } else {
            // Literal
            current_entry.?.literal = char - '0';
        }
    }

    return active_node.?;
}

fn addTrees(a: *Node, b: *Node) anyerror!*Node {
    var result = try createNode();
    result.left.node = a;
    result.right.node = b;

    a.parent = result;
    b.parent = result;

    result.debugPrint();

    // Reduce.
    while (true) {
        // Explode.
        if (result.explode(null, 0)) {
            // log("Exploded", .{});
            // result.debugPrint();
            continue;
        }

        // Split.
        if (try result.split()) {
            // log("Split", .{});
            // result.debugPrint();
            continue;
        }

        break;
    }

    return result;
}

pub fn main() anyerror!void {
    nodes = try std.ArrayList(Node).initCapacity(std.heap.page_allocator, 100000);
    defer nodes.deinit();

    // const file = try rob.File.loadFromPath("example.txt");
    const file = try rob.File.loadFromPath("puzzle.txt");
    defer file.deinit();
    log("File size: {}", .{file.bytes.len});
    const input_str = file.bytes;

    // const input_str = "[[6,[5,[4,[3,2]]]],1]";

    // var num_a = try createTree("[[[[4,3],4],4],[7,[[8,4],9]]]");
    // var num_b = try createTree("[1,1]");
    // num_a.debugPrint();
    // num_b.debugPrint();

    // var sum = try addTrees(num_a, num_b);
    // sum.debugPrint();

    var sum: ?*Node = null;

    var line_iter = std.mem.split(u8, input_str, "\r\n");
    while (line_iter.next()) |line| {
        var new_num = try createTree(line);
        log("New line num:", .{});
        new_num.debugPrint();

        if (sum == null) {
            sum = new_num;
        } else {
            sum = try addTrees(sum.?, new_num);
        }

        log("Sum:", .{});
        sum.?.debugPrint();
    }

    log("Nodes len: {}", .{nodes.items.len});

    const magnitude = sum.?.getMagnitude();
    log("Magnitude: {}", .{magnitude});
}
