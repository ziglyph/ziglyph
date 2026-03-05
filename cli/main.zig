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
    if (std.mem.eql(u8, cmd, "skeleton")) {
        try run_skeleton(allocator);
    } else {
        std.debug.print("Unknown command: {s}\n", .{cmd});
        print_usage();
    }

    std.debug.print("Allocated: {p}\n", .{allocator.ptr});
}

fn print_usage() void {
    std.debug.print("Usage: zgl <command>\n", .{});
    std.debug.print("Commands:\n", .{});
    std.debug.print("  skeleton    Run skeleton module\n", .{});
}

fn run_skeleton(allocator: std.mem.Allocator) !void {
    var sk = zgl.skeleton.Skeleton.init(allocator);
    defer sk.deinit();

    std.debug.print("Running skeleton...\n", .{});
    try sk.run();
    std.debug.print("Skeleton finished.\n", .{});
}
