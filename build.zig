const std = @import("std");
const Builder = std.build.Builder;
const Step = std.build.Step;
const CrossTarget = std.zig.CrossTarget;
const Mode = std.builtin.Mode;

const GitRepoStep = @import("GitRepoStep.zig");

pub fn build(b: *Builder) !void {
    const zog_repo = GitRepoStep.create(b, .{
        .url = "https://github.com/marler8997/zog",
        .branch = null,
        .sha = @embedFile("zogsha"),
    });

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    addTool(b, target, optimize, zog_repo, "git-fetchout.zig");
    addTool(b, target, optimize, null, "git-merged.zig");
}

fn addTool(
    b: *Builder,
    target: CrossTarget,
    optimize: Mode,
    zog_repo_opt: ?*GitRepoStep,
    src: []const u8,
) void {
    const exe = b.addExecutable(.{
        .name = std.fs.path.stem(src),
        .root_source_file = .{ .path = src },
        .target = target,
        .optimize = optimize,
        .single_threaded = true,
    });
    if (zog_repo_opt) |zog_repo| {
        exe.step.dependOn(&zog_repo.step);
        const zog_mod = b.createModule(.{
            .source_file = .{ .path = b.pathJoin(&.{zog_repo.getPath(&exe.step), "zog.zig"}) },
        });
        exe.addModule("zog", zog_mod);
    }
    b.installArtifact(exe);
}
