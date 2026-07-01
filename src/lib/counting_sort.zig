const std = @import("std");

pub fn project(Context: type, T: type, comptime field_name: []const u8) fn (Context, T) @FieldType(T, field_name) {
    return struct {
        pub fn inner(_: Context, item: T) @FieldType(T, field_name) {
            return @field(item, field_name);
        }
    }.inner;
}

pub fn CountingSortAndTable(
    comptime T: type,
    allocator: std.mem.Allocator,
    items: []T,
    context: anytype,
    comptime key: fn (@TypeOf(context), item: T) usize,
    bucket_count: usize,
) !struct { []T, [][]T } {
    const out = try allocator.alloc(T, items.len);
    {
        var end = try allocator.alloc(usize, bucket_count);
        @memset(end, 0);
        for (items) |item| {
            end[key(context, item)] += 1;
        }
        for (1..end.len) |i| {
            end[i] += end[i - 1];
        }
        for (items) |item| {
            const i = key(context, item);
            end[i] -= 1;
            out[end[i]] = item;
        }
    }
    const table = try allocator.alloc([]T, bucket_count);
    {
        var end: usize = 0;
        for (0..bucket_count) |i| {
            const start = end;
            while (end != out.len and key(context, out[end]) == i) end += 1;
            table[i] = out[start..end];
        }
    }
    return .{ out, table };
}
