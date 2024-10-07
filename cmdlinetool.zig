/// A small library with functions that assumes that errors get
/// logged to stderr.  Functions that fail in this module may choost
/// to log to stderr and return an AlreadyReported error.
const std = @import("std");

const runutil = @import("zogrunutil.zig");

fn logRun(allocator: std.mem.Allocator, argv: []const []const u8) !void {
    var buffer = try allocator.alloc(u8, runutil.getCommandStringLength(argv));
    defer allocator.free(buffer);
    runutil.writeCommandString(buffer.ptr, argv);
    try std.io.getStdErr().writer().print("[RUN] {s}\n", .{buffer});
}

pub fn runGetOutput(
    allocator: std.mem.Allocator,
    argv: []const []const u8,
) !std.ChildProcess.ExecResult {
    try logRun(allocator, argv);
    return std.ChildProcess.exec(.{
        .allocator = allocator,
        .argv = argv,
        .cwd = null,
        .env_map = null,
        .max_output_bytes = std.math.maxInt(usize),
        .expand_arg0 = .no_expand,
    }) catch |err|{
        std.log.err("failed to execute '{s}': {}", .{argv[0], err});
        return error.AlreadyReported;
    };
}

pub fn run(allocator: std.mem.Allocator, argv: []const []const u8) !std.ChildProcess.Term {
    try logRun(allocator, argv);
    var proc = std.ChildProcess.init(argv, allocator);
    return proc.spawnAndWait();
}

pub fn dumpExecResult(result: std.ChildProcess.ExecResult) !bool {
    var hasOutput = false;
    if (result.stdout.len > 0) {
        hasOutput = true;
        try std.io.getStdErr().writer().writeAll(result.stdout);
    }
    if (result.stderr.len > 0) {
        hasOutput = true;
        try std.io.getStdErr().writer().writeAll(result.stderr);
    }
    return hasOutput;
}

pub fn enforceRunGetOutputPassed(allocator: std.mem.Allocator, result: std.ChildProcess.ExecResult) ![]u8 {
    switch (result.term) {
        .Exited => {
            if (result.term.Exited != 0) {
                if (!try dumpExecResult(result)) {
                    std.log.err("last process exited with code {}", .{result.term.Exited});
                }
                return error.AlreadyReported;
            }
        },
        else => {
            if (!try dumpExecResult(result)) {
                std.log.err("last process failed with {}", .{result.term});
            }
            return error.AlreadyReported;
        },
    }
    return runutil.runCombineOutput(allocator, &result);
}

pub fn enforceRunPassed(term: std.ChildProcess.Term) error{AlreadyReported}!void {
    switch (term) {
        .Exited => {
            if (term.Exited != 0) {
                std.log.err("last process exited with code {}", .{term.Exited});
                return error.AlreadyReported;
            }
        },
        else => {
            std.log.err("last process failed with {}", .{term});
            return error.AlreadyReported;
        },
    }
}
