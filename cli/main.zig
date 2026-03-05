const std = @import("std");
const ziglyph = @import("ziglyph");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.smp_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("Allocated: {p}\n", .{allocator.ptr});
}
