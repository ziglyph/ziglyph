const std = @import("std");

pub const Detector = struct {
    pub fn detect(input: []const u8) bool {
        // placeholder: returns false for now
        _ = input;
        return false;
    }
};

test "detector dummy test" {
    try std.testing.expect(!Detector.detect("test"));
}
