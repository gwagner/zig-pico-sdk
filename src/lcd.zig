const std = @import("std");
const pin = @import("pin.zig");

const c = @cImport({
    @cInclude("stdio.h");
    @cInclude("string.h");
    @cInclude("pico/stdlib.h");
    @cInclude("pico/runtime_init.h");
    @cInclude("hardware/i2c.h");
    @cInclude("pico/binary_info.h");
});

const Self = @This();

// commands
const LCD_CLEARDISPLAY = 0x01;
const LCD_RETURNHOME = 0x02;
const LCD_ENTRYMODESET = 0x04;
const LCD_DISPLAYCONTROL = 0x08;
const LCD_CURSORSHIFT = 0x10;
const LCD_FUNCTIONSET = 0x20;
const LCD_SETCGRAMADDR = 0x40;
const LCD_SETDDRAMADDR = 0x80;

// flags for display entry mode
const LCD_ENTRYSHIFTINCREMENT = 0x01;
const LCD_ENTRYLEFT = 0x02;

// flags for display and cursor control
const LCD_BLINKON = 0x01;
const LCD_CURSORON = 0x02;
const LCD_DISPLAYON = 0x04;

// flags for display and cursor shift
const LCD_MOVERIGHT = 0x04;
const LCD_DISPLAYMOVE = 0x08;

// flags for function set
const LCD_5x10DOTS = 0x04;
const LCD_2LINE = 0x08;
const LCD_8BITMODE = 0x10;

// flag for backlight control
const LCD_BACKLIGHT = 0x08;

// flag for backlight control
const LCD_COMMAND = 0;
const LCD_CHARACTER = 1;

data_pin: pin,
clock_pin: pin,
instance: [*c]c.struct_i2c_inst,
i2c_addr: u8 = 0x27,
enable_bit: u8 = 0x04,
max_lines: i32 = 2,
max_chars: i32 = 16,

pub fn init(data_pin: u8, clock_pin: u8) Self {
    const dp = pin.init(data_pin, pin.Direction.In);
    c.gpio_set_function(dp.num, c.GPIO_FUNC_I2C);

    const cp = pin.init(clock_pin, pin.Direction.In);
    c.gpio_set_function(cp.num, c.GPIO_FUNC_I2C);

    const instance = switch (dp.num) {
        0, 4, 8, 12, 16, 20 => c.i2c_get_instance(0),
        2, 6, 10, 14, 18, 26 => c.i2c_get_instance(1),
        else => unreachable,
    };

    const baud_rate: c_int = 100 * 1000;
    _ = c.i2c_init(instance, baud_rate);

    const ret: Self = .{ .data_pin = dp, .clock_pin = cp, .instance = instance };
    ret.send_byte(0x03, LCD_COMMAND);
    ret.send_byte(0x03, LCD_COMMAND);
    ret.send_byte(0x03, LCD_COMMAND);
    ret.send_byte(0x02, LCD_COMMAND);

    ret.send_byte(LCD_ENTRYMODESET | LCD_ENTRYLEFT, LCD_COMMAND);
    ret.send_byte(LCD_FUNCTIONSET | LCD_2LINE, LCD_COMMAND);
    ret.send_byte(LCD_DISPLAYCONTROL | LCD_DISPLAYON, LCD_COMMAND);

    return ret;
}

fn i2c_write_byte(self: Self, val: u8) void {
    _ = c.i2c_write_blocking(self.instance, self.i2c_addr, val, 1, false);
}

pub fn enable(self: Self, val: u8) void {
    const delay_us = 600;
    c.busy_wait_us(delay_us);
    self.i2c_write_byte(val | self.enable_bit);
    c.busy_wait_us(delay_us);
    self.i2c_write_byte(val & ~self.enable_bit);
    c.busy_wait_us(delay_us);
}

pub fn send_byte(self: Self, val: u8, mode: u8) void {
    const high = mode | (val & 0xF0) | Self.LCD_BACKLIGHT;
    const low = mode | ((val << 4) & 0xF0) | Self.LCD_BACKLIGHT;

    self.i2c_write_byte(high);
    self.enable(high);
    self.i2c_write_byte(high);
    self.enable(low);
}

pub fn clear(self: Self) void {
    self.send_byte(Self.LCD_CLEARDISPLAY, Self.LCD_COMMAND);
}

pub fn set_cursor(self: Self, line: u8, position: u8) void {
    if (line > 0) self.send_byte(0x80 + position, LCD_COMMAND) else self.send_byte(0xC0 + position, LCD_COMMAND);
}

fn lcd_char(self: Self, val: u8) void {
    self.send_byte(val, LCD_COMMAND);
}

pub fn lcd_string(self: Self, val: []u8) void {
    for (val) |character| self.lcd_char(character);
}
