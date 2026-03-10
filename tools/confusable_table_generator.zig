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
        \\const expect = std.testing.expect;
        \\const expectEqualSlices = std.testing.expectEqualSlices;
        \\
        \\const raw_entries = [_]struct { u21, u21 }{
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
            try writer_interface.print(".{{ 0x{x}, 0x{x} }},\n", .{ src_cp, dst_cp });
            break; // only first codepoint matters for skeleton
        }
    }

    try writer_interface.writeAll(
        \\};
        \\
        \\pub const UnicodeData = struct {
        \\    keys: [raw_entries.len]u21,
        \\    values: [raw_entries.len]u21,
        \\
        \\    fn compare(context: u21, item: u21) std.math.Order {
        \\        return std.math.order(context, item);
        \\    }
        \\
        \\    pub fn get(self: @This(), code: u21) ?u21 {
        \\        const index = std.sort.binarySearch(u21, &self.keys, code, compare) orelse return null;
        \\
        \\        return self.values[index];
        \\    }
        \\};
        \\
        \\pub const confusables = blk: {
        \\    @setEvalBranchQuota(1_200_000);
        \\    const EntryType = struct { u21, u21 };
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
        \\    var values: [data.len]u21 = undefined;
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
        \\test "confusables lookup" {
        \\    const result1 = confusables.get(0x00AA);
        \\    try expect(result1 == null);
        \\
        \\    const result2 = confusables.get(0x00A8);
        \\    try expect(result2 == null);
        \\
        \\    const result_none = confusables.get(0xFFFF);
        \\    try expect(result_none == null);
        \\}
    );
    try writer_interface.flush();
}

fn getConfusablesFile(allocator: std.mem.Allocator, destination: []const u8) !void {
    try tools.downloadFile(allocator, "https://www.unicode.org/Public/security/latest/confusables.txt", destination);
}
