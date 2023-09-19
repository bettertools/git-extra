const builtin = @import("builtin");
const std = @import("std");

const zog = @import("zog");
const runutil = zog.runutil;

const cmdlinetool = zog.cmdlinetool;
const log = cmdlinetool.log;
const ErrorReported = cmdlinetool.ErrorReported;

const gitutil = @import("./gitutil.zig");

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const allocator = arena.allocator();

fn usage() void {
    log(
        \\Usage:
        \\ git fetchout <repo> <branch>
        \\
        , .{}
    );
}

fn help() void {
    usage();
    log(
    \\
    \\This command fetches a remote branch and checks it out.
    \\If a local branch with the same name already exists, it will
    \\prompt the user to overwrite the local branch.
    , .{});
    //writeln("Note: this is equivalent to:");
    //writeln("    1. git fetch <repo> <branch>");
    //writeln("    2. git checkout FETCH_HEAD");
    //writeln("    3. git branch -D <branch>");
    //writeln("    4. git checkout -b <branch>");
}

const LocalError = error {
    ProcessExitedWithErrorCode,
    ProcessFailed,
};

// make sure sha's are all 40-character hex strings so they can be compared
fn enforceSha(name: []const u8, val: []const u8) void {
    if (val.len != 40) {
        log("Error: {s} '{s}' is not a 40 character hex SHA", .{name, val});
        std.os.exit(0xff);
    }
}

pub fn main() u8 {
    return main2() catch |err| {
        if (err == ErrorReported) {
            return 1;
        }
        std.debug.print("error: {s}\n", .{@errorName(err)});
        return 1;
    };
}
fn main2() !u8 {
    const args_with_exe = try std.process.argsAlloc(allocator);
    if (args_with_exe.len <= 1) {
        help();
        return 1; // error exit code
    }

    const args = blk: {
        var args_len: usize = 0;
        const args_no_exe = args_with_exe[1..];
        var i : usize = 0;
        while (i < args_no_exe.len) : (i += 1) {
            const arg = args_no_exe[i];
            //log("parsing arg '{s}'", arg);
            if (!std.mem.startsWith(u8, arg, "-")) {
                args_no_exe[args_len] = arg;
                args_len += 1;
            //} else if (arg == "-r" || arg == "--repo") {
            //    repo = getOptionArg(args, &i);
            } else {
                log("Error: unknown option '{s}'", .{arg});
                return 1;
            }
        }
        break :blk args_no_exe[0 .. args_len];
    };

    if (args.len != 2) {
        log("Error: 'git fetchout' requires 2 arguments but got {}", .{args.len});
        usage();
        return 1;
    }

    const repo = args[0];
    const branch = args[1];

    const git = "git";

    const git_show_format = "--format=commit %H%nCommitter Date: %cd%n%n%s%n%n%b";

    // check if local branch exists and if it is updated
    const gitShowLocalOutput : []u8 = blk: {
        // NOTE the '--' is to let git know it's a revision, not a filename
        const result = try cmdlinetool.runGetOutput(allocator, .{
            git, "show", "--no-patch", git_show_format, branch, "--"
        });
        if (runutil.runFailed(&result)) {
            log("    local branch '{s}' does not exist", .{branch});
            const branchArg = try std.fmt.allocPrint(allocator, "{s}:{0s}", .{branch});
            try cmdlinetool.enforceRunPassed(try cmdlinetool.run(allocator, .{git, "fetch", repo, branchArg}));
            try cmdlinetool.enforceRunPassed(try cmdlinetool.run(allocator, .{git, "checkout", branch}));

            // NOTE the '--' is to let git know it's a revision, not a filename
            try cmdlinetool.enforceRunPassed(try cmdlinetool.run(allocator, .{
                git, "--no-pager", "show", "--no-patch", git_show_format, "HEAD", "--"
            }));
            return 0;
        }
        break :blk try runutil.runCombineOutput(allocator, &result);
    };

    const localBranchInfo = try gitutil.parseGitShow(gitShowLocalOutput);
    enforceSha("local branch", localBranchInfo.sha);
    log("    local branch: {s}", .{localBranchInfo.sha});

    try cmdlinetool.enforceRunPassed(try cmdlinetool.run(allocator, .{git, "fetch", repo, branch}));

    // NOTE the '--' is to let git know it's a revision, not a filename
    const gitShowFetchHead = try cmdlinetool.enforceRunGetOutputPassed(
        allocator,
        try cmdlinetool.runGetOutput(allocator, .{
            git, "show", "--no-patch", git_show_format, "FETCH_HEAD", "--"
        }),
    );
    const fetchHeadInfo = try gitutil.parseGitShow(gitShowFetchHead);
    enforceSha("remote branch", fetchHeadInfo.sha);
    log("    remote branch: {s}", .{fetchHeadInfo.sha});

    if (std.mem.eql(u8, localBranchInfo.sha, fetchHeadInfo.sha)) {
        log("local branch is already up-to-date", .{});
        try cmdlinetool.enforceRunPassed(try cmdlinetool.run(allocator, .{git, "checkout", branch}));
        return 0;
    }

    // check if local branch will be overwritten or if it's just an update
    const merge_base_raw = try cmdlinetool.enforceRunGetOutputPassed(allocator,
        try cmdlinetool.runGetOutputArray(allocator, &[_][]const u8{git, "merge-base", branch, "FETCH_HEAD"}));
    const merge_base = std.mem.trimRight(u8, merge_base_raw, "\r\n");
    enforceSha("merge base", merge_base);

    const is_normal_update = std.mem.eql(u8, merge_base, localBranchInfo.sha);
    if (is_normal_update) {
        log("remote branch is a normal update, no need to prompt user", .{});
    } else {
        log("================================================================================", .{});
        log("LOCAL_BRANCH", .{});
        log("================================================================================", .{});
        log("{s}", .{gitShowLocalOutput});
        log("================================================================================", .{});
        log("REMOTE_BRANCH", .{});
        log("================================================================================", .{});
        log("{s}", .{gitShowFetchHead});
        log("--------------------------------------------------------------------------------", .{});

        const yes = try promptYesNo("Overwrite LOCAL_BRANCH with REMOTE_BRANCH");
        if (!yes) {
            return 0xff;
        }
    }
    try cmdlinetool.enforceRunPassed(try cmdlinetool.run(allocator, .{git, "checkout", "FETCH_HEAD"}));
    try cmdlinetool.enforceRunPassed(try cmdlinetool.run(allocator, .{git, "--no-pager", "branch", "-D", branch}));
    try cmdlinetool.enforceRunPassed(try cmdlinetool.run(allocator, .{git, "checkout", "-b", branch}));

    if (is_normal_update) {
        log("Succesfully updated from {s} to {s}", .{localBranchInfo.sha, fetchHeadInfo.sha});
    } else {
        log("Succesfully overwrote local branch {s} with {s}", .{localBranchInfo.sha, fetchHeadInfo.sha});
    }

    return 0;
}

fn promptYesNo(prompt: []const u8) !bool {
    var answer = std.ArrayList(u8).init(allocator);
    defer answer.deinit();
    while (true) {
        std.debug.print("{s}[y/n]? ", .{prompt});
        //const answer = try std.io.readLine(&buffer);
        answer.resize(0) catch @panic("codebug");
        std.io.getStdIn().reader().readUntilDelimiterArrayList(&answer, '\n', 20) catch |e| switch (e) {
            error.StreamTooLong => continue,
            else => return e
        };
        if (std.mem.startsWith(u8, answer.items, "y")) return true;
        if (std.mem.startsWith(u8, answer.items, "n")) return false;
    }
}

fn firstLine(str: []const u8) []const u8 {
    return str[0 .. std.mem.indexOfAny(u8, str, "\n\r") orelse str.len];
}
