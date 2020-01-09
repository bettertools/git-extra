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

    const zogIndexFile = "../../zog/zog.zig";
    std.fs.File.access(zogIndexFile) catch |err| {
        std.debug.warn("Error: zog index file '{}' does not exist\n", .{zogIndexFile});
        std.debug.warn("       have you downloaded the zog library? Run the following to clone it:\n", .{});
        std.debug.warn("       git clone https://github.com/marler8997/zog ../../zog\n", .{});
        return err;
    };
    exe.addPackagePath("zog", zogIndexFile);

    const run_cmd = exe.run();

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    b.default_step.dependOn(&exe.step);
    b.installArtifact(exe);
}
