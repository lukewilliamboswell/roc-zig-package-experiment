const std = @import("std");
const builtin = @import("builtin");
const list = @import("list.zig");
const str = @import("str.zig");
const tvg = @import("tinyvg");
const zigimg = @import("zigimg");
const RocList = list.RocList;
const RocStr = str.RocStr;
const testing = std.testing;
const expectEqual = testing.expectEqual;
const expect = testing.expect;
const Align = 2 * @alignOf(usize);
const DEBUG: bool = false;

extern fn malloc(size: usize) callconv(.C) ?*align(Align) anyopaque;
extern fn realloc(c_ptr: [*]align(Align) u8, size: usize) callconv(.C) ?*anyopaque;
extern fn free(c_ptr: [*]align(Align) u8) callconv(.C) void;
extern fn memcpy(dst: [*]u8, src: [*]u8, size: usize) callconv(.C) void;
extern fn memset(dst: [*]u8, value: i32, size: usize) callconv(.C) void;

export fn roc_alloc(size: usize, alignment: u32) callconv(.C) ?*anyopaque {
    if (DEBUG) {
        var ptr = malloc(size);
        const stdout = std.io.getStdOut().writer();
        stdout.print("alloc:   {d} (alignment {d}, size {d})\n", .{ ptr, alignment, size }) catch unreachable;
        return ptr;
    } else {
        return malloc(size);
    }
}

export fn roc_realloc(c_ptr: *anyopaque, new_size: usize, old_size: usize, alignment: u32) callconv(.C) ?*anyopaque {
    if (DEBUG) {
        const stdout = std.io.getStdOut().writer();
        stdout.print("realloc: {d} (alignment {d}, old_size {d})\n", .{ c_ptr, alignment, old_size }) catch unreachable;
    }

    return realloc(@as([*]align(Align) u8, @alignCast(@ptrCast(c_ptr))), new_size);
}

export fn roc_dealloc(c_ptr: *anyopaque, alignment: u32) callconv(.C) void {
    if (DEBUG) {
        const stdout = std.io.getStdOut().writer();
        stdout.print("dealloc: {d} (alignment {d})\n", .{ c_ptr, alignment }) catch unreachable;
    }

    free(@as([*]align(Align) u8, @alignCast(@ptrCast(c_ptr))));
}

export fn roc_panic(msg: *RocStr, tag_id: u32) callconv(.C) void {
    const stderr = std.io.getStdErr().writer();
    // const msg = @as([*:0]const u8, @ptrCast(c_ptr));
    stderr.print("\n\nRoc crashed with the following error;\nMSG:{s}\nTAG:{d}\n\nShutting down\n", .{ msg.asSlice(), tag_id }) catch unreachable;
    std.process.exit(0);
}

export fn roc_memset(dst: [*]u8, value: i32, size: usize) callconv(.C) void {
    return memset(dst, value, size);
}

extern fn kill(pid: c_int, sig: c_int) c_int;
extern fn shm_open(name: *const i8, oflag: c_int, mode: c_uint) c_int;
extern fn mmap(addr: ?*anyopaque, length: c_uint, prot: c_int, flags: c_int, fd: c_int, offset: c_uint) *anyopaque;
extern fn getppid() c_int;

fn roc_getppid() callconv(.C) c_int {
    return getppid();
}

fn roc_getppid_windows_stub() callconv(.C) c_int {
    return 0;
}

fn roc_shm_open(name: *const i8, oflag: c_int, mode: c_uint) callconv(.C) c_int {
    return shm_open(name, oflag, mode);
}
fn roc_mmap(addr: ?*anyopaque, length: c_uint, prot: c_int, flags: c_int, fd: c_int, offset: c_uint) callconv(.C) *anyopaque {
    return mmap(addr, length, prot, flags, fd, offset);
}

comptime {
    if (builtin.os.tag == .macos or builtin.os.tag == .linux) {
        @export(roc_getppid, .{ .name = "roc_getppid", .linkage = .Strong });
        @export(roc_mmap, .{ .name = "roc_mmap", .linkage = .Strong });
        @export(roc_shm_open, .{ .name = "roc_shm_open", .linkage = .Strong });
    }

    if (builtin.os.tag == .windows) {
        @export(roc_getppid_windows_stub, .{ .name = "roc_getppid", .linkage = .Strong });
    }
}

const mem = std.mem;
const Allocator = mem.Allocator;

extern fn roc__mainForHost_1_exposed_generic(*RocStr, *RocStr) void;

pub fn main() !u8 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const stdout = std.io.getStdOut().writer();
    // const stderr = std.io.getStdErr().writer();

    // Start the timer
    var timer = std.time.Timer.start() catch unreachable;

    // Get the TVG text format from Roc
    var tvg_text_from_roc = callRoc(RocStr.fromSlice(""));
    defer tvg_text_from_roc.decref();

    // Parse the TVG text format bytes into a TVG binary format
    var intermediary_tvg = std.ArrayList(u8).init(allocator);
    defer intermediary_tvg.deinit();
    try tvg.text.parse(allocator, tvg_text_from_roc.asSlice(), intermediary_tvg.writer());

    // Get the size of the image from Roc
    var size_from_roc: RocStr = callRoc(RocStr.fromSlice("SIZE"));
    defer size_from_roc.decref();
    const size: tvg.rendering.SizeHint = try sizeFromRocStr(size_from_roc);

    // Get the anti aliasing for the image from Roc
    var alias_from_roc: RocStr = callRoc(RocStr.fromSlice("ALIAS"));
    defer alias_from_roc.decref();
    const anit_alias: tvg.rendering.AntiAliasing = try aliasFromRocStr(alias_from_roc);

    // Render TVG binary format into a framebuffer
    var stream = std.io.fixedBufferStream(intermediary_tvg.items);
    var tImage = try tvg.rendering.renderStream(
        allocator,
        allocator,
        size,
        anit_alias,
        stream.reader(),
    );

    // Convert the framebuffer into a zig image
    var zImage = try zigimg.Image.create(allocator, tImage.width, tImage.height, .rgba32);
    defer zImage.deinit();

    for (tImage.pixels, 0..) |pixel, i| {
        zImage.pixels.rgba32[i].r = pixel.r;
        zImage.pixels.rgba32[i].g = pixel.g;
        zImage.pixels.rgba32[i].b = pixel.b;
        zImage.pixels.rgba32[i].a = pixel.a;
    }

    // Get the title for the image from Roc
    var title_from_roc: RocStr = callRoc(RocStr.fromSlice("TITLE"));
    defer title_from_roc.decref();

    const title = try std.fmt.allocPrint(allocator, "{s}.png", .{title_from_roc.asSlice()});
    try zImage.writeToFilePath(title, zigimg.Image.EncoderOptions{
        .png = .{},
    });

    // Time taken
    const finish = timer.read();
    stdout.print("Total time {d:.3}ms\n", .{finish / std.time.ns_per_ms}) catch unreachable;

    return 0;
}

fn callRoc(arg: RocStr) RocStr {
    var callresult = RocStr.empty();
    roc__mainForHost_1_exposed_generic(&callresult, @constCast(&arg));
    arg.decref();

    return callresult;
}

// Try to parse width and height, or use default .inherit
fn sizeFromRocStr(sizeStr: RocStr) !tvg.rendering.SizeHint {
    var splitIterator = std.mem.splitScalar(u8, sizeStr.asSlice(), '|');

    const width = splitIterator.next() orelse return .inherit;
    const height = splitIterator.next() orelse return .inherit;

    return .{ .size = .{
        .width = try std.fmt.parseInt(u32, width, 10),
        .height = try std.fmt.parseInt(u32, height, 10),
    } };
}

// Try to parse anti aliasing, or use default .x4
fn aliasFromRocStr(aliasStr: RocStr) !tvg.rendering.AntiAliasing {
    const bytes = aliasStr.asSlice();

    if (std.mem.eql(u8, bytes, "X1")) {
        return .x1;
    }

    if (std.mem.eql(u8, bytes, "X4")) {
        return .x4;
    }

    if (std.mem.eql(u8, bytes, "X9")) {
        return .x9;
    }

    if (std.mem.eql(u8, bytes, "X16")) {
        return .x16;
    }

    if (std.mem.eql(u8, bytes, "X25")) {
        return .x25;
    }

    return .x4;
}
