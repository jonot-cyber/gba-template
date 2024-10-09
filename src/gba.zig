pub const reg_dispcnt: *volatile DispCnt = @ptrFromInt(0x04000000);
pub const reg_bg0cnt: *volatile BgCnt = @ptrFromInt(0x04000008);
pub const reg_bg1cnt: *volatile BgCnt = @ptrFromInt(0x0400000a);
pub const reg_bg2cnt: *volatile BgCnt = @ptrFromInt(0x0400000c);
pub const reg_bg3cnt: *volatile BgCnt = @ptrFromInt(0x0400000e);
pub const reg_vcount: *volatile u16 = @ptrFromInt(0x04000006);
pub const reg_keyinput: *volatile Keys = @ptrFromInt(0x04000130);

pub const Color = packed struct {
    r: u5 = 0,
    g: u5 = 0,
    b: u5 = 0,
    _: u1 = 0,
};

pub const Palette = [16]Color;

pub const Tile = [8]u32;

pub const ScreenBlock = [1024]u16;

const ObjMode = enum(u2) {
    normal = 0,
    semi_transparent = 1,
    window = 2,
    prohibited = 3,
};

const ObjShape = enum(u2) {
    square = 0,
    horizontal = 1,
    vertical = 2,
    prohibited = 3,
};

const ObjSize = enum(u2) {
    size8 = 0,
    size16 = 1,
    size32 = 2,
    size64 = 3,
};

const ColorMode = enum(u1) {
    color16 = 0,
    color256 = 1,
};

pub const OBJ = packed struct {
    y: u8 = 0,
    rot_scale: bool = false,
    hidden: bool = false,
    mode: ObjMode = .normal,
    mosaic: bool = false,
    color_mode: ColorMode = .color16,
    shape: ObjShape = .square,

    x: u9 = 0,
    _unused: u3 = undefined,
    h_flip: bool = false,
    v_flip: bool = false,
    size: ObjSize = .size8,

    tile_number: u10 = 0,
    priority: u2 = 0,
    palette_number: u4 = 0,
    _empty: u16 = undefined,
};

pub const VramOBJ = packed struct {
    attr0: u16,
    attr1: u16,
    attr2: u16,
    _empty: u16,

    pub fn set(self: *VramOBJ, obj: OBJ) void {
        const tmp: VramOBJ = @bitCast(obj);
        self.attr0 = tmp.attr0;
        self.attr1 = tmp.attr1;
        self.attr2 = tmp.attr2;
    }

    pub fn hide(self: *VramOBJ) void {
        self.attr0 ^= 0x0200;
    }
};

pub const bg_palettes: [*]Palette = @ptrFromInt(0x05000000);
pub const obj_palettes: [*]Palette = @ptrFromInt(0x05000200);
pub const bg_tiles: [*]Tile = @ptrFromInt(0x06000000);
pub const obj_tiles: [*]Tile = @ptrFromInt(0x06010000);
pub const bg_map: [*]ScreenBlock = @ptrFromInt(0x06000000);
pub const objs: [*]VramOBJ = @ptrFromInt(0x07000000);

pub const screen_height = 160;
pub const screen_width = 240;

pub fn copyPalette(src: Palette, dst: *Palette) void {
    for (src, 0..) |c, i| {
        dst[i] = c;
    }
}

pub fn copyTiles(src: []Tile, dst: [*]Tile) void {
    for (src, 0..) |t, i| {
        for (t, 0..) |d, j| {
            dst[i][j] = d;
        }
    }
}

const BgScreenSize = enum(u2) {
    size256x256 = 0,
    size512x256 = 1,
    size256x512 = 2,
    size512x512 = 3,
};

pub const BgCnt = packed struct {
    priority: u2 = 0,
    tile_data: u2 = 0,
    _reserved: u2 = 0,
    mosaic: bool = false,
    color_mode: ColorMode = .color16,
    map_data: u5 = 0,
    overflow: bool = false,
    screen_size: BgScreenSize = .size256x256,
};

pub const DispCnt = packed struct {
    video_mode: u3 = 0,
    _reserved: bool = false,
    frame: u1 = 0,
    hblank_interval_free: bool = false,
    character1d: bool = false,
    forced_blank: bool = false,
    display_bg0: bool = false,
    display_bg1: bool = false,
    display_bg2: bool = false,
    display_bg3: bool = false,
    display_obj: bool = false,
    window0: bool = false,
    window1: bool = false,
    obj_window: bool = false,
};

pub fn hBlankWait() void {
    while (reg_vcount.* >= 160) {}
    while (reg_vcount.* < 160) {}
}

pub const Keys = packed struct {
    a: bool = true,
    b: bool = true,
    select: bool = true,
    start: bool = true,
    right: bool = true,
    left: bool = true,
    up: bool = true,
    down: bool = true,
    r: bool = true,
    l: bool = true,
    _: u6 = undefined,

    pub fn justPressed(self: *const Keys, last: Keys) Keys {
        const self_as_uint: u16 = @bitCast(self.*);
        const last_as_uint: u16 = @bitCast(last);

        const res = ~(self_as_uint ^ last_as_uint) | self_as_uint;
        return @bitCast(res);
    }

    pub fn justReleased(self: *const Keys, last: Keys) Keys {
        const self_as_uint: u16 = @bitCast(self.*);
        const last_as_uint: u16 = @bitCast(last);

        const res = ~((self_as_uint ^ last_as_uint) & self_as_uint);
        return @bitCast(res);
    }
};
