pub const skeleton = @import("skeleton.zig");
pub const detector = @import("detector.zig");
pub const normalizer = @import("normalizer.zig");

// const std = @import("std");
//
// export fn compute(input_ptr: [*]const u8, input_len: usize, output_ptr: [*]u8, output_len: usize) callconv(.{ .x86_fastcall =  }) isize {
//     // Convert to Zig slices for internal use
//     const input = input_ptr[0..input_len];
//     const output = output_ptr[0..output_len];
//
//     var arena = std.heap.ArenaAllocator.init(std.heap.smp_allocator);
//     defer arena.deinit();
//     const allocator = arena.allocator();
//
//     var sk = skeleton.Skeleton.init(allocator);
//     defer sk.deinit();
//
//     const result = try sk.compute(input);
//     defer allocator.free(result);
//
//     return @as(isize, @intCast(result.len));
// }
