const std = @import("std");

fn FenwickTree(T: type) type {
    return struct {
        items: []T,

        fn init(allocator: std.mem.Allocator, length: usize) !@This() {
            const items = try allocator.alloc(T, length + 1);
            @memset(items, 0);
            return .{ .items = items };
        }

        fn add(self: @This(), index: usize, x: T) void {
            var i = index + 1;
            while (i < self.items.len) : (i += i & -%i) {
                self.items[i] += x;
            }
        }

        fn sub(self: @This(), index: usize, x: T) void {
            var i = index + 1;
            while (i < self.items.len) : (i += i & -%i) {
                self.items[i] -= x;
            }
        }

        fn prefix_sum(self: @This(), end_excluded: usize) T {
            var i = end_excluded;
            var ans: T = 0;
            while (i != 0) : (i -= i & -%i) {
                ans += self.items[i];
            }
            return ans;
        }
    };
}
