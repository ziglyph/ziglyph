const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const mod = b.addModule("ziglyph", .{
        .root_source_file = b.path("src/ziglyph.zig"),
        .target = target,
        .optimize = optimize,
        .strip = true,
    });

    const exe = b.addExecutable(.{
        .name = "zgl",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .strip = true,
            .imports = &.{
                .{
                    .name = "ziglyph",
                    .module = mod,
                },
            },
        }),
    });

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
}

fn createHooksDirectory(hooks_path: []const u8) void {
    std.fs.cwd().makeDir(hooks_path) catch |err| switch (err) {
        error.PathAlreadyExists => return,
        else => {
            std.debug.print("Could not create directory: {}\n", .{err});
        },
    };
}

fn buildHooksPath(allocator: std.mem.Allocator) []const u8 {
    const home = std.process.getEnvVarOwned(allocator, "HOME") catch |err| {
        std.debug.panic("Could not find home directory: {}\n", .{err});
    };
    const hooks_path = std.fs.path.join(allocator, &[_][]const u8{
        home,
        ".git_hooks",
    }) catch |err| {
        std.debug.panic("Could not build hooks path: {}\n", .{err});
    };
    return hooks_path;
}
