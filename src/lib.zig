const std = @import("std");

pub const skeleton = @import("skeleton.zig");
pub const detector = @import("detector.zig");
pub const normalizer = @import("normalizer.zig");
pub const cleaner = @import("cleaner.zig");

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
