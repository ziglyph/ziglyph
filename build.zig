const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const mod = b.addModule("ziglyph", .{
        .root_source_file = b.path("src/ziglyph.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "zgl",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{
                    .name = "ziglyph",
                    .module = mod,
                },
            },
        }),
    });

    if (optimize == .ReleaseFast) {
        mod.strip = true;
        exe.root_module.strip = true;
    }
    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const mod_tests = b.addTest(.{
        .root_module = mod,
    });

    const run_mod_tests = b.addRunArtifact(mod_tests);

    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });

    const run_exe_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_exe_tests.step);

    const clean_up = b.addRemoveDirTree(b.path("zig-out"));
    const clean_step = b.step("clean", "Clean up");
    clean_step.dependOn(&clean_up.step);
}

fn remove_zig_out() !void {
    const allocator = std.heap.page_allocator;
    const zig_out_dir = "zig-out";

    const dir = try std.fs.Dir.open(allocator, zig_out_dir, .{});
    defer dir.close();

    try dir.delete();

    try std.fs.Dir.delete(zig_out_dir);
}
