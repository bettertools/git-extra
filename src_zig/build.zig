const std = @import("std");
const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) !void {
    const mode = b.standardReleaseOptions();
    const exe = b.addExecutable("git-fetchout", "git-fetchout.zig");
    exe.setBuildMode(mode);
    std.fs.makeDir("out") catch |err| switch(err) {
        error.PathAlreadyExists => { },
        else => return err,
    };
    exe.single_threaded = true;
    exe.setOutputDir("out");

    const run_cmd = exe.run();

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    b.default_step.dependOn(&exe.step);
    b.installArtifact(exe);
}
