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
}
