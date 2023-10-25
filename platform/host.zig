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

const FromRoc = struct {
    format: []const u8,
    data: []const u8,
    path: []const u8,
};

pub fn main() !u8 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const stdout = std.io.getStdOut().writer();
    // const stderr = std.io.getStdErr().writer();

    var timer = std.time.Timer.start() catch unreachable;

    var image_tvg_text = callRoc(RocStr.fromSlice(""));
    defer image_tvg_text.decref();

    // // Parse the TVG text format bytes into a TVG binary format
    var intermediary_tvg = std.ArrayList(u8).init(allocator);
    defer intermediary_tvg.deinit();
    try tvg.text.parse(allocator, image_tvg_text.asSlice(), intermediary_tvg.writer());

    // Render TVG binary format into a framebuffer
    var stream = std.io.fixedBufferStream(intermediary_tvg.items);
    // TODO let the user set these parameters
    const size: tvg.rendering.SizeHint = try getSize();
    var tImage = try tvg.rendering.renderStream(
        allocator,
        allocator,
        size,
        // ^^ Can also specify a size here which improves the quality of the rendering at the cost of speed
        // rendering.SizeHint{ .size = rendering.Size{ .width = (1920 / 2), .height = (1080 / 2) } },
        .x4,
        // ^^ Can specify other anti aliasing modes .x4, .x9, .x16, .x25
        stream.reader(),
    );

    std.debug.print("size {any}", .{size});

    // Convert the framebuffer into a zig image
    var zImage = try zigimg.Image.create(allocator, tImage.width, tImage.height, .rgba32);
    defer zImage.deinit();

    for (tImage.pixels, 0..) |pixel, i| {
        zImage.pixels.rgba32[i].r = pixel.r;
        zImage.pixels.rgba32[i].g = pixel.g;
        zImage.pixels.rgba32[i].b = pixel.b;
        zImage.pixels.rgba32[i].a = pixel.a;
    }

    const pixel_count: usize = tImage.width * tImage.height;

    std.debug.assert(zImage.pixels.len() == pixel_count);

    // std.debug.print("\nallocator: {any}\nwidth: {any}\nheight: {any}\npixels: {any}\nanimation: {any}\n", .{
    //     zImage.allocator,
    //     zImage.width,
    //     zImage.height,
    //     zImage.pixels,
    //     zImage.animation,
    // });

    try zImage.writeToFilePath("zigimg.png", zigimg.Image.EncoderOptions{
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

fn getSize() !tvg.rendering.SizeHint {
    var callresult = RocStr.empty();
    defer callresult.decref();

    var arg = RocStr.fromSlice("SIZE");
    defer arg.decref();

    roc__mainForHost_1_exposed_generic(&callresult, @constCast(&arg));

    var splitIterator = std.mem.splitScalar(u8, callresult.asSlice(), '|');
    const width = splitIterator.next() orelse return .inherit;
    const height = splitIterator.next() orelse return .inherit;

    return .{ .size = .{
        .width = try std.fmt.parseInt(u32, width, 10),
        .height = try std.fmt.parseInt(u32, height, 10),
    } };
}
