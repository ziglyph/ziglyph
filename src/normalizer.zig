const std = @import("std");
const tables = @import("unicode_table.zig");

pub const Error = error{
    InvalidUtf8,
    OutOfMemory,
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
    ) Error![]u8 {
        if (!std.unicode.utf8ValidateSlice(input)) {
            return Error.InvalidUtf8;
        }

        var out = try std.ArrayList(u8).initCapacity(self.allocator, input.len);
        errdefer out.deinit(self.allocator);

        var it = std.unicode.Utf8Iterator{
            .bytes = input,
            .i = 0,
        };

        while (it.nextCodepoint()) |cp| {
            try decompose(cp, &out);
        }

        // TODO
        // canonical ordering
        // recomposition

        return out.toOwnedSlice();
    }
};

fn decompose(cp: u21, out: *std.ArrayList(u8)) !void {
    for (tables.compat_decomp) |m| {
        try appendCodepoint(out, m[cp]);
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

test "nfkc: ascii unchanged" {
    const testing = std.testing;

    var nm = Normalizer.init(testing.allocator);
    defer nm.deinit();

    const input = "paypal";

    const out = try nm.nfkc(input);

    try std.testing.expectEqualStrings("paypal", out);
}

test "nfkc: ligature decomposition" {
    const testing = std.testing;

    var nm = Normalizer.init(testing.allocator);
    defer nm.deinit();

    // ﬀ = U+FB00
    const input = "oﬀice";

    const out = try nm.nfkc(input);

    try std.testing.expectEqualStrings("office", out);
}

test "nfkc: compatibility character" {
    const testing = std.testing;

    var nm = Normalizer.init(testing.allocator);
    defer nm.deinit();

    // ℓ = script small l
    const input = "paypaℓ";

    const out = try nm.nfkc(input);

    try std.testing.expectEqualStrings("paypal", out);
}

test "nfkc: utf8 multi byte preserved" {
    const testing = std.testing;

    var nm = Normalizer.init(testing.allocator);
    defer nm.deinit();

    const input = "café";

    const out = try nm.nfkc(input);
    defer std.testing.allocator.free(out);

    try std.testing.expectEqualStrings("café", out);
}

test "nfkc: invalid utf8" {
    const testing = std.testing;

    var nm = Normalizer.init(testing.allocator);
    defer nm.deinit();

    const input = &[_]u8{ 0xff, 0xff };

    try std.testing.expectError(
        Error.InvalidUtf8,
        nm.nfkc(input),
    );
}
