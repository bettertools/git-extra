const std = @import("std");
const Builder = std.build.Builder;
const Step = std.build.Step;
const CrossTarget = std.zig.CrossTarget;
const Mode = std.builtin.Mode;

const GitRepoStep = @import("GitRepoStep.zig");

pub fn build(b: *Builder) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    addTool(b, target, optimize, "git-fetchout.zig");
    addTool(b, target, optimize, "git-merged.zig");
}

fn addTool(
    b: *Builder,
    target: CrossTarget,
    optimize: Mode,
    src: []const u8,
) void {
    const exe = b.addExecutable(.{
        .name = std.fs.path.stem(src),
        .root_source_file = .{ .path = src },
        .target = target,
        .optimize = optimize,
        .single_threaded = true,
    });
    b.installArtifact(exe);
}
