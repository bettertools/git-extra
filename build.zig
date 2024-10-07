const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    addTool(b, target, optimize, "git-fetchout.zig");
    addTool(b, target, optimize, "git-merged.zig");
}

fn addTool(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    src: []const u8,
) void {
    const exe = b.addExecutable(.{
        .name = std.fs.path.stem(src),
        .root_source_file = b.path(src),
        .target = target,
        .optimize = optimize,
        .single_threaded = true,
    });
    b.installArtifact(exe);
}
