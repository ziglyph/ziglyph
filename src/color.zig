pub const Color = enum {
    red,
    green,
    yellow,
    blue,
    reset,

    pub fn code(self: Color) []const u8 {
        return switch (self) {
            .red => "\x1b[31m",
            .green => "\x1b[32m",
            .yellow => "\x1b[33m",
            .blue => "\x1b[34m",
            .reset => "\x1b[0m",
        };
    }
};
