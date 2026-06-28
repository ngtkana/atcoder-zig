const std = @import("std");

pub fn MaxHeap(
    comptime T: type,
    comptime Context: type,
    comptime compareFn: fn (context: Context, a: T, b: T) std.math.Order,
) type {
    return MinHeap(T, Context, struct {
        fn inner(context: Context, a: T, b: T) std.math.Order {
            return compareFn(context, a, b).invert();
        }
    }.inner);
}

pub fn MinHeap(
    comptime T: type,
    comptime Context: type,
    comptime compareFn: fn (context: Context, a: T, b: T) std.math.Order,
) type {
    return struct {
        root: ?*Node,
        allocator: std.mem.Allocator,
        context: Context,

        const Heap = @This();
        var shared_spine: std.ArrayListUnmanaged(*Node) = .{};

        pub fn init(allocator: std.mem.Allocator, context: Context) !Heap {
            return .{ .root = null, .allocator = allocator, .context = context };
        }

        pub fn push(self: *Heap, key: T) !*Node {
            var array: []Node = try self.allocator.alloc(Node, 1);
            const node = &array[0];
            node.* = .{
                .key = key,
                .left = null,
                .right = null,
                // .parent = null,
            };
            if (self.root) |root| {
                self.root = Node.meld(self, root, node);
            } else {
                self.root = node;
            }
            return node;
        }

        pub fn pop(self: *Heap) !?T {
            if (self.root) |root| {
                const result = root.*.key;
                self.root = if (root.*.left) |left| try Node.meldMany(self, left) else null;
                return result;
            } else return null;
        }

        pub fn peek(self: Heap) ?T {
            return if (self.root) |root| root.key else null;
        }

        pub fn meld(lhs: *Heap, rhs: *Heap) !Heap {
            var result = try Heap.init(lhs.allocator, lhs.context);
            if (lhs.*.root) |a| {
                if (rhs.*.root) |b| {
                    result.root = Node.meld(&result, a, b);
                } else {
                    result.root = a;
                }
            } else if (rhs.*.root) |b_inner| {
                result.root = b_inner;
            }
            return result;
        }

        pub fn decrease_key(self: *Heap, node: *Node, new_key: T) !void {
            if (compareFn(self.context, new_key, node.*.key) != std.math.Order.lt) return;
            const root = self.root.?;
            node.*.key = new_key;
            if (root == node) return;
            if (node.*.parent) |p| {
                if (p.left == node) {
                    p.left = node.right;
                } else if (p.right == node) {
                    p.right = node.right;
                } else unreachable;
            }
            if (node.right) |r| r.parent = node.parent;
            node.parent = null;
            node.right = null;
            self.root = Node.meld(self, root, node);
        }

        pub fn collect(self: Heap) ![]T {
            var result = try std.ArrayList(T).initCapacity(self.allocator, 0);
            if (self.root) |root| {
                try Node.collect(root.*, self.allocator, &result);
            }
            return result.items;
        }

        const Node = struct {
            key: T,
            left: ?*Node,
            right: ?*Node,
            parent: ?*Node,

            pub fn meld(heap: *Heap, lhs: *Node, rhs: *Node) *Node {
                var a = lhs;
                var b = rhs;
                if (compareFn(heap.context, a.key, b.key) == std.math.Order.gt) {
                    std.mem.swap(*Node, &a, &b);
                }
                const c = a.left;
                a.left = b;
                b.right = c;
                if (c) |c_inner| c_inner.parent = b;
                b.parent = a;
                return a;
            }

            pub fn meldMany(heap: *Heap, node: *Node) !*Node {
                Heap.shared_spine.clearRetainingCapacity();
                var current: ?*Node = node;
                while (current) |current_node| {
                    current_node.parent = null;
                    try Heap.shared_spine.append(heap.allocator, current_node);
                    const next = current_node.right;
                    current_node.right = null;
                    current = next;
                }
                var i: usize = 0;
                while (i + 1 < Heap.shared_spine.items.len) : (i += 2) {
                    Heap.shared_spine.items[i] = @This().meld(
                        heap,
                        Heap.shared_spine.items[i],
                        Heap.shared_spine.items[i + 1],
                    );
                }
                i = Heap.shared_spine.items.len - 1 & ~@as(usize, 1);
                while (2 <= i) : (i -= 2) {
                    Heap.shared_spine.items[i - 2] = @This().meld(
                        heap,
                        Heap.shared_spine.items[i - 2],
                        Heap.shared_spine.items[i],
                    );
                }
                return Heap.shared_spine.items[0];
            }

            pub fn collect(self: @This(), allocator: std.mem.Allocator, result: *std.ArrayList(T)) !void {
                try result.*.append(allocator, self.key);
                if (self.left) |left| try left.collect(allocator, result);
                if (self.right) |right| try right.collect(allocator, result);
            }
        };
    };
}
