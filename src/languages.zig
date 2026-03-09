const std = @import("std");

pub const Script = enum {
    BasicLatin,
    Latin1Supplement,
    LatinExtendedA,
    LatinExtendedB,
    Greek,
    Cyrillic,
    Arabic,
    Hebrew,
    Devanagari,
    Thai,
    Lao,
    Tibetan,
    Georgian,
    Hangul,
    Hiragana,
    Katakana,
    Han,
    Emoticons,
    Miscellaneous,
    Unknown,

    pub fn toString(self: Script) []const u8 {
        return switch (self) {
            .BasicLatin => "Basic Latin (English, Western European)",
            .Latin1Supplement => "Latin-1 Supplement (Western European, Afrikaans)",
            .LatinExtendedA => "Latin Extended-A (Eastern European, Vietnamese)",
            .LatinExtendedB => "Latin Extended-B (African languages, Croatian)",
            .Greek => "Greek",
            .Cyrillic => "Cyrillic (Russian, Ukrainian, Serbian, Bulgarian)",
            .Arabic => "Arabic (Arabic, Persian, Urdu)",
            .Hebrew => "Hebrew",
            .Devanagari => "Devanagari (Hindi, Sanskrit, Nepali)",
            .Thai => "Thai",
            .Lao => "Lao",
            .Tibetan => "Tibetan",
            .Georgian => "Georgian",
            .Hangul => "Hangul (Korean)",
            .Hiragana => "Hiragana (Japanese)",
            .Katakana => "Katakana (Japanese)",
            .Han => "Han (Chinese, Japanese, Korean)",
            .Emoticons => "Emoticons/Symbols",
            .Miscellaneous => "Miscellaneous Symbols",
            .Unknown => "Unknown Script",
        };
    }
};

pub fn detectScriptFromCodePoint(codepoint: u21) Script {
    return switch (codepoint) {
        // Basic Latin (U+0000 - U+007F)
        0x0000...0x007F => .BasicLatin,

        // Latin-1 Supplement (U+0080 - U+00FF)
        0x0080...0x00FF => .Latin1Supplement,

        // Latin Extended-A (U+0100 - U+017F)
        0x0100...0x017F => .LatinExtendedA,

        // Latin Extended-B (U+0180 - U+024F)
        0x0180...0x024F => .LatinExtendedB,

        // Greek (U+0370 - U+03FF)
        0x0370...0x03FF => .Greek,

        // Cyrillic (U+0400 - U+04FF)
        0x0400...0x04FF => .Cyrillic,

        // Arabic (U+0600 - U+06FF)
        0x0600...0x06FF => .Arabic,

        // Hebrew (U+0590 - U+05FF)
        0x0590...0x05FF => .Hebrew,

        // Devanagari (U+0900 - U+097F)
        0x0900...0x097F => .Devanagari,

        // Thai (U+0E00 - U+0E7F)
        0x0E00...0x0E7F => .Thai,

        // Lao (U+0E80 - U+0EFF)
        0x0E80...0x0EFF => .Lao,

        // Tibetan (U+0F00 - U+0FFF)
        0x0F00...0x0FFF => .Tibetan,

        // Georgian (U+10A0 - U+10FF)
        0x10A0...0x10FF => .Georgian,

        // Hangul Jamo (U+1100 - U+11FF)
        // Hangul Syllables (U+AC00 - U+D7AF)
        0x1100...0x11FF, 0xAC00...0xD7AF => .Hangul,

        // Hiragana (U+3040 - U+309F)
        0x3040...0x309F => .Hiragana,

        // Katakana (U+30A0 - U+30FF)
        0x30A0...0x30FF => .Katakana,

        // CJK Unified Ideographs (U+4E00 - U+9FFF)
        0x4E00...0x9FFF => .Han,

        // Emoticons (U+1F600 - U+1F64F)
        0x1F600...0x1F64F => .Emoticons,

        // Miscellaneous Symbols (U+2600 - U+26FF)
        0x2600...0x26FF => .Miscellaneous,

        else => .Unknown,
    };
}

pub fn analyzeText(text: []const u8) !void {
    var out_buff: [4096]u8 = undefined;
    var stdout = std.fs.File.stdout().writer(&out_buff);
    const out = &stdout.interface;

    var script_counts = std.EnumMap(Script, usize).initFull(0);

    var total_chars: usize = 0;
    var utf8_view = std.unicode.Utf8View.init(text) catch |err| {
        try out.print("Invalid UTF-8: {}\n", .{err});
        return;
    };

    try out.print("\nAnalyzing text: \"{s}\"\n", .{text});
    try out.print("Character-by-character analysis:\n", .{});
    try out.print("--------------------------------\n", .{});

    var iter = utf8_view.iterator();
    while (iter.nextCodepoint()) |codepoint| {
        const script = detectScriptFromCodePoint(codepoint);

        // Update count
        const current = script_counts.get(script) orelse 0;
        script_counts.put(script, current + 1);
        total_chars += 1;

        // Print each character's info
        if (codepoint < 0x80) {
            // ASCII range
            if (std.ascii.isPrint(@intCast(codepoint))) {
                try out.print("  U+{X:0>4} '{c}' - {s}\n", .{ codepoint, @as(u8, @intCast(codepoint)), script.toString() });
            } else {
                try out.print("  U+{X:0>4} (control) - {s}\n", .{ codepoint, script.toString() });
            }
        } else {
            // Non-ASCII
            // Convert codepoint to UTF-8 for display
            var buf: [4]u8 = undefined;
            const len = try std.unicode.utf8Encode(codepoint, &buf);
            try out.print("  U+{X:0>4} '{s}' - {s}\n", .{ codepoint, buf[0..len], script.toString() });
        }
    }

    // Print summary
    try out.print("\nSummary:\n", .{});
    try out.print("--------\n", .{});
    try out.print("Total characters: {}\n", .{total_chars});

    var iter_counts = script_counts.iterator();
    while (iter_counts.next()) |entry| {
        const script = entry.value;
        const count = entry.value;
        const percentage = @as(f32, @floatFromInt(count.*)) / @as(f32, @floatFromInt(total_chars)) * 100;
        try out.print("  {d}: {} ({d:.1}%)\n", .{ script.*, count, percentage });
    }
    try out.flush();
}

test "basic usage" {
    // Example usage with various texts including U+21 (!)
    const test_strings = [_][]const u8{
        "Hello World!", // Basic Latin with !
        "!@#$%", // All symbols including !
        "こんにちは世界!", // Japanese with !
        "Привет мир!", // Russian with !
        "مرحبا بالعالم!", // Arabic with !
    };

    var out_buff: [4096]u8 = undefined;
    var stdout = std.fs.File.stdout().writer(&out_buff);
    const out = &stdout.interface;

    for (test_strings) |text| {
        try analyzeText(text);
        try out.print("\n", .{});
    }
}
