const std = @import("std");

const dbg = jo.dbg;

const PairingHeap = pairing_heap.MaxHeap(i64, void, struct {
    fn inner(_: void, a: i64, b: i64) std.math.Order {
        return std.math.order(a, b);
    }
}.inner);

const DpValue = struct {
    heap: PairingHeap,
    limit: i64,
};

pub fn main() !void {
    try jo.init();
    defer jo.deinit();

    const n = try jo.readInt(usize);
    const node_weight = try jo.alloc(i64, n);
    var edges = try jo.alloc(struct { usize, usize }, n - 1);

    node_weight[0] = try jo.readInt(i64);
    for (1..n) |i| {
        const p = try jo.readInt(usize) - 1;
        edges[i - 1] = .{ p, i };
        node_weight[i] = try jo.readInt(i64);
    }
    edges, const g = try counting_sort.SortConstructTable(
        struct { usize, usize },
        jo.allocator,
        edges,
        {},
        struct {
            fn inner(_: void, edge: struct { usize, usize }) usize {
                return edge.@"0";
            }
        }.inner,
        n,
    );

    const depth = try jo.alloc(i64, n);
    depth[0] = 0;
    for (0..n) |i| {
        node_weight[i] += depth[i];
        for (g[i]) |edge| {
            _, const j = edge;
            depth[j] = depth[i] + 1;
        }
    }

    const dp = try jo.alloc(DpValue, n);
    for (0..n) |i_rev| {
        const i = n - 1 - i_rev;
        dp[i] = .{ .heap = try .init(jo.allocator, {}), .limit = 0 };
        for (g[i]) |edge| {
            _, const j = edge;
            dp[i].heap = try PairingHeap.meld(&dp[i].heap, &dp[j].heap);
            dp[i].limit += dp[j].limit;
        }
        _ = try dp[i].heap.push(node_weight[i]);
        _ = try dp[i].heap.push(node_weight[i]);
        dp[i].limit += (dp[i].heap.peek() orelse unreachable) - node_weight[i];
        _ = try dp[i].heap.pop();
    }

    const ans = dp[0].limit;
    try jo.println("{d}", .{ans});
}

const counting_sort = struct {
    pub fn SortConstructTable(
        comptime T: type,
        allocator: std.mem.Allocator,
        items: []T,
        context: anytype,
        comptime key: fn (@TypeOf(context), item: T) usize,
        bucket_count: usize,
    ) !struct { []T, [][]T } {
        const out = try allocator.alloc(T, items.len);
        {
            var end = try allocator.alloc(usize, bucket_count);
            @memset(end, 0);
            for (items) |item| {
                end[key(context, item)] += 1;
            }
            for (1..end.len) |i| {
                end[i] += end[i - 1];
            }
            for (items) |item| {
                const i = key(context, item);
                end[i] -= 1;
                out[end[i]] = item;
            }
        }
        const table = try allocator.alloc([]T, bucket_count);
        {
            var end: usize = 0;
            for (0..bucket_count) |i| {
                const start = end;
                while (end != out.len and key(context, out[end]) == i) end += 1;
                table[i] = out[start..end];
            }
        }
        return .{ out, table };
    }
};

const pairing_heap = struct {
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
};

// {{{ jo: 標準入出力のコーナーでございます👆️
const jo = struct {
    const stdin = std.fs.File.stdin();
    const stdout = std.fs.File.stdout();

    var _stdin_buf: [1024]u8 = undefined;
    var stdin_reader = stdin.reader(&_stdin_buf);

    var _stdout_buf: [4096]u8 = undefined;

    fn print(comptime fmt: []const u8, args: anytype) !void {
        const output = try std.fmt.bufPrint(&_stdout_buf, fmt, args);
        try stdout.writeAll(output);
    }

    fn println(comptime fmt: []const u8, args: anytype) !void {
        try print(fmt ++ "\n", args);
    }

    var arena: std.heap.ArenaAllocator = undefined;
    var allocator: std.mem.Allocator = undefined;
    var input_tokens: std.mem.TokenIterator(u8, .any) = undefined;

    fn dbg(value: anytype) void {
        std.debug.print("{any}\n", .{value});
    }

    fn readString() []const u8 {
        return input_tokens.next() orelse {
            std.debug.panic("Input parsing failed:\n\n  Reached the end of file\n", .{});
            std.process.exit(1);
        };
    }

    fn readChar() u8 {
        const token = readString();
        std.debug.assert(token.len == 1);
        return token[0];
    }

    fn readInt(comptime T: type) !T {
        const token = readString();
        return std.fmt.parseInt(T, token, 10);
    }

    fn readIntPair(comptime T: type, comptime U: type) !struct { T, U } {
        return .{
            try readInt(T),
            try readInt(U),
        };
    }

    fn readIntArray(comptime T: type, size: usize) ![]T {
        const result = try allocator.alloc(T, size);
        for (result) |*item| {
            item.* = try readInt(T);
        }
        return result;
    }

    fn alloc(T: type, len: usize) ![]T {
        return try allocator.alloc(T, len);
    }

    fn alloc2d(T: type, h: usize, w: usize) [][]T {
        const flat_items = alloc(T, h * w);
        const result = alloc([]T, h);
        for (result, 0..) |*row, i| {
            row.* = flat_items[i * w .. (i + 1) * w];
        }
        return result;
    }

    fn init() !void {
        arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        allocator = arena.allocator();
        const input_data = try stdin_reader.interface.allocRemaining(allocator, .unlimited);
        input_tokens = std.mem.tokenizeAny(u8, input_data, " \t\r\n");
    }

    fn deinit() void {
        arena.deinit();
    }
};
// }}}
