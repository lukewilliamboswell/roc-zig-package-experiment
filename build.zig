const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const tvg_dep = b.dependency("tvg", .{
        .target = target,
        .optimize = optimize,
    }).module("tvg");

    const zig_img_dep = b.dependency("zig_img", .{
        .target = target,
        .optimize = optimize,
    }).module("zigimg");

    const obj = b.addObject(.{
        .name = "graphics",
        .root_source_file = .{ .path = "platform/host.zig" },
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    obj.force_pic = true;
    obj.disable_stack_probing = true;

    obj.addModule("tinyvg", tvg_dep);
    obj.addModule("zigimg", zig_img_dep);

    const install_obj = b.addInstallFile(obj.getEmittedBin(), "host.o");
    b.default_step.dependOn(&install_obj.step);

    if (target.os_tag == .linux) {
        const exe = b.addExecutable(.{
            .name = "dynhost",
            .root_source_file = .{ .path = "platform/host.zig" },
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        });
        exe.pie = true;
        exe.disable_stack_probing = true;
        exe.addLibraryPath(.{ .path = "platform/" });
        exe.linkSystemLibraryNeededName("app");

        exe.addModule("tinyvg", tvg_dep);
        exe.addModule("zigimg", zig_img_dep);

        b.installArtifact(exe);
    }
}
