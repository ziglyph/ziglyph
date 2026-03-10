const std = @import("std");

pub const Skeleton = @import("skeleton.zig").Skeleton;
pub const Detector = @import("detector.zig").Detector;
pub const Normalizer = @import("normalizer.zig").Normalizer;
pub const Cleaner = @import("cleaner.zig").Cleaner;

pub const Ziglyph = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Ziglyph {
        return .{ .allocator = allocator };
    }

    pub fn deinit(self: *Ziglyph) void {
        _ = self;
    }

    pub fn run_skeleton(
        self: *Ziglyph,
        input: []const u8,
    ) !void {
        var sk = Skeleton.init(self.allocator);
        defer sk.deinit();

        std.debug.print("Running skeleton...\n", .{});
        const result = try sk.compute(input);

        std.debug.print(
            \\{s}
            \\{s}
            \\
        , .{ input, result });
        std.debug.print("Skeleton finished.\n", .{});
    }

    pub fn run_normalizer(
        self: *Ziglyph,
        input: []const u8,
    ) !void {
        var nm = Normalizer.init(self.allocator);
        defer nm.deinit();

        std.debug.print("Running normalizer...\n", .{});
        const result = try nm.nfkc(input);

        std.debug.print(
            \\{s}
            \\{s}
            \\
        , .{ input, result });
        std.debug.print("Normalizer finished.\n", .{});
    }

    pub fn run_cleaner(
        self: *Ziglyph,
        input: []const u8,
    ) !void {
        var cl = Cleaner.init(self.allocator);
        defer cl.deinit();

        std.debug.print("Running cleaner...\n", .{});
        const result = try cl.clean(input);

        std.debug.print(
            \\{s}
            \\{s}
            \\
        , .{ input, result });
        std.debug.print("Cleaner finished.\n", .{});
    }

    pub fn run_detector(
        self: *Ziglyph,
        input: []const u8,
    ) !void {
        std.debug.print("Running detector...\n", .{});
        const result = try self.containsHomoglyph(input);

        if (result) {
            std.debug.print("{s} contains a homoglyph\n", .{input});
        } else {
            std.debug.print("{s} does not contain a homoglyph\n", .{input});
        }
        std.debug.print("Detector finished.\n", .{});
    }

    pub fn containsHomoglyph(
        self: *Ziglyph,
        input: []const u8,
    ) !bool {
        var dt = Detector.init(self.allocator);
        defer dt.deinit();

        return dt.detect(input);
    }
};

test "containsHomoglyph true" {
    const testing = std.testing;
    // ℓ = script small l
    const input = "paypaℓ";

    try testing.expect(try Ziglyph.containsHomoglyph(input));
}

test "containsHomoglyph false" {
    const testing = std.testing;
    // ℓ = script small l
    const input = "paypal";

    try testing.expect(!try Ziglyph.containsHomoglyph(input));
}
