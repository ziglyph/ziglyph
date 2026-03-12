const std = @import("std");
const Reader = std.io.Reader;

/// Reads from a buffered reader up to `delimiter`, or returns the rest of the buffered data.
///
/// This helper is designed for readers that expose:
/// - `peekDelimiterInclusive(delimiter)` returning the buffered bytes **including** the delimiter
/// - `toss(n)` to consume bytes from the buffer
/// - internal buffer window fields: `buffer`, `seek`, `end`
///
/// Behavior:
/// - If `delimiter` is found in the currently buffered data, consumes through the delimiter and
///   returns a slice of the bytes *before* the delimiter.
/// - If `peekDelimiterInclusive` reports `error.EndOfStream` or `error.StreamTooLong`, returns the
///   remaining buffered bytes (consuming them) and **does not** require a delimiter.
/// - Returns `null` if there are no remaining buffered bytes in those error cases.
/// - Propagates any other error as `error.ReadFailed`.
///
/// Returns:
/// - `null` when there is nothing to return (no bytes remaining and no delimiter found)
/// - `[]u8` slice pointing into the reader's internal buffer window (valid until the reader refills/changes)
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

test "delimiter found: returns bytes before delimiter and consumes inclusive length" {
    var buf = [_]u8{ 'a', 'b', 'c', ',', 'd', 'e' };
    var reader = std.io.Reader.fixed(&buf);

    const out = try takeUntilDelimiterOrEnd(&reader, ',');
    try std.testing.expect(out != null);
    try std.testing.expectEqualStrings("abc", out.?);
    try std.testing.expectEqual(@as(usize, 4), reader.seek); // consumed "abc,"
}

test "end-of-stream: returns remaining buffered bytes and consumes them" {
    var buf = [_]u8{ 'x', 'y', 'z' };
    var reader = std.io.Reader.fixed(&buf);

    const out = try takeUntilDelimiterOrEnd(&reader, '\n');
    try std.testing.expect(out != null);
    try std.testing.expectEqualStrings("xyz", out.?);
    try std.testing.expectEqual(@as(usize, 3), reader.seek);
}

test "stream-too-long: returns remaining buffered bytes and consumes them" {
    var buf = [_]u8{ '1', '2', '3', '4' };
    var reader = std.io.Reader.fixed(&buf);

    const out = try takeUntilDelimiterOrEnd(&reader, '\n');
    try std.testing.expect(out != null);
    try std.testing.expectEqualStrings("1234", out.?);
    try std.testing.expectEqual(@as(usize, 4), reader.seek);
}

test "end-of-stream with no remaining bytes: returns null" {
    var buf = [_]u8{};
    var reader = std.io.Reader.fixed(&buf);

    const out = try takeUntilDelimiterOrEnd(&reader, '\n');
    try std.testing.expect(out == null);
    try std.testing.expectEqual(@as(usize, 0), reader.seek);
}
