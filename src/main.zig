const std = @import("std");

const dbg = jo.dbg;

pub fn main() !void {
    try jo.init();
    defer jo.deinit();
}

// {{{ jo: 標準入出力のコーナーでございます👆️
const jo = struct {
    const stdin = std.fs.File.stdin();
    const stdout = std.fs.File.stdout();

    var _stdin_buf: [1024]u8 = undefined;
    var stdin_reader = stdin.reader(&_stdin_buf);

    var _stdout_buf: [4096]u8 = undefined;

    pub const StdioError = error{
        EndOfFile,
        ExpectedCharButLongerThanOne,
    };

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

    fn readString() ![]const u8 {
        return input_tokens.next() orelse {
            return StdioError.EndOfFile;
        };
    }

    fn readChar() !u8 {
        const token = try readString();
        if (token.len != 1) {
            return StdioError.ExpectedCharButLongerThanOne;
        }
        return token[0];
    }

    fn readInt(comptime T: type) !T {
        const token = try readString();
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
