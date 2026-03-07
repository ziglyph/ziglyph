const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{ .default_target = .{ .cpu_model = .determined_by_arch_os } });
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("ziglyph", .{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });

    const shared = b.addLibrary(.{
        .name = "ziglyph",
        .linkage = .dynamic,
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/lib.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    // const header_install_step = b.addInstallHeaderFile(shared.getEmittedH(), "ziglyph.h");

    const exe = b.addExecutable(.{
        .name = "zgl",
        .root_module = b.createModule(.{
            .root_source_file = b.path("cli/main.zig"),
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
        shared.root_module.strip = true;
        exe.root_module.strip = true;
    }
    b.installArtifact(exe);

    const run_shared_lib_step = b.addInstallArtifact(shared, .{});
    const shared_lib_step = b.step("shared", "Shared lib");
    shared_lib_step.dependOn(&run_shared_lib_step.step);
    // shared_lib_step.dependOn(&header_install_step.step);

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

    const confusables_gen = b.addExecutable(.{
        .name = "confusables_gen",
        .root_module = b.createModule(.{
            .root_source_file = b.path("tools/confusable_table_generator.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const run_confusables_gen = b.addRunArtifact(confusables_gen);
    run_confusables_gen.addArg("unicode/confusables.txt");
    const generated_confusables_file = run_confusables_gen.addOutputFileArg("confusables.zig");

    const write_file_confusables_gen = b.addUpdateSourceFiles();
    write_file_confusables_gen.addCopyFileToSource(generated_confusables_file, "src/confusables.zig");

    const confusables_gen_step = b.step("confusable", "Generate confusable lookup table");
    confusables_gen_step.dependOn(&write_file_confusables_gen.step);

    const unicode_data_gen = b.addExecutable(.{
        .name = "unicode_data_gen",
        .root_module = b.createModule(.{
            .root_source_file = b.path("tools/normalizer_table_generator.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const run_unicode_data_gen = b.addRunArtifact(unicode_data_gen);
    run_unicode_data_gen.addArg("unicode/UnicodeData.txt");
    const generated_unicode_data_file = run_unicode_data_gen.addOutputFileArg("unicode_table.zig");

    const write_file_unicode_data_gen = b.addUpdateSourceFiles();
    write_file_unicode_data_gen.addCopyFileToSource(generated_unicode_data_file, "src/unicode_table.zig");

    const unicode_data_gen_step = b.step("unicode", "Generate unicode lookup table");
    unicode_data_gen_step.dependOn(&write_file_unicode_data_gen.step);
}

fn remove_zig_out() !void {
    const allocator = std.heap.page_allocator;
    const zig_out_dir = "zig-out";

    const dir = try std.fs.Dir.open(allocator, zig_out_dir, .{});
    defer dir.close();

    try dir.delete();

    try std.fs.Dir.delete(zig_out_dir);
}
