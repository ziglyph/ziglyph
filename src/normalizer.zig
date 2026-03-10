const std = @import("std");
const tables = @import("unicode_table.zig");

pub const Error = error{
    InvalidUtf8,
    OutOfMemory,
    Utf8CannotEncodeSurrogateHalf,
    CodepointTooLarge,
    NoSpaceLeft,
};

pub const Normalizer = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Normalizer {
        return .{ .allocator = allocator };
    }

    pub fn deinit(self: *Normalizer) void {
        _ = self;
    }

    /// Converts a UTF-8 string to its NFKC (Normalization Form KC) normalized form.
    ///
    /// NFKC normalization performs compatibility decomposition followed by
    /// canonical composition. This form is useful for text processing where
    /// compatibility equivalence is desired, such as search indexing or
    /// string comparison where visual distinctions shouldn't matter.
    ///
    /// The normalization process follows these steps:
    /// 1. Validate the input is valid UTF-8
    /// 2. Perform compatibility decomposition (NFKD) - breaking characters into
    ///    base characters and combining marks, with compatibility characters
    ///    replaced by their decomposed forms
    /// 3. Apply canonical ordering - reordering combining marks in a specific
    ///    order required by Unicode
    /// 4. Perform canonical composition (compose back to NFC) - combining base
    ///    characters and combining marks where possible
    ///
    /// Note: This function currently implements only the decomposition step.
    /// Canonical ordering and recomposition are TODO items.
    ///
    /// ### Parameters
    /// - `self`: Pointer to the Normalizer instance containing the allocator
    /// - `input`: Slice of bytes containing the UTF-8 text to normalize
    ///
    /// ### Returns
    /// - `Error![]u8`: A newly allocated UTF-8 string in NFKC form, or an error
    ///
    /// ### Errors
    /// - `Error.InvalidUtf8`: The input is not valid UTF-8
    /// - `std.mem.Allocator.Error`: If memory allocation fails during processing
    ///
    /// ### Memory Management
    /// The caller owns the returned slice and must free it using the same allocator
    /// that was provided to the Normalizer instance.
    ///
    /// ### Example
    /// ```zig
    /// var normalizer = try Normalizer.init(allocator);
    /// defer normalizer.deinit();
    ///
    /// // "ﬁ" (U+FB01) is decomposed to "f" + "i" (U+0066 U+0069)
    /// const result = try normalizer.nfkc("ﬁ");
    /// defer allocator.free(result);
    /// try std.testing.expectEqualStrings("fi", result);
    /// ```
    pub fn nfkc(
        self: *Normalizer,
        input: []const u8,
    ) Error![]u8 {
        if (!std.unicode.utf8ValidateSlice(input)) {
            return Error.InvalidUtf8;
        }

        var out = try std.ArrayList(u8).initCapacity(self.allocator, input.len);
        defer out.deinit(self.allocator);

        var it = std.unicode.Utf8Iterator{
            .bytes = input,
            .i = 0,
        };

        while (it.nextCodepoint()) |cp| {
            try self.decompose(cp, &out);
        }

        // TODO:
        // - Canonical ordering: Reorder combining marks according to
        //   Unicode Canonical Ordering Algorithm
        // - Recomposition: Compose back to NFC form where possible
        //   (but maintaining compatibility decomposition)

        return out.toOwnedSlice(self.allocator);
    }

    fn decompose(
        self: *Normalizer,
        cp: u21,
        out: *std.ArrayList(u8),
    ) !void {
        var buff: [16]u8 = undefined;
        const slice = try std.fmt.bufPrint(&buff, "0x{x}", .{cp});
        const decomp = tables.compat_decomp.get(slice) orelse &.{cp};
        for (decomp) |v| {
            try self.appendCodepoint(out, v);
        }
    }

    fn appendCodepoint(
        self: *Normalizer,
        out: *std.ArrayList(u8),
        cp: u21,
    ) !void {
        var buf: [25]u8 = undefined;
        const len = try std.unicode.utf8Encode(cp, &buf);
        try out.appendSlice(self.allocator, buf[0..len]);
    }
};

test "nfkc: ascii unchanged" {
    const testing = std.testing;

    var nm = Normalizer.init(testing.allocator);
    defer nm.deinit();

    const input = "paypal";

    const out = try nm.nfkc(input);
    defer std.testing.allocator.free(out);

    try std.testing.expectEqualStrings("paypal", out);
}

test "nfkc: ligature decomposition" {
    const testing = std.testing;

    var nm = Normalizer.init(testing.allocator);
    defer nm.deinit();

    // ﬀ = U+FB00
    const input = "oﬀice";

    const out = try nm.nfkc(input);
    defer std.testing.allocator.free(out);

    try std.testing.expectEqualStrings("office", out);
}

test "nfkc: compatibility character" {
    const testing = std.testing;

    var nm = Normalizer.init(testing.allocator);
    defer nm.deinit();

    // ℓ = script small l
    const input = "paypaℓ";

    const out = try nm.nfkc(input);
    defer std.testing.allocator.free(out);

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

test "nfkc: cyrillic" {
    var nm = Normalizer.init(std.testing.allocator);
    defer nm.deinit();

    const input = "кафе";

    const out = try nm.nfkc(input);
    defer std.testing.allocator.free(out);

    try std.testing.expectEqualStrings(input, out);
}
