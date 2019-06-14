/// A small library with functions that assumes that errors get
/// logged to stderr.  Functions that fail in this module may choost
/// to log to stderr and return an AlreadyReported error.
const std = @import("std");

const varargs = @import("./varargs.zig");
const appendlib = @import("./appendlib.zig");
const runutil = @import("./runutil.zig");

pub fn log(comptime fmt: []const u8, args: ...) void {
    std.debug.warn(fmt ++ "\n", args);
}

pub const AlreadyReportedError = error {
    AlreadyReported,
};

pub const ErrorReported = AlreadyReportedError.AlreadyReported;

fn logRun(allocator: *std.mem.Allocator, argv: []const []const u8) !void {
    var buffer = try allocator.alloc(u8, runutil.getCommandStringLength(argv));
    defer allocator.free(buffer);

    var appender = appendlib.FixedAppender(u8).init(buffer);
    runutil.appendCommandString(&appender.appender, argv);
    std.debug.assert(appender.full());
    log("[RUN] {}", buffer);
}

pub fn runGetOutput(allocator: *std.mem.Allocator, args: ...) !std.ChildProcess.ExecResult {
    var argv = try varargs.allocVarargs([]const u8, allocator, args);
    defer allocator.free(argv);
    return runGetOutputArray(allocator, argv);
}

pub fn runGetOutputArray(allocator: *std.mem.Allocator, argv: []const []const u8) !std.ChildProcess.ExecResult {
    try logRun(allocator, argv);
    return std.ChildProcess.exec(allocator, argv, null, null, std.math.maxInt(usize)) catch |err| {
        log("Error: failed to execute '{}': {}", argv[0], err);
        return ErrorReported;
    };
}

pub fn run(allocator: *std.mem.Allocator, args: ...) !std.ChildProcess.Term {
    var argv = try varargs.allocVarargs([]const u8, allocator, args);
    defer allocator.free(argv);
    return runArray(allocator, argv);
}
pub fn runArray(allocator: *std.mem.Allocator, argv: []const []const u8) !std.ChildProcess.Term {
    try logRun(allocator, argv);
    var proc = try std.ChildProcess.init(argv, allocator);
    defer proc.deinit();
    return proc.spawnAndWait();
}

pub fn dumpExecResult(result: std.ChildProcess.ExecResult) bool {
    var hasOutput = false;
    if (result.stdout.len > 0) {
        hasOutput = true;
        log("{}", result.stdout);
    }
    if (result.stderr.len > 0) {
        hasOutput = true;
        log("{}", result.stderr);
    }
    return hasOutput;
}

pub fn enforceRunGetOutputPassed(allocator: *std.mem.Allocator, result: std.ChildProcess.ExecResult) ![]u8 {
    switch (result.term) {
        .Exited => {
            if (result.term.Exited != 0) {
                if (!dumpExecResult(result)) {
                    log("Error: last process exited with code {}", result.term.Exited);
                }
                return ErrorReported;
            }
        },
        else => {
            if (!dumpExecResult(result)) {
                log("Error: last process failed with {}", result.term);
            }
            return ErrorReported;
        },
    }
    return runutil.runCombineOutput(allocator, &result);
}

pub fn enforceRunPassed(term: std.ChildProcess.Term) !void {
    switch (term) {
        .Exited => {
            if (term.Exited != 0) {
                log("Error: last process exited with code {}", term.Exited);
                return ErrorReported;
            }
        },
        else => {
            log("Error: last process failed with {}", term);
            return ErrorReported;
        },
    }
}
