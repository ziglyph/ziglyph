const std = @import("std");
const zgl = @import("ziglyph").ziglyph;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.smp_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var out_buff: [4096]u8 = undefined;
    var stdout = std.fs.File.stdout().writer(&out_buff);
    const out = &stdout.interface;

    const args = try std.process.argsAlloc(allocator);
    if (args.len < 3) {
        try print_usage(out);
        return;
    }

    const cmd = args[1];
    const input = args[2];

    var app = zgl.init(allocator);
    defer app.deinit();

    if (std.mem.eql(u8, cmd, "skeleton") or std.mem.eql(u8, cmd, "s")) {
        try app.run_skeleton(input);
    } else if (std.mem.eql(u8, cmd, "normalizer") or std.mem.eql(u8, cmd, "n")) {
        try app.run_normalizer(input);
    } else if (std.mem.eql(u8, cmd, "detector") or std.mem.eql(u8, cmd, "d")) {
        try app.run_detector(input);
    } else if (std.mem.eql(u8, cmd, "cleaner") or std.mem.eql(u8, cmd, "c")) {
        try app.run_cleaner(input);
    } else {
        try out.print("Unknown command: {s}\n", .{cmd});
        try print_usage(out);
    }
}

fn print_usage(out: *std.Io.Writer) !void {
    try out.print(
        \\Usage: zgl <command> <string>
        \\Commands:
        \\  skeleton    Run skeleton module
        \\  detector    Run detector module
        \\
    , .{});
    try out.flush();
}
