pub const skeleton = @import("skeleton.zig");
pub const detector = @import("detector.zig");
pub const normalizer = @import("normalizer.zig");

export fn skeleton_compute(
    input_ptr: [*]const u8,
    input_len: usize,
    output_ptr: [*]u8,
    output_len: usize,
    written: *usize,
) callconv(.c) i32 {
    const std = @import("std");

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
