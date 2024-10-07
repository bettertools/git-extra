const std = @import("std");

const cmdlinetool = @import("cmdlinetool.zig");

const GitShowInfo = struct {
    sha : []const u8,
};

pub fn parseGitShow(output: []const u8) !GitShowInfo {
    const CommitPrefix = "commit ";
    if (!std.mem.startsWith(u8, output, CommitPrefix)) {
        std.log.err("expected `git show` output to start with \"{s}\" but it didn't:", .{CommitPrefix});
        return error.AlreadyReported;
    }
    var sha = output[CommitPrefix.len..];

    const shaEnd = std.mem.indexOfAny(u8, sha, "\r\n");
    if (shaEnd == null) {
        std.log.err("expected `git show` output to contain newline after commit but none was found:", .{});
        try std.io.getStdErr().writer().writeAll(output);
        return error.AlreadyReported;
    } else {
        return GitShowInfo { .sha = sha[0 .. shaEnd.?], };
    }
}
