const std = @import("std");
const skeleton = @import("skeleton.zig");
const normalizer = @import("normalizer.zig");

pub const Cleaner = struct {
    allocator: std.mem.Allocator,
    nm: normalizer.Normalizer,
    sk: skeleton.Skeleton,

    pub fn clean(self: *Cleaner, input: []const u8) ![]const u8 {
        const normalized_input = try self.nm.nfkc(input);
        defer self.allocator.free(normalized_input);

        const skeleton_input = try self.sk.compute(normalized_input);

        return skeleton_input;
    }

    pub fn init(allocator: std.mem.Allocator) Cleaner {
        return .{
            .allocator = allocator,
            .nm = normalizer.Normalizer.init(allocator),
            .sk = skeleton.Skeleton.init(allocator),
        };
    }

    pub fn deinit(self: *Cleaner) void {
        defer self.nm.deinit();
        defer self.sk.deinit();
    }
};

test "Cleaner: utf8 multi byte preserved" {
    const testing = std.testing;

    var cl = Cleaner.init(testing.allocator);
    defer cl.deinit();

    const input = "café";

    const out = try cl.clean(input);
    defer std.testing.allocator.free(out);

    try std.testing.expectEqualStrings(out, input);
}
