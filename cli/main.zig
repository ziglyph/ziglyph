const std = @import("std");
const zgl = @import("ziglyph");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.smp_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const args = try std.process.argsAlloc(allocator);
    if (args.len < 3) {
        print_usage();
        return;
    }

    const cmd = args[1];
    const input = args[2];

    if (std.mem.eql(u8, cmd, "skeleton") or std.mem.eql(u8, cmd, "s")) {
        try run_skeleton(allocator, input);
    } else if (std.mem.eql(u8, cmd, "normalizer") or std.mem.eql(u8, cmd, "n")) {
        try run_normalizer(allocator, input);
    } else if (std.mem.eql(u8, cmd, "detector") or std.mem.eql(u8, cmd, "d")) {
        try run_detector(input);
    } else if (std.mem.eql(u8, cmd, "cleaner") or std.mem.eql(u8, cmd, "c")) {
        try run_cleaner(allocator, input);
    } else {
        std.debug.print("Unknown command: {s}\n", .{cmd});
        print_usage();
    }
}

fn print_usage() void {
    std.debug.print(
        \\Usage: zgl <command> <string>
        \\Commands:
        \\  skeleton    Run skeleton module
        \\  detector    Run detector module
        \\
    , .{});
}

fn run_skeleton(allocator: std.mem.Allocator, input: []const u8) !void {
    var sk = zgl.skeleton.Skeleton.init(allocator);
    defer sk.deinit();

    std.debug.print("Running skeleton...\n", .{});
    const result = try sk.compute(input);

    std.debug.print(
        \\{s}
        \\{s}
        \\
    , .{ input, result });
    std.debug.print("Skeleton finished.\n", .{});
}

fn run_normalizer(allocator: std.mem.Allocator, input: []const u8) !void {
    var nm = zgl.normalizer.Normalizer.init(allocator);
    defer nm.deinit();

    std.debug.print("Running normalizer...\n", .{});
    const result = try nm.nfkc(input);

    std.debug.print(
        \\{s}
        \\{s}
        \\
    , .{ input, result });
    std.debug.print("Normalizer finished.\n", .{});
}

fn run_detector(input: []const u8) !void {
    std.debug.print("Running detector...\n", .{});
    const result = try zgl.containsHomoglyph(input);

    if (result) {
        std.debug.print("{s} contains a homoglyph\n", .{input});
    } else {
        std.debug.print("{s} does not contain a homoglyph\n", .{input});
    }
    std.debug.print("Detector finished.\n", .{});
}

fn run_cleaner(allocator: std.mem.Allocator, input: []const u8) !void {
    var cl = zgl.cleaner.Cleaner.init(allocator);
    defer cl.deinit();

    std.debug.print("Running cleaner...\n", .{});
    const result = try cl.clean(input);

    std.debug.print(
        \\{s}
        \\{s}
        \\
    , .{ input, result });
    std.debug.print("Cleaner finished.\n", .{});
}
