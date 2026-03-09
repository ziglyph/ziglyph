const std = @import("std");
const skeleton = @import("skeleton.zig");
const normalizer = @import("normalizer.zig");

pub const Detector = struct {
    allocator: std.mem.Allocator,
    nm: normalizer.Normalizer,
    sk: skeleton.Skeleton,

    pub fn detect(self: *Detector, input: []const u8) !bool {
        const normalized_input = try self.nm.nfkc(input);
        defer self.allocator.free(normalized_input);

        if (!std.mem.eql(u8, normalized_input, input)) {
            return true;
        }

        const skeleton_input = try self.sk.compute(input);
        defer self.allocator.free(skeleton_input);

        if (!std.mem.eql(u8, skeleton_input, input)) {
            return true;
        }

        return false;
    }

    pub fn init(allocator: std.mem.Allocator) Detector {
        return .{
            .allocator = allocator,
            .nm = normalizer.Normalizer.init(allocator),
            .sk = skeleton.Skeleton.init(allocator),
        };
    }

    pub fn deinit(self: *Detector) void {
        defer self.nm.deinit();
        defer self.sk.deinit();
    }
};

test "nfkc: utf8 multi byte preserved" {
    const testing = std.testing;

    var dt = Detector.init(testing.allocator);
    defer dt.deinit();

    const input = "café";

    const out = try dt.detect(input);
    // defer std.testing.allocator.free(out);

    try std.testing.expect(!out);
}
