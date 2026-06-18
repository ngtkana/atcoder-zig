const std = @import("std");

pub fn main() !void {
    // stdin から全入力を読み込む
    const stdin = std.fs.File.stdin();
    var input_buf: [1024 * 1024 * 10]u8 = undefined;
    const bytes_read = try stdin.readAll(&input_buf);
    const input_data = input_buf[0..bytes_read];

    // 入力を空白文字で分割
    var tokens = std.mem.tokenizeAny(u8, input_data, " \t\r\n");

    // stdout へのライター
    const stdout = std.fs.File.stdout();

    // --- ここから問題の解法記述 ---

    // 例1: 整数Nの入力
    const n_str = tokens.next().?;
    const n = try std.fmt.parseInt(i32, n_str, 10);

    // 例2: 長さNの配列の入力と出力
    var output_buf: [65536]u8 = undefined;
    var output_pos: usize = 0;

    var written = try std.fmt.bufPrint(output_buf[output_pos..], "N is: {d}\n", .{n});
    output_pos += written.len;

    var i: i32 = 0;
    while (i < n) : (i += 1) {
        if (tokens.next()) |token| {
            const val = try std.fmt.parseInt(i32, token, 10);
            written = try std.fmt.bufPrint(output_buf[output_pos..], "{d} ", .{val * 2});
            output_pos += written.len;
        }
    }
    written = try std.fmt.bufPrint(output_buf[output_pos..], "\n", .{});
    output_pos += written.len;

    try stdout.writeAll(output_buf[0..output_pos]);
}
