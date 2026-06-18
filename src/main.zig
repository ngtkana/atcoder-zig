const std = @import("std");
const nextInt = libio.nextInt;
const print = libio.print;
const dbg = libfmt.dbg;

const Item = struct {
    c: usize,
    v: u64,
};

pub fn main() !void {
    try libio.init();
    defer libio.deinit();

    const n = try nextInt(usize);
    const k = try nextInt(usize);
    const m = try nextInt(usize);

    const a = try libio.alloc.alloc(u64, 2 * n);
    @memset(a, 0);
    for (0..n) |i| {
        const c = try nextInt(usize) - 1;
        var v = try nextInt(u64);
        if (a[c] < v) {
            std.mem.swap(u64, &a[c], &v);
        }
        a[n + i] = v;
    }
    std.mem.sortUnstable(u64, a[0..n], {}, std.sort.desc(u64));
    std.mem.sortUnstable(u64, a[m .. 2 * n], {}, std.sort.desc(u64));

    var ans: u64 = 0;
    for (a[0..k]) |item| {
        ans += item;
    }
    try print("{d}", .{ans});
}

// {{{ libfmt: デバッグ出力のフォーマットでございます👆️
const libfmt = struct {
    fn dbg(value: anytype) void {
        std.debug.print("{f}\n", .{fmtArray(value)});
    }

    fn fmtArray(value: anytype) FmtArray(@TypeOf(value)) {
        return .{ .value = value };
    }

    fn fmtByFor(value: anytype, writer: anytype) !void {
        try writer.writeAll("[");
        var is_head = true;
        for (value) |item| {
            if (is_head) {
                is_head = false;
            } else {
                try writer.writeAll(", ");
            }
            try writer.print("{f}", .{fmtArray(item)});
        }
        try writer.writeAll("]");
    }

    fn FmtArray(comptime T: type) type {
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
                            .slice => return try fmtByFor(value, writer),
                            else => {},
                        }
                    },
                    .array => {
                        return try fmtByFor(value[0..], writer);
                    },
                    .@"struct" => {
                        inline for (type_info.@"struct".fields) |field| {
                            if (std.mem.eql(u8, field.name, "items") and
                                @typeInfo(field.type) == .pointer and @typeInfo(field.type).pointer.size == .slice)
                            {
                                return try fmtByFor(value.items, writer);
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
