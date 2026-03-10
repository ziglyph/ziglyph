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
    if (args.len < 2) {
        try print_usage(out);
        return;
    }

    const cmd = args[1];

    var input_file: std.fs.File = undefined;
    defer input_file.close();

    if (args.len == 2) {
        input_file = std.fs.File.stdin();
    } else {
        input_file = try std.fs.cwd().openFile(args[2], .{ .mode = .read_only });
    }
    var input_buff: [4096]u8 = undefined;
    var input_reader = input_file.reader(&input_buff);

    var app = zgl.init(allocator, &input_reader.interface, out);
    defer app.deinit();

    if (std.mem.startsWith(u8, "skeleton", cmd)) {
        try app.run_skeleton();
    } else if (std.mem.startsWith(u8, "normalizer", cmd)) {
        try app.run_normalizer();
    } else if (std.mem.startsWith(u8, "detector", cmd)) {
        try app.run_detector();
    } else {
        try out.print("Unknown command: {s}\n", .{cmd});
        try print_usage(out);
    }
}

fn print_usage(out: *std.Io.Writer) !void {
    std.debug.print(
        \\Usage: zgl s|n|d [filename]
        \\Commands:
        \\  skeleton    Run skeleton module
        \\  normalizer  Run normalizer module
        \\  detector    Run detector module
        \\
    , .{});
    try out.flush();
}
