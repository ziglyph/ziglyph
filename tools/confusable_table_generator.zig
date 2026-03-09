const std = @import("std");
const tools = @import("tools.zig");

const debug = false;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.smp_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const args = try std.process.argsAlloc(allocator);
    if (args.len < 3) std.debug.panic("wrong number of arguments", .{});

    const conf_file = args[1];
    const output_file = args[2];

    std.fs.cwd().access(conf_file, .{}) catch |err| switch (err) {
        error.FileNotFound => try getConfusablesFile(allocator, conf_file),
        else => {
            std.debug.print("{}\n", .{err});
        },
    };

    const read_file = try std.fs.cwd().openFile(conf_file, .{});
    defer read_file.close();

    var read_buff: [4096]u8 = undefined;
    var read_file_reader = read_file.reader(&read_buff);
    const read_file_interface = &read_file_reader.interface;

    var file = try std.fs.cwd().createFile(output_file, .{
        .truncate = true,
    });
    defer file.close();

    var file_write_buf: [4096]u8 = undefined;
    var writer = file.writerStreaming(&file_write_buf);
    const writer_interface = &writer.interface;

    // try writer_interface.print("pub const table: [_]u21 = .{{\n", .{});
    try writer_interface.writeAll(
        \\const std = @import("std");
        \\
        \\const DecompositionMap =  std.StaticStringMap(u21);
        \\
        \\pub const confusables = DecompositionMap.initComptime(confusables_entries);
        \\
        \\pub const confusables_entries = .{
        \\
    );

    while (try read_file_interface.takeDelimiter('\n')) |line| {
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
            try writer_interface.print(".{{ \"0x{x}\", 0x{x} }},\n", .{ src_cp, dst_cp });
            break; // only first codepoint matters for skeleton
        }
    }

    try writer_interface.writeAll("};\n");
    try writer_interface.flush();
}

fn getConfusablesFile(allocator: std.mem.Allocator, destination: []const u8) !void {
    try tools.downloadFile(allocator, "https://www.unicode.org/Public/security/latest/confusables.txt", destination);
}
