const std = @import("std");

const MAX = 0x110000;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.smp_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const args = try std.process.argsAlloc(allocator);
    if (args.len < 3) std.debug.panic("wrong number of arguments", .{});

    const conf_file = args[1];
    const output_file = args[2];

    try getConfusablesFile(allocator, conf_file);

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

    var file = try std.fs.cwd().createFile(output_file, .{
        .truncate = true,
    });
    defer file.close();

    var file_write_buf: [2048]u8 = undefined;
    var writer = file.writer(&file_write_buf);
    const writer_interface = &writer.interface;

    try writer_interface.print("pub const table: [0x{x}]u21 = .{{\n", .{MAX});

    for (table) |v| {
        try writer_interface.print("0x{x},\n", .{v});
    }

    try writer_interface.writeAll("};\n");
    try writer_interface.flush();
}

fn getConfusablesFile(allocator: std.mem.Allocator, destination: []const u8) !void {
    var file = try std.fs.cwd().createFile(destination, .{
        .truncate = true,
    });
    defer file.close();

    var file_write_buf: [1024]u8 = undefined;
    var file_writer = file.writer(&file_write_buf);

    var client = std.http.Client{ .allocator = allocator };

    const uri = try std.Uri.parse("https://www.unicode.org/Public/security/latest/confusables.txt");
    const res = client.fetch(.{
        .method = .GET,
        .location = .{ .uri = uri },
        .response_writer = &file_writer.interface,
    }) catch |err| {
        std.debug.panic("Error during fetch: {}\n", .{err});
    };
    if (res.status != .ok) {
        std.debug.print("Could not fetch confusables.txt\n", .{});
    }
}
