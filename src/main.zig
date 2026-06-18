const std = @import("std");
const ac = @import("ac-library");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var d = try ac.Dsu.init(allocator, 10);
    defer d.deinit();
    _ = d.merge(0, 1);
    try std.testing.expect(d.same(0, 1));
    _ = d.merge(1, 5);
    var g = try d.groups();
    std.debug.print("{any}\n", .{g.get(0)});
}
