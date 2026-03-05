const std = @import("std");

pub const Skeleton = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Skeleton {
        return .{
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Skeleton) void {
        _ = self;
    }

    pub fn run(self: *Skeleton) !void {
        _ = self;
    }
};

test "skeleton basic test" {
    const testing = std.testing;
    var sk = Skeleton.init(testing.allocator);
    defer sk.deinit();
    try sk.run();
}
