const builtin = @import("builtin");
const std = @import("std");

const zog = @import("zog");
const varargs = zog.varargs;
const appendlib = zog.appendlib;
const runutil = zog.runutil;
usingnamespace zog.cmdlinetool;

const gitutil = @import("./gitutil.zig");


var arena = std.heap.ArenaAllocator.init(std.heap.direct_allocator);
const allocator = &arena.allocator;

fn usage() void {
    log("Usage:", .{});
    log("    git fetchout <repo> <branch>", .{});
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

pub fn main() u8 {
    return main2() catch |err| {
        if (err == ErrorReported) {
            return 1;
        }
        std.debug.warn("error: {}\n", .{@errorName(err)});
        return 1;
    };
}
fn main2() !u8 {
    var args = try std.process.argsAlloc(allocator);
    if (args.len <= 1) {
        help();
        return 1; // error exit code
    }
    args = args[1..];

    {
        var newArgsLength : usize = 0;
        defer args.len = newArgsLength;
        var i : usize = 0;
        while (i < args.len) : (i += 1) {
            var arg = args[i];
            //log("parsing arg '{}'", arg);
            if (!std.mem.startsWith(u8, arg, "-")) {
                args[newArgsLength] = arg;
                newArgsLength += 1;
            //} else if (arg == "-r" || arg == "--repo") {
            //    repo = getOptionArg(args, &i);
            } else {
                log("Error: unknown option '{}'", .{arg});
                return 1;
            }
        }
    }
    if (args.len != 2) {
        log("Error: 'git fetchout' requires 2 arguments but got {}", .{args.len});
        usage();
        return 1;
    }

    const repo = args[0];
    const branch = args[1];

    const git = "git";

    // check if local branch exists and if it is updated
    var gitShowLocalOutput : []u8 = undefined;
    {
        // NOTE the '--' is to let git know it's a revision, not a filename
        const result = try runGetOutput(allocator, .{git, "show", "-s", branch, "--"});
        if (runutil.runFailed(&result)) {
            log("    local branch '{}' does not exist", .{branch});
            const branchArg = try std.fmt.allocPrint(allocator, "{}:{}", .{branch, branch});
            try enforceRunPassed(try run(allocator, .{git, "fetch", repo, branchArg}));
            try enforceRunPassed(try run(allocator, .{git, "checkout", branch}));

            // NOTE the '--' is to let git know it's a revision, not a filename
            try enforceRunPassed(try run(allocator, .{git, "--no-pager", "show", "-s", "HEAD", "--"}));
            return 0;
        }
        gitShowLocalOutput = try runutil.runCombineOutput(allocator, &result);
    }

    const localBranchInfo = try gitutil.parseGitShow(gitShowLocalOutput);
    log("    local branch: {}", .{localBranchInfo.sha});

    try enforceRunPassed(try run(allocator, .{git, "fetch", repo, branch}));

    // NOTE the '--' is to let git know it's a revision, not a filename
    const gitShowFetchHead = try enforceRunGetOutputPassed(allocator,
        try runGetOutput(allocator, .{git, "show", "-s", "FETCH_HEAD", "--"}));
    const fetchHeadInfo = try gitutil.parseGitShow(gitShowFetchHead);
    log("    remote branch: {}", .{fetchHeadInfo.sha});

    if (std.mem.eql(u8, localBranchInfo.sha, fetchHeadInfo.sha)) {
        log("local branch is already up-to-date", .{});
        try enforceRunPassed(try run(allocator, .{git, "checkout", branch}));
        return 0;
    }

    log("================================================================================", .{});
    log("LOCAL_BRANCH", .{});
    log("================================================================================", .{});
    log("{}", .{gitShowLocalOutput});
    log("================================================================================", .{});
    log("REMOTE_BRANCH", .{});
    log("================================================================================", .{});
    log("{}", .{gitShowFetchHead});
    log("--------------------------------------------------------------------------------", .{});

    const result = try promptYesNo("Overwrite LOCAL_BRANCH with REMOTE_BRANCH");
    if (result) {
        try enforceRunPassed(try run(allocator, .{git, "checkout", "FETCH_HEAD"}));
        try enforceRunPassed(try run(allocator, .{git, "--no-pager", "branch", "-D", branch}));
        try enforceRunPassed(try run(allocator, .{git, "checkout", "-b", branch}));
    }
    return 0;
}

fn promptYesNo(prompt: []const u8) !bool {
    var answer = std.ArrayList(u8).init(allocator);
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

fn firstLine(str: []const u8) []const u8 {
    return str[0 .. std.mem.indexOfAny(u8, str, "\n\r") orelse str.len];
}
