const std = @import("std");

// todo: use quotes if arg contains spaces
pub fn getCommandStringLength(argv: []const []const u8) usize {
    var len: usize = 0;
    var prefixLength: u8 = 0;
    for (argv) |arg| {
        len += prefixLength + arg.len;
        prefixLength = 1;
    }
    return len;
}

pub fn writeCommandString(buf: [*]u8, argv: []const []const u8) void {
    var next = buf;
    var prefix: []const u8 = "";
    for (argv) |arg| {
        if (prefix.len > 0) {
            @memcpy(next, prefix);
            next += prefix.len;
        }
        @memcpy(next, arg);
        next += arg.len;
        prefix = " ";
    }
}

pub fn runPassed(result: *const std.process.Child.RunResult) bool {
    switch (result.term) {
        .Exited => {
            return result.term.Exited == 0;
        },
        else => {
            return false;
        },
    }
}
pub fn runFailed(result: *const std.process.Child.RunResult) bool {
    return !runPassed(result);
}

pub fn runCombineOutput(allocator: std.mem.Allocator, result: *const std.process.Child.RunResult) ![]u8 {
    if (result.stderr.len == 0) {
        return result.stdout;
    }
    if (result.stdout.len == 0) {
        return result.stderr;
    }
    const combined = try allocator.alloc(u8, result.stdout.len + result.stderr.len);
    @memcpy(combined, result.stdout);
    @memcpy(combined[result.stdout.len..], result.stderr);
    return combined;
}
