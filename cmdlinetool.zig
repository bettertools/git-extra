/// A small library with functions that assumes that errors get
/// logged to stderr.  Functions that fail in this module may choost
/// to log to stderr and return an AlreadyReported error.
const std = @import("std");

const runutil = @import("zogrunutil.zig");

fn logRun(argv: []const []const u8) !void {
    var buffer: [1000]u8 = undefined;
    var file_writer = std.fs.File.stderr().writer(&buffer);
    const writer = &file_writer.interface;
    try writer.writeAll("[RUN] ");
    var prefix: []const u8 = "";
    for (argv) |arg| {
        try writer.writeAll(prefix);
        try writer.writeAll(arg);
        prefix = " ";
    }
    try writer.writeAll("\n");
    try writer.flush();
}

pub fn runGetOutput(
    allocator: std.mem.Allocator,
    argv: []const []const u8,
) !std.process.Child.RunResult {
    try logRun(argv);
    return std.process.Child.run(.{
        .allocator = allocator,
        .argv = argv,
        .cwd = null,
        .env_map = null,
        .max_output_bytes = std.math.maxInt(usize),
        .expand_arg0 = .no_expand,
    }) catch |err| {
        std.log.err("failed to execute '{s}': {}", .{ argv[0], err });
        return error.AlreadyReported;
    };
}

pub fn run(allocator: std.mem.Allocator, argv: []const []const u8) !std.process.Child.Term {
    try logRun(argv);
    var proc = std.process.Child.init(argv, allocator);
    return proc.spawnAndWait();
}

pub fn dumpRunResult(result: std.process.Child.RunResult) !bool {
    var hasOutput = false;
    if (result.stdout.len > 0) {
        hasOutput = true;
        try std.fs.File.stderr().writeAll(result.stdout);
    }
    if (result.stderr.len > 0) {
        hasOutput = true;
        try std.fs.File.stderr().writeAll(result.stderr);
    }
    return hasOutput;
}

pub fn enforceRunGetOutputPassed(allocator: std.mem.Allocator, result: std.process.Child.RunResult) ![]u8 {
    switch (result.term) {
        .Exited => {
            if (result.term.Exited != 0) {
                if (!try dumpRunResult(result)) {
                    std.log.err("last process exited with code {}", .{result.term.Exited});
                }
                return error.AlreadyReported;
            }
        },
        else => {
            if (!try dumpRunResult(result)) {
                std.log.err("last process failed with {}", .{result.term});
            }
            return error.AlreadyReported;
        },
    }
    return runutil.runCombineOutput(allocator, &result);
}

pub fn enforceRunPassed(term: std.process.Child.Term) error{AlreadyReported}!void {
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
