const std = @import("std");

comptime {
    const v = @import("builtin").zig_version;
    if (v.major != 0 or v.minor != 15 or v.patch != 1)
        @compileError("Zig 0.15.1 required");
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
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

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    const run_step = b.step("run", "Build and run");
    run_step.dependOn(&run_cmd.step);

    const run_clip_cmd = b.addSystemCommand(&.{
        "sh", "-c",
        "powershell.exe -command \"Get-Clipboard\" | tr -d '\\r' | ./zig-out/bin/judge",
    });
    run_clip_cmd.step.dependOn(b.getInstallStep());
    const run_clip_step = b.step("run-clip", "Build and run with clipboard as stdin");
    run_clip_step.dependOn(&run_clip_cmd.step);

    const show_cmd = b.addSystemCommand(&.{ "powershell.exe", "-command", "Get-Clipboard" });
    const show_step = b.step("show", "Show clipboard content");
    show_step.dependOn(&show_cmd.step);
}
