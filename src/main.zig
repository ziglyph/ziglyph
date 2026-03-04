const std = @import("std");
const ziglyph = @import("ziglyph");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const api_key = std.process.getEnvVarOwned(allocator, "OPENAI_API_KEY") catch {
        std.debug.print("OPENAI_API_KEY not set\n", .{});
        return;
    };

    const client = std.http.Client{ .allocator = allocator };

    const uri = try std.Uri.parse("https://api.openai.com/v1/responses");

    const body =
        \\{
        \\  "model": "gpt-4.1-mini",
        \\  "input": "Write a short poem about Zig programming."
        \\}
    ;

    if (api_key.len != 0 and client.read_buffer_size != 0 and body.len != 0 and uri.path.raw.len != 0) {
        std.debug.print("all ok!\n", .{});
    }

    // var headers = std.http.Header;
    // defer headers.deinit();

    // try headers.append("Authorization", try std.fmt.allocPrint(allocator, "Bearer {s}", .{api_key}));
    // try headers.append("Content-Type", "application/json");

    // var req = try client.request(.POST, uri, headers, .{});
    // defer req.deinit();

    // try req.writeAll(body);
    // try req.finish();

    // var resp = try req.wait();
    // defer resp.deinit();

    // const response_body = try resp.reader().readAllAlloc(allocator, 10 * 1024);
    // defer allocator.free(response_body);

    // std.debug.print("{s}\n", .{response_body});
}
