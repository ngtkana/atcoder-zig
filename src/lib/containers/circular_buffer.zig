const std = @import("std");

pub fn CircularBuffer(T: type) type {
    const initial_capacity = 1;
    const realloc_multiplier = 2;

    return struct {
        buffer: []T,
        start: usize,
        end: usize,

        const Self = @This();

        pub fn init(allocator: std.mem.Allocator) !Self {
            return .{
                .buffer = try allocator.alloc(T, initial_capacity),
                .start = 0,
                .end = 0,
            };
        }

        pub fn pushBack(self: *Self, allocator: std.mem.Allocator, item: T) !void {
            self.buffer[self.end] = item;
            self.end += 1;
            if (self.end == self.buffer.len) {
                self.end = 0;
            }
            if (self.start == self.end) {
                const new_buffer = try allocator.alloc(T, self.buffer.len * realloc_multiplier);
                var new_end: usize = 0;
                for (self.buffer[self.start..self.buffer.len]) |jtem| {
                    new_buffer[new_end] = jtem;
                    new_end += 1;
                }
                for (self.buffer[0..self.end]) |jtem| {
                    new_buffer[new_end] = jtem;
                    new_end += 1;
                }
                self.* = .{
                    .buffer = new_buffer,
                    .start = 0,
                    .end = new_end,
                };
            }
        }

        pub fn popFrontOrNull(self: *Self) ?T {
            if (self.start == self.end) {
                return null;
            }
            const result = self.buffer[self.start];
            self.start += 1;
            if (self.start == self.buffer.len) {
                self.start = 0;
            }
            return result;
        }
    };
}
