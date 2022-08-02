const std = @import("std");
const assert = std.debug.assert;
const log = std.log.info;
const rob = @import("rob.zig");

const Node = struct {
    name: []const u8,
    small_cave: bool,
    links: std.ArrayList(*Node),
    visited: usize = 0,

    pub fn init(allocator: std.mem.Allocator, name: []const u8) Node {
        var result = Node{
            .name = name,
            .small_cave = false,
            .links = std.ArrayList(*Node).init(allocator),
        };

        if (name[0] >= 'a') {
            result.small_cave = true;
        }

        return result;
    }

    pub fn print(self: Node) void {
        log("{s} Small: {} LinkCount: {}", .{ self.name, self.small_cave, self.links.items.len });
    }
};

pub fn findNode(nodes: std.ArrayList(*Node), name: []const u8) ?*Node {
    for (nodes.items) |item| {
        if (std.mem.eql(u8, item.*.name, name)) {
            return item;
        }
    }

    return null;
}

const NodeVisit = struct {
    node: *Node,
    next_link_index: usize = 0,
    did_double_visit: bool = false,
};

pub fn main() anyerror!void {
    const allocator = std.heap.page_allocator;

    // const file = try rob.File.loadFromPath("example.txt");
    const file = try rob.File.loadFromPath("puzzle.txt");
    defer file.deinit();

    log("File size: {}", .{file.bytes.len});

    var nodes_backing = std.ArrayList(Node).init(allocator);
    defer nodes_backing.deinit();

    var nodes = std.ArrayList(*Node).init(allocator);
    defer nodes.deinit();

    var line_iter = std.mem.split(u8, file.bytes, "\r\n");
    while (line_iter.next()) |line| {
        var arg_iter = std.mem.split(u8, line, "-");

        const cave_name_a = arg_iter.next().?;
        const cave_name_b = arg_iter.next().?;

        log("{s} <-> {s}", .{ cave_name_a, cave_name_b });

        // Make sure the caves exist.
        var cave_a = findNode(nodes, cave_name_a) orelse newNode: {
            try nodes_backing.append(Node.init(allocator, cave_name_a));
            const node: *Node = &nodes_backing.items[nodes_backing.items.len - 1];
            try nodes.append(node);
            break :newNode node;
        };

        var cave_b = findNode(nodes, cave_name_b) orelse newNode: {
            try nodes_backing.append(Node.init(allocator, cave_name_b));
            const node: *Node = &nodes_backing.items[nodes_backing.items.len - 1];
            try nodes.append(node);
            break :newNode node;
        };

        // Make sure the caves link to each other.
        _ = findNode(cave_a.links, cave_name_b) orelse {
            try cave_a.links.append(cave_b);
        };

        _ = findNode(cave_b.links, cave_name_a) orelse {
            try cave_b.links.append(cave_a);
        };
    }

    log("Nodes:", .{});
    for (nodes.items) |node| {
        node.print();
    }

    var visit_stack = std.ArrayList(NodeVisit).init(allocator);
    defer visit_stack.deinit();

    const starting_node = findNode(nodes, "start").?;

    try visit_stack.append(NodeVisit{ .node = starting_node });
    starting_node.visited = 100;

    var path_count: usize = 0;

    var have_done_double_visit: bool = false;

    while (visit_stack.items.len > 0) {
        var current_visit = &visit_stack.items[visit_stack.items.len - 1];

        if (std.mem.eql(u8, "end", current_visit.node.name)) {
            path_count += 1;
            _ = visit_stack.pop();
            current_visit.node.visited = 0;
            continue;
        }

        if (current_visit.next_link_index == current_visit.node.links.items.len) {
            // Visited all paths in this node and nowhere to go.
            const visit = visit_stack.pop();
            current_visit.node.visited -= 1;

            if (visit.did_double_visit) {
                have_done_double_visit = false;
            }
        } else {
            const node_to_visit = current_visit.node.links.items[current_visit.next_link_index];
            current_visit.next_link_index += 1;

            if (node_to_visit.small_cave) {
                if (node_to_visit.visited == 0) {
                    try visit_stack.append(NodeVisit{ .node = node_to_visit });
                    node_to_visit.visited += 1;
                } else if (node_to_visit.visited == 1) {
                    if (!have_done_double_visit) {
                        try visit_stack.append(NodeVisit{
                            .node = node_to_visit,
                            .did_double_visit = true,
                        });
                        node_to_visit.visited += 1;

                        have_done_double_visit = true;
                    }
                }
            } else {
                try visit_stack.append(NodeVisit{ .node = node_to_visit });
                node_to_visit.visited += 1;
            }
        }
    }

    log("Path count: {}", .{path_count});
}
