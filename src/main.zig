const std = @import("std");

pub fn main() !void {
    try jo.init();
    defer jo.deinit();

    const a = try jo.nextInt(u4);
    const b = try jo.nextInt(u4);
    const c = try jo.nextInt(u4);

    const ans = a != b and b == c;
    jo.println("{s}", .{if (ans) "Yes" else "No"});
}

// {{{ jo: 標準入出力のコーナーでございます👆️
const jo = struct {
    const stdin = std.fs.File.stdin();
    const stdout = std.fs.File.stdout();

    var _stdin_buf: [1024]u8 = undefined;
    var stdin_reader = stdin.reader(&_stdin_buf);

    var _stdout_buf: [4096]u8 = undefined;

    fn print(comptime fmt: []const u8, args: anytype) void {
        const output = std.fmt.bufPrint(&_stdout_buf, fmt, args) catch unreachable;
        stdout.writeAll(output) catch unreachable;
    }

    fn println(comptime fmt: []const u8, args: anytype) void {
        print(fmt ++ "\n", args);
    }

    var arena: std.heap.ArenaAllocator = undefined;
    var allocator: std.mem.Allocator = undefined;
    var input_tokens: std.mem.TokenIterator(u8, .any) = undefined;

    fn dbg(value: anytype) void {
        std.debug.print("{f}\n", .{value});
    }

    fn nextToken() ![]const u8 {
        return input_tokens.next().?;
    }

    fn nextInt(comptime T: type) !T {
        return std.fmt.parseInt(T, input_tokens.next().?, 10);
    }

    fn nextIntPair(comptime T: type, comptime U: type) !struct { T, U } {
        return .{
            try nextInt(T),
            try nextInt(U),
        };
    }

    fn nextIntArray(comptime T: type, size: usize) ![]T {
        const result = try allocator.alloc(T, size);
        for (result) |*item| {
            item.* = try nextInt(T);
        }
        return result;
    }

    fn nextIntArrayArray(comptime T: type, size: usize) ![][]T {
        const result = try allocator.alloc(T, size);
        for (result) |*item| {
            item.* = try nextIntArray(T);
        }
        return result;
    }

    fn nextIntPairArray(comptime T: type, comptime U: type, size: usize) ![]struct { T, U } {
        const result = try allocator.alloc(struct { T, U }, size);
        for (result) |*item| {
            item.* = try nextIntPair(T, U);
        }
        return result;
    }

    fn alloc(T: type, len: usize) ![]T {
        return allocator.alloc(T, len);
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
