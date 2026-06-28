const std = @import("std");

pub fn FenwickTree(T: type) type {
    return struct {
        items: []T,

        const Self = @This();

        pub fn init(allocator: std.mem.Allocator, length: usize) !Self {
            const items = try allocator.alloc(T, length + 1);
            @memset(items, 0);
            return .{ .items = items };
        }

        pub fn add(self: *Self, index: usize, x: T) void {
            var i = index + 1;
            while (i < self.*.items.len) : (i += i & -%i) {
                self.*.items[i] += x;
            }
        }

        pub fn sub(self: *Self, index: usize, x: T) void {
            var i = index + 1;
            while (i < self.*.items.len) : (i += i & -%i) {
                self.*.items[i] -= x;
            }
        }

        pub fn prefix_sum(self: Self, end_excluded: usize) T {
            var i = end_excluded;
            var ans: T = 0;
            while (i != 0) : (i -= i & -%i) {
                ans += self.items[i];
            }
            return ans;
        }

        pub fn get(self: Self, index: usize) T {
            return self.prefix_sum(index + 1) - self.prefix_sum(index);
        }

        pub fn collect(self: @This(), allocator: std.mem.Allocator) ![]T {
            const result = try allocator.alloc(T, self.items.len - 1);
            for (result, 0..) |*out, i| {
                out.* = self.get(i);
            }
            return result;
        }
    };
}
