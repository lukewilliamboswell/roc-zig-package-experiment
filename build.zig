const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const tvg_dep = b.dependency("tvg", .{
        .target = target,
        .optimize = optimize,
    });

    const zig_img_dep = b.dependency("zig_img", .{
        .target = target,
        .optimize = optimize,
    }).module("zigimg");

    const lib = b.addStaticLibrary(.{
        .name = "basic-graphics",
        .root_source_file = .{ .path = "platform/host.zig" },
        .target = target,
        .optimize = optimize,
    });

    lib.addModule("tinyvg", tvg_dep.module("tvg"));
    lib.addModule("zigimg", zig_img_dep);

    lib.linkLibC();
    lib.linkSystemLibrary("System");

    lib.linkFramework("Foundation");
    lib.linkFramework("CoreServices");
    lib.linkFramework("CoreGraphics");
    lib.linkFramework("AppKit");
    lib.linkFramework("IOKit");

    // lib.addIncludePath(.{ .path = "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX14.0.sdk" });

    // const install_lib = b.addInstallArtifact(lib, .{
    //     .dest_dir = ""
    // });

    // b.getInstallStep().dependOn(&install_lib.step);

    b.installArtifact(lib);
}
