const std = @import("std");
const pin = @import("pin.zig");
const lcd = @import("lcd.zig");

const c = @cImport({
    @cInclude("stdio.h");
    @cInclude("string.h");
    @cInclude("pico/stdlib.h");
    @cInclude("pico/runtime_init.h");
    @cInclude("hardware/i2c.h");
    @cInclude("pico/binary_info.h");
});

export fn _init() void {
    c.runtime_init_clocks();
    c.runtime_init_early_resets();
    c.runtime_init_spin_locks_reset();
    _ = c.stdio_init_all();
}

export fn main() void {
    _init();
    const l = lcd.init(4, 5);

    while (true) {
        const messages = [_][]const u8{
            "Hello World",
        };

        for (messages) |message| {
            l.lcd_string(@constCast(message));
        }
    }
}

// // FIX ME: probably a hack and will break
export fn _fini() void {}
