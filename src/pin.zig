const std = @import("std");

const c = @cImport({
    @cInclude("pico/stdlib.h");
    @cInclude("stdio.h");
    @cInclude("pico/runtime_init.h");
    @cInclude("pico/stdlib.h");
    @cInclude("hardware/gpio.h");
    @cInclude("hardware/irq.h");
    @cInclude("hardware/uart.h");
    @cInclude("hardware/sync.h");
});

const Self = @This();

pub const Direction = enum {
    In,
    Out,

    pub fn Get(self: Direction) bool {
        return self == Direction.Out;
    }
};

pub const State = enum {
    Low,
    High,
};

num: u8,
direction: Direction,
state: State,

pub fn init(num: u8, direction: Direction) Self {
    c.gpio_init(num);
    c.gpio_set_dir(num, direction.Get());
    if (direction == .In) {
        c.gpio_pull_up(num);
    }

    return .{
        .num = num,
        .direction = direction,
        .state = .Low,
    };
}

pub fn get(self: Self) bool {
    return c.gpio_get(self.num);
}

pub fn put(self: Self, val: bool) void {
    c.gpio_put(self.num, val);
}
