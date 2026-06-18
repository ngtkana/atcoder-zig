const std = @import("std");
const nextInt = libio.nextInt;
const nextIntArray = libio.nextIntArray;
const print = libio.print;
const dbg = libfmt.dbg;

pub fn main() !void {
    try libio.init();
    defer libio.deinit();

    const n = try nextInt(usize);
    const m = try nextInt(usize);

    // 2 * a >= b
    const a = try nextIntArray(u32, n);
    const b = try nextIntArray(u32, m);
    std.mem.sortUnstable(u32, a, {}, std.sort.asc(u32));
    std.mem.sortUnstable(u32, b, {}, std.sort.asc(u32));

    var ans: usize = 0;
    var i: usize = 0;
    for (0..m) |j| {
        while (i < n and 2 * a[i] < b[j]) {
            i += 1;
        }
        if (i == n) {
            break;
        }
        ans += 1;
        i += 1;
    }
    try print("{d}", .{ans});
}

// {{{ libfmt: デバッグ出力のフォーマットでございます👆️
const libfmt = struct {
    fn dbg(value: anytype) void {
        std.debug.print("{f}\n", .{fmtDbg(value)});
    }

    fn fmtDbg(value: anytype) FmtDbg(@TypeOf(value)) {
        return .{ .value = value };
    }

    fn fmtIter(value: anytype, writer: anytype) !void {
        try writer.writeAll("[");
        var is_head = true;
        for (value) |item| {
            if (is_head) {
                is_head = false;
            } else {
                try writer.writeAll(", ");
            }
            try writer.print("{f}", .{fmtDbg(item)});
        }
        try writer.writeAll("]");
    }

    fn FmtDbg(comptime T: type) type {
        return struct {
            value: T,

            pub fn format(
                self: @This(),
                writer: anytype,
            ) !void {
                const value = self.value;
                const type_info = @typeInfo(T);
                switch (type_info) {
                    .pointer => {
                        switch (type_info.pointer.size) {
                            .slice => return try fmtIter(value, writer),
                            else => {},
                        }
                    },
                    .array => {
                        return try fmtIter(value[0..], writer);
                    },
                    .@"struct" => {
                        inline for (type_info.@"struct".fields) |field| {
                            if (std.mem.eql(u8, field.name, "items") and
                                @typeInfo(field.type) == .pointer and @typeInfo(field.type).pointer.size == .slice)
                            {
                                return try fmtIter(value.items, writer);
                            }
                        }
                    },
                    else => {},
                }
                try writer.print("{any}", .{value});
            }
        };
    }
};
// }}}
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
    var alloc: std.mem.Allocator = undefined;
    var input_tokens: std.mem.TokenIterator(u8, .any) = undefined;

    fn nextInt(comptime T: type) !T {
        return std.fmt.parseInt(T, input_tokens.next().?, 10);
    }

    fn nextIntArray(comptime T: type, size: usize) ![]T {
        const result = try alloc.alloc(T, size);
        for (result) |*item| {
            item.* = try std.fmt.parseInt(T, input_tokens.next().?, 10);
        }
        return result;
    }

    fn init() !void {
        arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        alloc = arena.allocator();
        const input_data = try stdin_reader.interface.allocRemaining(alloc, .unlimited);
        input_tokens = std.mem.tokenizeAny(u8, input_data, " \t\r\n");
    }

    fn deinit() void {
        arena.deinit();
    }
};
// }}}
