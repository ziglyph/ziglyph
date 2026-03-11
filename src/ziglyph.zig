const std = @import("std");

pub const Skeleton = @import("skeleton.zig").Skeleton;
pub const Detector = @import("detector.zig").Detector;
pub const Normalizer = @import("normalizer.zig").Normalizer;
pub const Cleaner = @import("cleaner.zig").Cleaner;

pub const Ziglyph = struct {
    allocator: std.mem.Allocator,
    input: *std.Io.Reader,
    out: *std.Io.Writer,

    pub fn initStreaming(
        allocator: std.mem.Allocator,
        input: *std.Io.Reader,
        out: *std.Io.Writer,
    ) Ziglyph {
        return .{
            .allocator = allocator,
            .input = input,
            .out = out,
        };
    }

    pub fn init(
        allocator: std.mem.Allocator,
    ) Ziglyph {
        return .{
            .allocator = allocator,
            .input = undefined,
            .out = undefined,
        };
    }

    pub fn deinit(self: *Ziglyph) void {
        _ = self;
    }

    pub fn run_skeleton(
        self: *Ziglyph,
    ) !void {
        var sk = Skeleton.init(self.allocator);
        defer sk.deinit();

        line: while (try self.input.takeDelimiter('\n')) |raw_line| {
            const line = std.mem.trim(u8, raw_line, " \t\r");
            if (line.len == 0) continue;

            try self.out.print("{s}\n", .{line});

            var it = std.mem.splitScalar(u8, line, ' ');
            while (it.next()) |word| {
                const result = sk.compute(word) catch |err| switch (err) {
                    error.InvalidUtf8 => {
                        continue :line;
                    },
                    else => return err,
                };
                try self.out.print("{s} ", .{result});
            }

            try self.out.writeAll("\n");
        }

        try self.out.flush();
    }

    pub fn run_normalizer(
        self: *Ziglyph,
    ) !void {
        var nm = Normalizer.init(self.allocator);
        defer nm.deinit();

        line: while (try self.input.takeDelimiter('\n')) |raw_line| {
            const line = std.mem.trim(u8, raw_line, " \t\r");
            if (line.len == 0) continue;

            try self.out.print("{s}\n", .{line});

            var it = std.mem.splitScalar(u8, line, ' ');
            while (it.next()) |word| {
                const result = nm.nfkc(word) catch |err| switch (err) {
                    error.InvalidUtf8 => {
                        continue :line;
                    },
                    else => return err,
                };
                try self.out.print("{s} ", .{result});
            }

            try self.out.writeAll("\n");
        }

        try self.out.flush();
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
    ) !void {
        var line_counter: usize = 1;

        line: while (try self.input.takeDelimiter('\n')) |raw_line| : (line_counter += 1) {
            const line = std.mem.trim(u8, raw_line, " \t\r");
            if (line.len == 0) continue;

            var it = std.mem.splitScalar(u8, line, ' ');
            while (it.next()) |word| {
                const result = self.containsHomoglyph(word) catch |err| switch (err) {
                    error.InvalidUtf8 => {
                        continue :line;
                    },
                    else => return err,
                };

                if (result) {
                    try self.out.print("{d}: {s}\n", .{ line_counter, line });
                }
            }
        }
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
