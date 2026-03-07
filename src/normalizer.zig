const std = @import("std");
const tables = @import("unicode_table.zig");

pub const Error = error{
    InvalidUtf8,
};

pub const Normalizer = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Normalizer {
        return .{ .allocator = allocator };
    }

    pub fn deinit(self: *Normalizer) void {
        _ = self;
    }

    pub fn nfkc(
        self: *Normalizer,
        input: []const u8,
    ) ![]u8 {
        var out = std.ArrayList(u8).initCapacity(self.allocator, input.len);
        defer out.deinit(self.allocator);

        var it = std.unicode.Utf8Iterator{
            .bytes = input,
            .i = 0,
        };

        while (true) {
            const cp = it.nextCodepoint() catch |err| {
                if (err == error.InvalidUtf8) return Error.InvalidUtf8;
                break;
            } orelse break;

            try decompose(cp, &out);
        }

        // TODO
        // canonical ordering
        // recomposition

        return out.toOwnedSlice();
    }
};

fn decompose(cp: u21, out: *std.ArrayList(u8)) !void {
    if (tables.compat_decomp.get(cp)) |mapping| {
        for (mapping) |m| {
            try appendCodepoint(out, m);
        }
    } else {
        try appendCodepoint(out, cp);
    }
}

fn appendCodepoint(
    out: *std.ArrayList(u8),
    cp: u21,
) !void {
    var buf: [4]u8 = undefined;
    const len = try std.unicode.utf8Encode(cp, &buf);
    try out.appendSlice(buf[0..len]);
}
