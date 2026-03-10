const std = @import("std");
const tools = @import("tools.zig");

const debug = false;

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

    try writer_interface.writeAll(
        \\const std = @import("std");
        \\const expect = std.testing.expect;
        \\const expectEqualSlices = std.testing.expectEqualSlices;
        \\
        \\const raw_entries = [_]struct { u21, []const u21 }{
        \\
    );

    var max_dest_i: usize = 0;

    while (try read_file_interface.takeDelimiter('\n')) |line| {
        if (line.len == 0) continue;
        if (line[0] == '#') continue;

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

        var dest: [25]u21 = undefined;
        var dest_i: usize = 0;
        while (parts.next()) |p| {
            const trimmed = std.mem.trim(u8, p, " \t");
            if (trimmed.len == 0) continue;

            const v = try std.fmt.parseInt(u21, trimmed, 16);
            dest[dest_i] = v;
            dest_i += 1;
        }

        if (debug and dest_i > max_dest_i) {
            max_dest_i = dest_i;
            std.debug.print(
                \\{s}
                \\{s}, max_dest_i: {d}
                \\
            ,
                .{ line, decomp, max_dest_i },
            );
        }

        try writer_interface.print(".{{ 0x{x}, &.{{", .{cp});
        for (dest[0..dest_i]) |v| {
            try writer_interface.print("0x{x},", .{v});
        }
        try writer_interface.writeAll("} },\n");
    }

    try writer_interface.writeAll(
        \\};
        \\pub const UnicodeData = struct {
        \\    keys: [raw_entries.len]u21,
        \\    values: [raw_entries.len][]const u21,
        \\
        \\    fn compare(context: u21, item: u21) std.math.Order {
        \\        return std.math.order(context, item);
        \\    }
        \\
        \\    pub fn get(self: @This(), code: u21) ?[]const u21 {
        \\        const index = std.sort.binarySearch(u21, &self.keys, code, compare) orelse return null;
        \\
        \\        return self.values[index];
        \\    }
        \\};
        \\
        \\pub const compat_decomp = blk: {
        \\    @setEvalBranchQuota(20_000);
        \\    const EntryType = struct { u21, []const u21 };
        \\    var data: [raw_entries.len]EntryType = raw_entries;
        \\
        \\    const sortFn = struct {
        \\        fn lessThan(_: void, lhs: EntryType, rhs: EntryType) bool {
        \\            return lhs[0] < rhs[0];
        \\        }
        \\    }.lessThan;
        \\
        \\    std.sort.pdq(EntryType, &data, {}, sortFn);
        \\
        \\    var keys: [data.len]u21 = undefined;
        \\    var values: [data.len][]const u21 = undefined;
        \\
        \\    for (data, 0..) |item, i| {
        \\        if (i > 0 and item[0] == data[i - 1][0]) {
        \\            @compileError(std.fmt.comptimePrint("Duplicate Unicode key found: 0x{X}", .{item[0]}));
        \\        }
        \\        keys[i] = item[0];
        \\        values[i] = item[1];
        \\    }
        \\
        \\    break :blk UnicodeData{
        \\        .keys = keys,
        \\        .values = values,
        \\    };
        \\};
        \\
        \\test "unicode decomposition lookup" {
        \\    const result1 = compat_decomp.get(0x00AA);
        \\    try expect(result1 != null);
        \\    try expectEqualSlices(u21, &.{0x0061}, result1.?);
        \\
        \\    const result2 = compat_decomp.get(0x00A8);
        \\    try expect(result2 != null);
        \\    try expectEqualSlices(u21, &.{ 0x0020, 0x0308 }, result2.?);
        \\
        \\    const result_none = compat_decomp.get(0xFFFF);
        \\    try expect(result_none == null);
        \\}
        \\
    );
    try writer_interface.flush();
}

fn getUnicodeDataFile(allocator: std.mem.Allocator, destination: []const u8) !void {
    try tools.downloadFile(allocator, "https://www.unicode.org/Public/UCD/latest/ucd/UnicodeData.txt", destination);
}
