const std = @import("std");

pub const skeleton = @import("skeleton.zig");
pub const detector = @import("detector.zig");
pub const normalizer = @import("normalizer.zig");
pub const cleaner = @import("cleaner.zig");

/// Returns whether `input` contains one or more Unicode homoglyphs.
///
/// A “homoglyph” is a character that looks like another character (often ASCII),
/// but is a different code point. These are commonly used in spoofing (e.g.
/// a Cyrillic 'а' (U+0430) that looks like Latin 'a' (U+0061)).
///
/// This function:
/// - Allocates temporary detector state using an arena allocator.
/// - Runs `detector.Detector.detect` on the provided UTF-8 bytes.
/// - Frees all temporary allocations before returning.
///
/// Expected behavior:
/// - Returns `true` if a suspicious/confusable character is present.
/// - Returns `false` if none are detected.
/// - Returns an error if the detector fails to initialize or the input is not
///   valid UTF-8 (depending on `detector`’s error policy).
///
/// ## Examples
/// ASCII-only input typically yields `false`:
/// ```zig
/// const std = @import("std");
///
/// test "containsHomoglyph: ASCII returns false" {
///     try std.testing.expectEqual(false, try containsHomoglyph("hello"));
///     try std.testing.expectEqual(false, try containsHomoglyph("paypal.com"));
/// }
/// ```
///
/// Mixed-script confusable characters typically yield `true`:
/// ```zig
/// const std = @import("std");
///
/// test "containsHomoglyph: Cyrillic a in place of Latin a returns true" {
///     // "pаypal.com" where the second character is Cyrillic small letter a (U+0430),
///     // not Latin 'a' (U+0061).
///     const s = "p\u{0430}ypal.com";
///     try std.testing.expectEqual(true, try containsHomoglyph(s));
/// }
/// ```
///
/// If your detector treats invalid UTF-8 as an error, you can assert that too:
/// ```zig
/// const std = @import("std");
///
/// test "containsHomoglyph: invalid UTF-8 errors (if detector enforces UTF-8)" {
///     // Overlong / invalid sequence example (may vary by policy).
///     const bad = [_]u8{ 0xC0, 0xAF };
///     _ = containsHomoglyph(&bad) catch return; // pass if it errors
///     // If it didn't error, this test should fail because we expected an error.
///     try std.testing.expect(false);
/// }
/// ```
///
/// Note: The exact set of “homoglyphs” / confusables depends on the underlying
/// `detector` implementation and its data tables.
pub fn containsHomoglyph(input: []const u8) !bool {
    var arena = std.heap.ArenaAllocator.init(std.heap.smp_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var dt = detector.Detector.init(allocator);
    defer dt.deinit();

    return dt.detect(input);
}

export fn skeleton_compute(
    input_ptr: [*]const u8,
    input_len: usize,
    output_ptr: [*]u8,
    output_len: usize,
    written: *usize,
) callconv(.c) i32 {
    const input = input_ptr[0..input_len];

    var arena = std.heap.ArenaAllocator.init(std.heap.smp_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var sk = skeleton.Skeleton.init(allocator);
    defer sk.deinit();

    const result = sk.compute(input) catch {
        return -1;
    };
    defer allocator.free(result);

    if (result.len > output_len) {
        return -1;
    }

    @memcpy(output_ptr[0..result.len], result);
    written.* = result.len;

    return 0;
}

export fn normalizer_nfkc(
    input_ptr: [*]const u8,
    input_len: usize,
    output_ptr: [*]u8,
    output_len: usize,
    written: *usize,
) callconv(.c) i32 {
    const input = input_ptr[0..input_len];

    var arena = std.heap.ArenaAllocator.init(std.heap.smp_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var nm = normalizer.Normalizer.init(allocator);
    defer nm.deinit();

    const result = nm.nfkc(input) catch {
        return -1;
    };
    defer allocator.free(result);

    if (result.len > output_len) {
        return -1;
    }

    @memcpy(output_ptr[0..result.len], result);
    written.* = result.len;

    return 0;
}

test "containsHomoglyph true" {
    const testing = std.testing;
    // ℓ = script small l
    const input = "paypaℓ";

    try testing.expect(try containsHomoglyph(input));
}

test "containsHomoglyph false" {
    const testing = std.testing;
    // ℓ = script small l
    const input = "paypal";

    try testing.expect(!try containsHomoglyph(input));
}
