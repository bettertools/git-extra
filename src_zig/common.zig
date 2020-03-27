const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

pub fn promptYesNo(allocator: *Allocator, prompt: []const u8) !bool {
    var answer = ArrayList(u8).init(allocator);
    defer answer.deinit();
    while (true) {
        std.debug.warn("{}[y/n]? ", .{prompt});
        //const answer = try std.io.readLine(&buffer);
        answer.resize(0) catch @panic("codebug");
        std.io.getStdIn().inStream().readUntilDelimiterArrayList(&answer, '\n', 20) catch |e| switch (e) {
            error.StreamTooLong => continue,
            else => return e
        };
        if (std.mem.eql(u8, answer.span(), "y")) return true;
        if (std.mem.eql(u8, answer.span(), "n")) return false;
    }
}
