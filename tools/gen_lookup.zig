const std = @import("std");

const MAX = 0x110000;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.smp_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const conf_file = "confusables.txt";
    const output_file = "../src/confusable_lookup.zig";

    const data = try std.fs.cwd().readFileAlloc(allocator, conf_file, 20 * 1024 * 1024);
    defer allocator.free(data);

    var table = try allocator.alloc(u21, MAX);
    defer allocator.free(table);

    // identity mapping
    for (table, 0..) |*v, i| {
        v.* = @intCast(i);
    }

    var lines = std.mem.splitScalar(u8, data, '\n');

    while (lines.next()) |line| {
        if (line.len == 0) continue;
        if (line[0] == '#') continue;

        var parts = std.mem.splitScalar(u8, line, ';');

        const src = std.mem.trim(u8, parts.next() orelse continue, " ");
        const dst = std.mem.trim(u8, parts.next() orelse continue, " ");

        const src_cp = try std.fmt.parseInt(u32, src, 16);

        var dst_parts = std.mem.splitScalar(u8, dst, ' ');
        while (dst_parts.next()) |cp_str| {
            const trimmed = std.mem.trim(u8, cp_str, " \t");
            if (trimmed.len == 0) continue;

            const dst_cp = std.fmt.parseInt(u32, trimmed, 16) catch |err| {
                std.debug.print(
                    \\Cannot parse int: {s}
                    \\Error: {}
                    \\
                , .{ trimmed, err });
                return err;
            };
            table[src_cp] = @intCast(dst_cp);
            break; // only first codepoint matters for skeleton
        }
    }

    var file = try std.fs.cwd().createFile(output_file, .{});
    defer file.close();

    var w = file.deprecatedWriter();

    try w.writeAll("pub const table: [0x110000]u21 = .{\n");

    for (table) |v| {
        try w.print("0x{x},\n", .{v});
    }

    try w.writeAll("};\n");
}
