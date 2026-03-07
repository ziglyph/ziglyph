const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const cwd = std.fs.cwd();

    const file = try cwd.openFile("UnicodeData.txt", .{});
    defer file.close();

    var reader = std.io.bufferedReader(file.reader());
    const r = reader.reader();

    var out = try cwd.createFile("src/norm_tables.zig", .{});
    defer out.close();

    try out.writer().print(
        "const std = @import(\"std\");\n\n",
        .{},
    );

    try out.writer().print(
        "pub const compat_decomp = std.StaticHashMap(u21, []const u21).initComptime(.{{\n",
        .{},
    );

    var buf: [4096]u8 = undefined;

    while (try r.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var it = std.mem.splitScalar(u8, line, ';');

        const code_str = it.next() orelse continue;
        _ = it.next(); // name
        _ = it.next(); // category
        _ = it.next(); // combining
        _ = it.next(); // bidi

        const decomp = it.next() orelse continue;

        if (decomp.len == 0)
            continue;

        if (decomp[0] != '<')
            continue;

        const cp = try std.fmt.parseInt(u21, code_str, 16);

        var parts = std.mem.splitScalar(u8, decomp, ' ');

        _ = parts.next(); // skip <compat>

        try out.writer().print(" .{{ 0x{x}, &[_]u21{{", .{cp});

        while (parts.next()) |p| {
            const v = try std.fmt.parseInt(u21, p, 16);
            try out.writer().print("0x{x},", .{v});
        }

        try out.writer().print("}} }},\n", .{});
    }

    try out.writer().print("});\n", .{});
}
