pub const Error = error{
    InvalidUtf8,
    OutOfMemory,
    Utf8CannotEncodeSurrogateHalf,
    CodepointTooLarge,
    NoSpaceLeft,
};

const std = @import("std");
const testing = std.testing;

test "Error set contains expected tags" {
    try testing.expect(Error.InvalidUtf8 == error.InvalidUtf8);
    try testing.expect(Error.OutOfMemory == error.OutOfMemory);
    try testing.expect(Error.Utf8CannotEncodeSurrogateHalf == error.Utf8CannotEncodeSurrogateHalf);
    try testing.expect(Error.CodepointTooLarge == error.CodepointTooLarge);
    try testing.expect(Error.NoSpaceLeft == error.NoSpaceLeft);
}

test "error matching works correctly" {
    const err: Error = Error.InvalidUtf8;

    switch (err) {
        Error.InvalidUtf8 => {},
        else => return error.TestUnexpectedResult,
    }
}

fn returnsError() Error!void {
    return Error.NoSpaceLeft;
}

test "error union returns correct error" {
    const result = returnsError();

    try testing.expectError(Error.NoSpaceLeft, result);
}

test "error set coercion" {
    const err: anyerror = Error.CodepointTooLarge;

    try testing.expect(err == Error.CodepointTooLarge);
}

test "exhaustive switch over Error" {
    inline for (@typeInfo(Error).error_set.?) |err| {
        _ = err; // ensures all error tags are referenced
    }
}
