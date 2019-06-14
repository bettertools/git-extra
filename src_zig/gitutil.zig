const std = @import("std");

const cmdlinetool = @import("./cmdlinetool.zig");

const GitShowInfo = struct {
    sha : []u8,
};

pub fn parseGitShow(output: []u8) !GitShowInfo {
    const CommitPrefix = "commit ";
    if (!std.mem.startsWith(u8, output, CommitPrefix)) {
        cmdlinetool.log("Error: expected `git show` output to start with \"{}\" but it didn't:", CommitPrefix);
        return cmdlinetool.ErrorReported;
    }
    var sha = output[CommitPrefix.len..];

    const shaEnd = std.mem.indexOfAny(u8, sha, "\r\n");
    if (shaEnd == null) {
        cmdlinetool.log("Error: expected `git show` output to contain newline after commit but none was found:");
        cmdlinetool.log("{}", output);
        return cmdlinetool.ErrorReported;
    } else {
        return GitShowInfo { .sha = sha[0 .. shaEnd.?], };
    }
}
