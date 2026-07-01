const std = @import("std");

pub fn BoundedArrayList(T: type) type {
    return struct {
        items: []T,
        len: usize,

        pub fn initCapacity(allocator: std.mem.Allocator, n: usize) !@This() {
            const items = try allocator.alloc(T, n);
            return .{ .items = items, .len = 0 };
        }

        pub fn push(self: *@This(), item: T) ?void {
            if (self.len == self.items.len) return null;
            self.items[self.len] = item;
            self.len += 1;
        }

        pub fn pop(self: *@This()) ?T {
            if (self.len == 0) return null;
            self.len -= 1;
            return self.items[self.len];
        }

        pub fn exact(self: @This()) ?[]T {
            if (self.len < self.items.len) return null;
            return self.items;
        }
    };
}
