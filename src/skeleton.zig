const std = @import("std");
const lookup = @import("confusables.zig").table;

pub const Skeleton = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Skeleton {
        return .{ .allocator = allocator };
    }

    pub fn deinit(self: *Skeleton) void {
        _ = self;
    }

    pub fn compute(self: *Skeleton, input: []const u8) ![]u8 {
        var out = try std.ArrayList(u8).initCapacity(self.allocator, input.len);
        defer out.deinit(self.allocator);

        var it = std.unicode.Utf8Iterator{ .bytes = input, .i = 0 };

        while (it.nextCodepoint()) |cp| {
            const mapped_u32 = mapCodepoint(cp);

            // cast safely to u21
            if (mapped_u32 > 0x10FFFF)
                continue; // skip invalid codepoints
            const mapped: u21 = @intCast(mapped_u32);

            var buf: [4]u8 = undefined;
            const len = try std.unicode.utf8Encode(mapped, &buf);

            try out.appendSlice(self.allocator, buf[0..len]);
        }

        return out.toOwnedSlice(self.allocator);
    }
};

fn mapCodepoint(cp: u32) u32 {
    return lookup[cp];
}

test "basic skeleton mapping" {
    try basicSkeletonMapingTest();
}

pub fn basicSkeletonMapingTest() !void {
    const testing = std.testing;

    var sk = Skeleton.init(testing.allocator);
    defer sk.deinit();

    const input = "раураl"; // contains Cyrillic letters
    const result = try sk.compute(input);
    defer testing.allocator.free(result);

    try testing.expect(std.mem.eql(u8, result, "paypal"));
}
