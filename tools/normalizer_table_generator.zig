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
    const read_file = try std.fs.cwd().openFile(unicode_data_file, .{});
    defer read_file.close();

    var read_buff: [4096]u8 = undefined;
    var read_file_reader = read_file.reader(&read_buff);
    const read_file_interface = &read_file_reader.interface;

    var generated_file = try std.fs.cwd().createFile(output_file, .{
        .truncate = true,
    });
    defer generated_file.close();

    var file_write_buf: [4096]u8 = undefined;
    var writer = generated_file.writerStreaming(&file_write_buf);
    const writer_interface = &writer.interface;

    try writer_interface.writeAll("const std = @import(\"std\");\n\n");

    try writer_interface.writeAll(
        \\pub const CompatEntry = struct {
        \\    cp: u21,
        \\    map: []const u21,
        \\};
        \\
        \\pub const compat_decomp = [_]CompatEntry{
        \\
    );

    while (try read_file_interface.takeDelimiter('\n')) |line| {
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

        try writer_interface.print(" .{{ .cp = 0x{x}, .map = &[_]u21{{", .{cp});

        while (parts.next()) |p| {
            const v = try std.fmt.parseInt(u21, p, 16);
            try writer_interface.print("0x{x},", .{v});
        }

        try writer_interface.print("}} }},\n", .{});
    }

    try writer_interface.writeAll("};\n");
    try writer_interface.flush();
}

fn getUnicodeDataFile(allocator: std.mem.Allocator, destination: []const u8) !void {
    try tools.downloadFile(allocator, "https://www.unicode.org/Public/UCD/latest/ucd/UnicodeData.txt", destination);
}
