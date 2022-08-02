const std = @import("std");
const rob = @import("rob.zig");
const assert = std.debug.assert;
const log = std.log.info;

const Node = struct {
    pub const State = enum {
        idle,
        active,
        done,
    };

    index: usize = 0,
    state: State = .idle,
    heap_index: usize = 0,
    risk: u8 = 0,
    shortest_index: ?usize = null,
    shortest_value: usize = 0,
};

const MinHeap = struct {
    allocator: std.mem.Allocator = undefined,

    nodes: std.ArrayList(*Node) = undefined,

    pub fn init(allocator: std.mem.Allocator) MinHeap {
        return MinHeap{
            .allocator = allocator,
            .nodes = std.ArrayList(*Node).init(allocator),
        };
    }

    pub fn deinit(self: *MinHeap) void {
        self.nodes.deinit();
    }

    pub fn debugPrint(self: MinHeap) void {
        log("Heap info - Size: {}", .{self.nodes.items.len});

        for (self.nodes.items) |node, index| {
            log("Node {}({}): Cost: {} Index: {}", .{ index, node.heap_index, node.shortest_value, node.index });
        }
    }

    pub fn add(self: *MinHeap, node: *Node) !void {
        node.heap_index = self.nodes.items.len;
        try self.nodes.append(node);
        self.update(node);
    }

    pub fn remove(self: *MinHeap, node: *Node) void {
        const last_node = self.nodes.items[self.nodes.items.len - 1];
        self.swapNodes(node, last_node);
        _ = self.nodes.pop();
        self.update(last_node);
    }

    pub fn pop(self: *MinHeap) ?*Node {
        if (self.nodes.items.len == 0) {
            return null;
        }

        const top_node = self.nodes.items[0];
        self.remove(top_node);

        return top_node;
    }

    pub fn update(self: *MinHeap, node: *Node) void {
        // Has parent?
        if (node.heap_index > 0) {
            var parent_node = self.getNodeFromIndex((node.heap_index - 1) / 2).?;

            if (node.shortest_value < parent_node.shortest_value) {
                var sift_node_parent: *Node = parent_node;
                while (sift_node_parent.shortest_value > node.shortest_value) {
                    self.swapNodes(sift_node_parent, node);

                    if (node.heap_index == 0) {
                        // Balanced.
                        return;
                    }

                    sift_node_parent = self.getNodeFromIndex((node.heap_index - 1) / 2).?;
                }

                return;
            } else if (node.shortest_value == parent_node.shortest_value) {
                // Tree is balanced.
                return;
            }
        }

        // Sift down
        while (true) {
            var child_node_a = self.getNodeFromIndex(node.heap_index * 2 + 1) orelse {
                // Could not get child A, so balanced.
                return;
            };

            var child_node_b = self.getNodeFromIndex(node.heap_index * 2 + 2);

            var smallest_child: *Node = child_node_a;

            if (child_node_b) |child_b| {
                if (child_b.shortest_value < smallest_child.shortest_value) {
                    smallest_child = child_b;
                }
            }

            if (smallest_child.shortest_value >= node.shortest_value) {
                // Balanced.
                return;
            }

            self.swapNodes(smallest_child, node);
        }
    }

    pub fn getNodeFromIndex(self: *MinHeap, node_index: usize) ?*Node {
        if (node_index >= self.nodes.items.len) {
            return null;
        }

        return self.nodes.items[node_index];
    }

    pub fn swapNodes(self: *MinHeap, a: *Node, b: *Node) void {
        const a_index = a.heap_index;
        const b_index = b.heap_index;

        self.nodes.items[b.heap_index] = a;
        self.nodes.items[a.heap_index] = b;

        a.heap_index = b_index;
        b.heap_index = a_index;
    }
};

pub fn main() anyerror!void {
    const allocator = std.heap.page_allocator;

    // const file = try rob.File.loadFromPath("example.txt");
    const file = try rob.File.loadFromPath("puzzle.txt");
    defer file.deinit();

    log("File size: {}", .{file.bytes.len});

    var cave_size: usize = 0;
    var cave = std.ArrayList(Node).init(allocator);
    defer cave.deinit();

    var line_iter = std.mem.split(u8, file.bytes, "\r\n");
    var line_index: usize = 0;
    while (line_iter.next()) |line| {
        if (cave_size == 0) {
            cave_size = line.len;
        }

        for (line) |char| {
            const risk: u8 = char - '0';

            try cave.append(Node{
                .index = cave.items.len,
                .risk = risk,
            });
        }

        line_index += 1;
    }

    assert(cave.items.len == cave_size * cave_size);

    // Draw grid.
    // for (cave.items) |cell, index| {
    //     if (index % cave_size == 0) {
    //         std.debug.print("\n", .{});
    //     }
    //     std.debug.print("{}", .{cell.risk});
    // }
    // std.debug.print("\n", .{});

    var heap = MinHeap.init(allocator);
    defer heap.deinit();

    // Start with starting node.
    var starting_node = &cave.items[0];
    starting_node.state = .active;
    starting_node.shortest_value = 0;
    try heap.add(starting_node);

    heap.debugPrint();

    while (true) {
        // Pop min node from heap.
        var active_node = heap.pop() orelse {
            log("No more nodes to pop!", .{});
            break;
        };

        active_node.state = .done;

        const x = active_node.index % cave_size;
        const y = active_node.index / cave_size;

        // If we are the ending node, then store the shortest path here.
        if (x == cave_size - 1 and y == cave_size - 1) {
            log("Found end node - Cost: {}", .{active_node.shortest_value});
            
            log("Path:", .{});
            while (active_node.shortest_index) |next_index| {
                const x_v = active_node.index % cave_size;
                const y_v = active_node.index / cave_size;

                log("Node {},{} {} {}", .{x_v, y_v, active_node.index, active_node.shortest_value});
                active_node = &cave.items[next_index];
            }

            break;
        }

        // log("Active node: {},{}", .{ x, y });

        if (x > 0) {
            try processNode(&cave, &heap, active_node, (x - 1) + y * cave_size);
        }

        if (x < cave_size - 1) {
            try processNode(&cave, &heap, active_node, (x + 1) + y * cave_size);
        }

        if (y > 0) {
            try processNode(&cave, &heap, active_node, x + (y - 1) * cave_size);
        }

        if (y < cave_size - 1) {
            try processNode(&cave, &heap, active_node, x + (y + 1) * cave_size);
        }
    }

    heap.debugPrint();
}

fn processNode(cave: *std.ArrayList(Node), heap: *MinHeap, active_node: *Node, target_index: usize) !void {
    var target_node = &cave.items[target_index];

    if (target_node.state != .done) {
        const cost: usize = active_node.shortest_value + target_node.risk;

        // log("Target index: {} Cost: {}", .{ target_index, cost });

        var update_node: bool = false;

        if (target_node.shortest_index) |_| {
            if (target_node.shortest_value > cost) {
                update_node = true;
            }
        } else {
            update_node = true;
        }

        if (update_node) {
            target_node.shortest_index = active_node.index;
            target_node.shortest_value = cost;

            if (target_node.state == .idle) {
                // Insert into heap.
                target_node.state = .active;
                try heap.add(target_node);
            } else if (target_node.state == .active) {
                // Update heap.
                heap.update(target_node);
            }
        }
    }
}
