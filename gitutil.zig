const std = @import("std");

const zog = @import("zog");
const cmdlinetool = zog.cmdlinetool;

const GitShowInfo = struct {
    sha : []const u8,
};

pub fn parseGitShow(output: []const u8) !GitShowInfo {
    const CommitPrefix = "commit ";
    if (!std.mem.startsWith(u8, output, CommitPrefix)) {
        cmdlinetool.log("Error: expected `git show` output to start with \"{s}\" but it didn't:", .{CommitPrefix});
        return cmdlinetool.ErrorReported;
    }
    var sha = output[CommitPrefix.len..];

    const shaEnd = std.mem.indexOfAny(u8, sha, "\r\n");
    if (shaEnd == null) {
        cmdlinetool.log("Error: expected `git show` output to contain newline after commit but none was found:", .{});
        cmdlinetool.log("{s}", .{output});
        return cmdlinetool.ErrorReported;
    } else {
        return GitShowInfo { .sha = sha[0 .. shaEnd.?], };
    }
}
