const std = @import("std");

const ArgsFormatter = struct {
    args: []const []const u8,
    pub fn format(
        self: ArgsFormatter,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        var prefix: ?[]const u8 = null;
        for (self.args) |arg| {
            if (prefix) |p| try writer.writeAll(p);
            // TODO: escape if necessary
            try writer.writeAll(arg);
            prefix = " ";
        }
    }
};

pub const RunGetStdout = struct {
    term: std.ChildProcess.Term,
    stdout: []u8,
    pub fn passed(self: RunGetStdout) bool { return termPassed(self.term); }
};
pub fn runGetStdout(allocator: std.mem.Allocator, argv: []const []const u8) !RunGetStdout {
    std.log.debug("[RUN] {}", .{ArgsFormatter{ .args = argv }});
    var child = std.ChildProcess.init(argv, allocator);
    child.stdin_behavior = .Ignore;
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Inherit;
    try child.spawn();

    const stdout = try child.stdout.?.readToEndAlloc(allocator, std.math.maxInt(usize));
    errdefer allocator.free(stdout);
    
    return RunGetStdout{
        .term = try child.wait(),
        .stdout = stdout,
    };
}

pub fn termPassed(term: std.ChildProcess.Term) bool {
    return switch (term) {
        .Exited => |code| code == 0,
        else => false,
    };
}
