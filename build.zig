const std = @import("std");
const builtin = @import("builtin");

comptime {
    const v = builtin.zig_version;
    if (v.major != 0 or v.minor != 15 or v.patch != 1)
        @compileError("Zig 0.15.1 required");
}

const ClipboardCmds = switch (builtin.os.tag) {
    .macos => struct {
        const get = "pbpaste";
        const put = "cat src/main.zig | pbcopy";
        const pipe_to_binary = "pbpaste | ./zig-out/bin/judge";
    },
    .windows => struct {
        const get = "powershell.exe -command \"Get-Clipboard\"";
        const put = "cat src/main.zig | clip.exe";
        const pipe_to_binary = "powershell.exe -command \"Get-Clipboard\" | tr -d '\\r' | ./zig-out/bin/judge";
    },
    .linux => struct {
        const get = "xclip -o -selection clipboard";
        const put = "cat src/main.zig | xclip -i -selection clipboard";
        const pipe_to_binary = "xclip -o -selection clipboard | ./zig-out/bin/judge";
    },
    else => @compileError("Unsupported OS"),
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // ===== Executable =====
    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "judge",
        .root_module = exe_mod,
    });
    b.installArtifact(exe);

    // ===== Library Dependencies =====
    const ac_library = b.dependency("ac-library", .{
        .target = target,
        .optimize = optimize,
    });
    exe_mod.addImport("ac-library", ac_library.module("ac-library"));

    const proconio = b.dependency("proconio", .{
        .target = target,
        .optimize = optimize,
    });
    exe_mod.addImport("proconio", proconio.module("proconio"));

    const string = b.dependency("string", .{
        .target = target,
        .optimize = optimize,
    });
    exe_mod.addImport("string", string.module("string"));

    const mvzr = b.dependency("mvzr", .{
        .target = target,
        .optimize = optimize,
    });
    exe_mod.addImport("mvzr", mvzr.module("mvzr"));

    // ===== Build Steps =====

    // `zig build run` — Build and run
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    const run_step = b.step("run", "Build and run");
    run_step.dependOn(&run_cmd.step);

    // `zig build run-from-clipboard` — Build and run with clipboard as stdin
    const run_from_clipboard_cmd = b.addSystemCommand(&.{ "sh", "-c", ClipboardCmds.pipe_to_binary });
    run_from_clipboard_cmd.step.dependOn(b.getInstallStep());
    const run_from_clipboard_step = b.step("run-from-clipboard", "Build and run with clipboard as stdin");
    run_from_clipboard_step.dependOn(&run_from_clipboard_cmd.step);

    // `zig build show-clipboard` — Show clipboard content
    const show_clipboard_cmd = b.addSystemCommand(&.{ "sh", "-c", ClipboardCmds.get });
    const show_clipboard_step = b.step("show-clipboard", "Show clipboard content");
    show_clipboard_step.dependOn(&show_clipboard_cmd.step);

    // `zig build copy-to-clipboard` — Copy src/main.zig to clipboard
    const copy_to_clipboard_cmd = b.addSystemCommand(&.{ "sh", "-c", ClipboardCmds.put });
    const copy_to_clipboard_step = b.step("copy-to-clipboard", "Copy src/main.zig to clipboard");
    copy_to_clipboard_step.dependOn(&copy_to_clipboard_cmd.step);
}
