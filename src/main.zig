const std = @import("std");
const ziglyph = @import("ziglyph");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.smp_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const api_key = std.process.getEnvVarOwned(allocator, "OPENAI_API_KEY") catch {
        std.debug.print("OPENAI_API_KEY not set\n", .{});
        return;
    };

    var client = std.http.Client{ .allocator = allocator };

    const uri = try std.Uri.parse("https://api.openai.com/v1/responses");

    const body_literal =
        \\{
        \\ "model":"gpt-5.2",
        \\ "input":"Generate 3 startup ideas."
        \\}
    ;

    const body: []u8 = try allocator.alloc(u8, body_literal.len);
    defer allocator.free(body);
    @memcpy(body, body_literal);

    if (api_key.len != 0 and client.read_buffer_size != 0 and body.len != 0 and uri.scheme.len != 0) {
        std.debug.print("all ok!\n", .{});
    }

    const headers = [_]std.http.Header{ .{
        .name = "Authorization",
        .value = try std.fmt.allocPrint(allocator, "Bearer {s}", .{api_key}),
    }, .{
        .name = "Content-Type",
        .value = "application/json",
    } };

    var req = try client.request(.POST, uri, .{ .extra_headers = &headers });
    defer req.deinit();

    try req.sendBodyComplete(body);

    const receive_buffer: []u8 = undefined;
    var resp = try req.receiveHead(receive_buffer);

    if (resp.head.status != .ok) {
        std.debug.print("Response status: {s}\n", .{resp.head.bytes});
        return;
    }

    const resp_body = try resp.reader(&.{}).allocRemaining(allocator, .limited(10 * 1024));
    defer allocator.free(body);
    std.debug.print("Body:\n{s}\n", .{resp_body});
}
