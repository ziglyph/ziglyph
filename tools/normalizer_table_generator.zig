const std = @import("std");
const tools = @import("tools.zig");
const cwd = std.fs.cwd();

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.smp_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const args = try std.process.argsAlloc(allocator);
    if (args.len < 3) std.debug.panic("wrong number of arguments", .{});

    const unicode_data_file = args[1];
    const output_file = args[2];

    std.fs.cwd().access(unicode_data_file, .{}) catch |err| switch (err) {
        error.FileNotFound => try getUnicodeDataFile(allocator, unicode_data_file),
        else => {
            std.debug.print("{}\n", .{err});
        },
    };
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

fn getUnicodeDataFile(allocator: std.mem.Allocator, destination: []const u8) !void {
    try tools.downloadFile(allocator, "https://www.unicode.org/Public/UCD/latest/ucd/UnicodeData.txt", destination);
}
