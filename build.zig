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

    const lib = b.addStaticLibrary(.{
        .name = "graphics",
        .root_source_file = .{ .path = "platform/host.zig" },
        .target = target,
        .optimize = optimize,
    });

    lib.addModule("tinyvg", tvg_dep);
    lib.addModule("zigimg", zig_img_dep);

    b.installArtifact(lib);
}
