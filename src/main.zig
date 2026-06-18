const std = @import("std");
const ac = @import("ac-library");

const colors = struct {
    const reset = "\x1b[0m";
    const cyan = "\x1b[36m";
    const bold = "\x1b[1m";
};

fn printSection(comptime name: []const u8) void {
    std.debug.print("{s}{s}─── {s} ───{s}\n", .{
        colors.bold,
        colors.cyan,
        name,
        colors.reset,
    });
}

pub fn main() !void {
    printSection("INPUT");

    const allocator = std.heap.page_allocator;
    var d = try ac.Dsu.init(allocator, 10);
    defer d.deinit();
    _ = d.merge(0, 1);
    try std.testing.expect(d.same(0, 1));
    _ = d.merge(1, 5);
    var g = try d.groups();

    printSection("OUTPUT");
    std.debug.print("{any}\n", .{g.get(0)});
}
