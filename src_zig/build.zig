const std = @import("std");
const Builder = std.build.Builder;
const Step = std.build.Step;
const CrossTarget = std.zig.CrossTarget;
const Mode = std.builtin.Mode;

pub fn build(b: *Builder) !void {
    const zogIndexFile = join(&[_][]const u8 {"..", "..", "zog", "zog.zig"}, std.fs.path.sep);

    std.fs.cwd().access(&zogIndexFile, std.fs.File.OpenFlags { .read = true }) catch |err| {
        std.debug.warn("Error: zog index file '{}' does not exist\n", .{zogIndexFile});
        std.debug.warn("       have you downloaded the zog library? Run the following to clone it:\n", .{});
        std.debug.warn("       git clone https://github.com/marler8997/zog ../../zog\n", .{});
        return err;
    };

    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();
    const run_step = b.step("run", "Run the app");

    addTool(b, run_step, target, mode, &zogIndexFile, "git-fetchout", "git-fetchout.zig");
}

pub fn joinLen(comptime parts: [][]const u8) usize {
    var total : usize = 0;
    for (parts) |part| {
        if (total > 0) { total += 1; }
        total += part.len;
    }
    return total;
}
// TODO: I want something like this from the standard library
pub fn join(comptime parts: [][]const u8, comptime sep: u8) [joinLen(parts) :0]u8 {
    comptime const totalLen = joinLen(parts);
    var path : [totalLen :0]u8 = undefined;
    var offset : usize = 0;
    inline for (parts) |part| {
        if (offset > 0) {
            path[offset] = sep;
            offset += 1;
        }
        std.mem.copy(u8, path[offset..], part);
        offset += part.len;
    }
    if (offset != totalLen) @panic("codebug");
    if (path[totalLen] != 0) @panic("codebug");
    return path;
}

fn addTool(b: *Builder, run_step: *Step, target: CrossTarget, mode: Mode,
    zogIndexFile: []const u8, name: []const u8, src: []const u8) void {

    const exe = b.addExecutable(name, src);
    exe.single_threaded = true;
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.addPackagePath("zog", zogIndexFile);
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());

    run_step.dependOn(&run_cmd.step);
}
