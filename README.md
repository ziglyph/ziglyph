# ZiGlyph

ZiGlyph is a lightweight homoglyph detection library and CLI tool
written in Zig.

It detects visually similar Unicode characters that can be used to
impersonate legitimate text such as domains, usernames, package names,
or URLs.

------------------------------------------------------------------------

## What Is a Homoglyph Attack?

A homoglyph is a character that looks like another character but has a
different Unicode code point.

Example:

example.com exаmple.com

The second string uses a Cyrillic "а" (U+0430) instead of the Latin "a"
(U+0061).

These tricks are commonly used in phishing domains, malicious packages,
fake usernames, and misleading URLs.

------------------------------------------------------------------------

## Features

-   Detect visually similar Unicode characters
-   Identify suspicious mixed-script strings
-   CLI tool for quick checks
-   Zig library for integration
-   Small and fast
-   Minimal dependencies

------------------------------------------------------------------------

## Installation

Clone the repository and build with Zig.

``` bash
git clone https://github.com/ziglyph/ziglyph.git
cd ziglyph
zig build
```

The CLI binary will be located at:

    zig-out/bin/zgl

------------------------------------------------------------------------

## CLI Usage

### Check a string

``` bash
zgl check "exаmple.com"
```

### Compare two strings

``` bash
zgl compare "example.com" "exаmple.com"
```

### Generate a skeleton

``` bash
zgl skeleton "exаmple.com"
```

------------------------------------------------------------------------

## Library Usage

Example Zig program:

``` zig
const std = @import("std");
const ziglyph = @import("ziglyph");

pub fn main() !void {
    const input = "exаmple.com";

    if (ziglyph.containsHomoglyph(input)) {
        std.debug.print("Potential homoglyph detected: {s}\n", .{input});
    }
}
```

------------------------------------------------------------------------

## Project Structure

    ziglyph/
    ├── build.zig
    ├── build.zig.zon
    ├── src/
    │   ├── ziglyph.zig
    │   ├── skeleton.zig
    │   ├── homoglyph.zig
    │   └── tables.zig
    ├── cli/
    │   └── main.zig
    ├── tests/
    └── README.md

------------------------------------------------------------------------

## Testing

    zig build test

------------------------------------------------------------------------

## License

MIT License
