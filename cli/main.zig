const std = @import("std");
const zgl = @import("ziglyph");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.smp_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const args = try std.process.argsAlloc(allocator);
    if (args.len < 2) {
        print_usage();
        return;
    }

    const cmd = args[1];
    if (std.mem.eql(u8, cmd, "skeleton") or std.mem.eql(u8, cmd, "s")) {
        try run_skeleton(allocator);
    } else if (std.mem.eql(u8, cmd, "normalizer") or std.mem.eql(u8, cmd, "n")) {
        try run_normalizer(allocator);
    } else if (std.mem.eql(u8, cmd, "detector") or std.mem.eql(u8, cmd, "d")) {
        try run_detector(allocator);
    } else if (std.mem.eql(u8, cmd, "cleaner") or std.mem.eql(u8, cmd, "c")) {
        try run_cleaner(allocator);
    } else {
        std.debug.print("Unknown command: {s}\n", .{cmd});
        print_usage();
    }
}

fn print_usage() void {
    std.debug.print(
        \\Usage: zgl <command>
        \\Commands:
        \\  skeleton    Run skeleton module
        \\  detector    Run detector module
        \\
    , .{});
}

fn run_skeleton(allocator: std.mem.Allocator) !void {
    var sk = zgl.skeleton.Skeleton.init(allocator);
    defer sk.deinit();

    std.debug.print("Running skeleton...\n", .{});
    const input = "раураl"; // contains Cyrillic letters
    const result = try sk.compute(input);

    std.debug.print(
        \\{s}
        \\{s}
        \\
    , .{ result, "paypal" });
    std.debug.print("Skeleton finished.\n", .{});
}

fn run_normalizer(allocator: std.mem.Allocator) !void {
    var nm = zgl.normalizer.Normalizer.init(allocator);
    defer nm.deinit();

    std.debug.print("Running skeleton...\n", .{});
    // ℓ = script small l
    const input = "paypaℓ";
    const result = try nm.nfkc(input);

    std.debug.print(
        \\{s}
        \\{s}
        \\
    , .{ result, "paypal" });
    std.debug.print("Skeleton finished.\n", .{});
}

fn run_detector(allocator: std.mem.Allocator) !void {
    var dt = zgl.detector.Detector.init(allocator);
    defer dt.deinit();

    std.debug.print("Running detector...\n", .{});
    const input = "раурвl"; // contains Cyrillic letters
    const result = try dt.detect(input);

    if (result) {
        std.debug.print(
            \\{s}
            \\
        , .{"true"});
    }
    std.debug.print("Detector finished.\n", .{});
}

fn run_cleaner(allocator: std.mem.Allocator) !void {
    var cl = zgl.cleaner.Cleaner.init(allocator);
    defer cl.deinit();

    std.debug.print("Running cleaner...\n", .{});
    // ℓ = script small l
    const input = "paypaℓ";
    const result = try cl.clean(input);

    std.debug.print(
        \\{s}
        \\{s}
        \\
    , .{ result, "paypal" });
    std.debug.print("Cleaner finished.\n", .{});
}
