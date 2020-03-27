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
    log("    git cleanbranches <upstream-branch>", .{});
}

fn help() void {
    usage();
    log(
    \\
    \\Cleans branches that have already been merged into the given
    \\upstream branch.  Note that it will not clean anything before
    \\prompting the user.
    , .{});
}

pub fn main() !u8 {
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
    if (args.len != 1) {
        log("Error: 'git cleanbranches' requires 1 argument but got {}", .{args.len});
        usage();
        return 1;
    }

    const branch = args[0];

    const git = "git";
    std.debug.warn("not impl\n", .{});
    return 1;
}

fn firstLine(str: []const u8) []const u8 {
    return str[0 .. std.mem.indexOfAny(u8, str, "\n\r") orelse str.len];
}
