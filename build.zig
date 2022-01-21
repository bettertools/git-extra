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
    const mode = b.standardReleaseOptions();
    const run_step = b.step("run", "Run the app");

    addTool(b, run_step, target, mode, zog_repo, "git-fetchout", "git-fetchout.zig");
}

fn addTool(
    b: *Builder,
    run_step: *Step,
    target: CrossTarget,
    mode: Mode,
    zog_repo: *GitRepoStep,
    name: []const u8,
    src: []const u8,
) void {

    const exe = b.addExecutable(name, src);
    exe.single_threaded = true;
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.step.dependOn(&zog_repo.step);
    exe.addPackagePath("zog", b.pathJoin(&.{zog_repo.getPath(&exe.step), "zog.zig"}));
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());

    run_step.dependOn(&run_cmd.step);
}
