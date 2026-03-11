const std = @import("std");
const zgl = @import("ziglyph.zig");

pub const ziglyph = zgl.Ziglyph;

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

    var sk = zgl.Skeleton.init(allocator);
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

    var nm = zgl.Normalizer.init(allocator);
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

pub fn containsHomoglyph(input: []const u8) !bool {
    var arena = std.heap.ArenaAllocator.init(std.heap.smp_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var app = ziglyph.init(allocator);
    defer app.deinit();

    return app.containsHomoglyph(input);
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
