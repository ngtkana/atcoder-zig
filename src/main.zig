const std = @import("std");
const nextInt = libio.nextInt;
const print = libio.print;

pub fn main() !void {
    try libio.init();
    defer libio.deinit();

    const x = try nextInt(usize);
    const ans = switch (3 <= x and x <= 18) {
        true => "Yes",
        false => "No",
    };
    try print("{s}", .{ans});
}

// {{{ libio: 標準入出力のコーナーでございます👆️
const libio = struct {
    const stdin = std.fs.File.stdin();
    const stdout = std.fs.File.stdout();

    var _stdin_buf: [1024]u8 = undefined;
    var stdin_reader = stdin.reader(&_stdin_buf);

    var _stdout_buf: [4096]u8 = undefined;
    fn print(comptime fmt: []const u8, args: anytype) !void {
        const output = try std.fmt.bufPrint(&_stdout_buf, fmt, args);
        try stdout.writeAll(output);
    }

    var arena: std.heap.ArenaAllocator = undefined;
    var allocator: std.mem.Allocator = undefined;
    var input_tokens: std.mem.TokenIterator(u8, .any) = undefined;

    fn nextInt(comptime T: type) !T {
        return std.fmt.parseInt(T, input_tokens.next().?, 10);
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
