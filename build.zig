const std = @import("std");
const builtin = @import("builtin");

comptime {
    const v = builtin.zig_version;
    if (v.major != 0 or v.minor != 15 or v.patch != 1)
        @compileError("Zig 0.15.1 required");
}

const section_header = "\\033[1;36m─── CLIPBOARD ───\\033[0m";

const ClipboardCmds = switch (builtin.os.tag) {
    .macos => struct {
        const get = "printf '" ++ section_header ++ "\\n' && pbpaste";
        const put = "cat src/main.zig | pbcopy && printf '\\033[1;32mCopied to clipboard\\033[0m\\n'";
        const pipe_to_binary = "pbpaste | ./zig-out/bin/judge";
    },
    .windows => struct {
        const get = "printf '" ++ section_header ++ "\\n' && powershell.exe -command \"Get-Clipboard\"";
        const put = "cat src/main.zig | clip.exe && printf '\\033[1;32mCopied to clipboard\\033[0m\\n'";
        const pipe_to_binary = "powershell.exe -command \"Get-Clipboard\" | tr -d '\\r' | ./zig-out/bin/judge";
    },
    .linux => struct {
        const get = "printf '" ++ section_header ++ "\\n' && xclip -o -selection clipboard";
        const put = "cat src/main.zig | xclip -i -selection clipboard && printf '\\033[1;32mCopied to clipboard\\033[0m\\n'";
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

    // `zig build run-clip` — Build and run with clipboard as stdin
    const run_clip_cmd = b.addSystemCommand(&.{ "sh", "-c", ClipboardCmds.pipe_to_binary });
    run_clip_cmd.step.dependOn(b.getInstallStep());
    const run_clip_step = b.step("run-clip", "Build and run with clipboard as stdin");
    run_clip_step.dependOn(&run_clip_cmd.step);

    // `zig build clip` — Show clipboard content
    const clip_cmd = b.addSystemCommand(&.{ "sh", "-c", ClipboardCmds.get });
    const clip_step = b.step("clip", "Show clipboard content");
    clip_step.dependOn(&clip_cmd.step);

    // `zig build copy` — Copy src/main.zig to clipboard
    const copy_cmd = b.addSystemCommand(&.{ "sh", "-c", ClipboardCmds.put });
    const copy_step = b.step("copy", "Copy src/main.zig to clipboard");
    copy_step.dependOn(&copy_cmd.step);
}
