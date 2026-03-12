const std = @import("std");
const Reader = std.io.Reader;

pub fn takeUntilDelimiterOrEnd(r: *Reader, delimiter: u8) error{ReadFailed}!?[]u8 {
    const inclusive = r.peekDelimiterInclusive(delimiter) catch |err| switch (err) {
        error.EndOfStream, error.StreamTooLong => {
            const remaining = r.buffer[r.seek..r.end];
            if (remaining.len == 0) return null;

            r.toss(remaining.len);
            return remaining;
        },
        else => |e| return e,
    };

    r.toss(inclusive.len);
    return inclusive[0 .. inclusive.len - 1];
}

test "takeUntilDelimiterOrEnd returns up to delimiter" {
    var buf = "hello,world".*; // turn string literal into []u8
    var reader = std.io.Reader.fixed(&buf);

    const result = try takeUntilDelimiterOrEnd(&reader, ',');

    try std.testing.expect(std.mem.eql(u8, result.?, "hello"));
}

test "takeUntilDelimiterOrEnd returns remaining if delimiter missing" {
    var buf = "foobar".*;
    var reader = std.io.Reader.fixed(&buf);

    const result = try takeUntilDelimiterOrEnd(&reader, ',');
    try std.testing.expect(std.mem.eql(u8, result.?, "foobar"));
}

test "takeUntilDelimiterOrEnd returns null on empty input" {
    const buf: [0]u8 = undefined;
    var reader = std.io.Reader.fixed(&buf);

    const result = try takeUntilDelimiterOrEnd(&reader, ',');
    try std.testing.expect(result == null);
}

test "takeUntilDelimiterOrEnd handles delimiter at start" {
    var buf = ",rest".*;
    var reader = std.io.Reader.fixed(&buf);

    const result = try takeUntilDelimiterOrEnd(&reader, ',');
    try std.testing.expect(std.mem.eql(u8, result.?, ""));
}
