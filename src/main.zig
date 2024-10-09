const std = @import("std");
const builtin = @import("builtin");
const gba = @import("gba.zig");
const alphabet = @import("alphabet.zig");

pub fn panic(msg: []const u8, error_return_trace: ?*std.builtin.StackTrace, size: ?usize) noreturn {
    @setCold(true);
    if (builtin.mode != .Debug) {
        while (true) {}
    }
    gba.reg_dispcnt.* = .{
        .video_mode = 0,
        .display_bg0 = true,
    };
    gba.copyPalette(.{
        .{},
        .{ .r = 31, .g = 31, .b = 31 },
        .{},
        .{},
        .{},
        .{},
        .{},
        .{},
        .{},
        .{},
        .{},
        .{},
        .{},
        .{},
        .{},
        .{},
    }, &gba.bg_palettes[0]);
    var ascii_tiles: [128]gba.Tile = undefined;
    for (alphabet.letters, 0..) |l, i| {
        ascii_tiles[i] = alphabet.letterToTile(l);
    }
    gba.copyTiles(ascii_tiles[0..], gba.bg_tiles[0..]);
    gba.reg_bg0cnt.map_data = 2;
    for ("PANIC: ", 0..) |l, i| {
        gba.bg_map[2][i] = l;
    }
    for (msg, 7..) |l, i| {
        gba.bg_map[2][i] = l;
    }
    _ = error_return_trace;
    _ = size;
    while (true) {}
}

export fn main() noreturn {
    while (true) {}
}
