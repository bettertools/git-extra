const builtin = @import("builtin");
const std = @import("std");
const runutil = @import("runutil.zig");

pub const std_options: std.Options = .{
    .log_level = .info,
};

var arena_instance = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const arena = arena_instance.allocator();

pub fn oom(e: error{OutOfMemory}) noreturn {
    @panic(@errorName(e));
}

fn usage() !void {
    try std.io.getStdErr().writer().writeAll(
        \\Usage: git merged BRANCH
        \\Shows branches that have been merged into the given branch.
        \\
    );
}

var windows_args_arena = if (builtin.os.tag == .windows)
    std.heap.ArenaAllocator.init(std.heap.page_allocator)
else
    struct {}{};
pub fn cmdlineArgs() [][*:0]u8 {
    if (builtin.os.tag == .windows) {
        const slices = std.process.argsAlloc(windows_args_arena.allocator()) catch |err| switch (err) {
            error.OutOfMemory => oom(error.OutOfMemory),
            //error.InvalidCmdLine => @panic("InvalidCmdLine"),
            error.Overflow => @panic("Overflow while parsing command line"),
        };
        const args = windows_args_arena.allocator().alloc([*:0]u8, slices.len - 1) catch |e| oom(e);
        for (slices[1..], 0..) |slice, i| {
            args[i] = slice.ptr;
        }
        return args;
    }
    return std.os.argv.ptr[1..std.os.argv.len];
}

fn getSha(refspec: []const u8) ![]const u8 {
    const sha = blk: {
        const result = try runutil.runGetStdout(arena, &.{
            "git",
            "rev-parse",
            refspec,
        });
        if (!result.passed())
            // git should have already logged an error
            std.process.exit(0x7f);
        break :blk std.mem.trimRight(u8, result.stdout, &std.ascii.whitespace);
    };
    if (sha.len != 40) {
        std.log.err("invalid sha '{s}', expected 40 hex digits but got {}", .{ sha, sha.len });
        std.process.exit(0x7f);
    }
    return sha;
}

const refs_heads = "refs/heads/";

pub fn main() !u8 {
    const args = cmdlineArgs();
    if (args.len == 0) {
        try usage();
        return 0x7f;
    }
    if (args.len != 1) {
        std.log.err("expected 1 cmdline argument but got {}", .{args.len});
        return 0x7f;
    }

    const against_refspec = std.mem.span(args[0]);

    const against_sha = try getSha(against_refspec);
    const refs_stdout = blk: {
        const result = try runutil.runGetStdout(arena, &.{
            "git",
            "for-each-ref",
            "--format=%(refname)",
            refs_heads,
        });
        if (!result.passed())
            // git should have already logged an error
            return 0x7f;
        break :blk std.mem.trimRight(u8, result.stdout, &std.ascii.whitespace);
    };

    {
        var it = std.mem.splitScalar(u8, refs_stdout, '\n');
        while (it.next()) |refs_line| {
            try onRefsLine(against_refspec, against_sha, refs_line);
        }
    }
    return 0;
}

fn onRefsLine(
    against_refspec: []const u8,
    against_sha: []const u8,
    refs_line: []const u8,
) !void {
    const ref = std.mem.trimRight(u8, refs_line, &std.ascii.whitespace);
    if (!std.mem.startsWith(u8, ref, refs_heads)) {
        std.log.err("expected each line of git for-each-ref to start with '{s}' but got '{s}'", .{ refs_heads, ref });
        std.process.exit(0x7f);
    }
    const name = ref[refs_heads.len..];
    if (std.mem.eql(u8, name, against_refspec))
        return;
    const branch_sha = try getSha(ref);
    std.log.debug("{s}: {s}", .{ name, branch_sha });
    const is_ancestor_result = try runutil.runGetStdout(arena, &.{
        "git",
        "merge-base",
        "--is-ancestor",
        ref,
        against_sha,
    });
    if (is_ancestor_result.passed()) {
        try std.io.getStdOut().writer().print("{s}\n", .{name});
    }
}
