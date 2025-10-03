const std = @import("std");
const pin = @import("pin.zig");

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

export fn _init() void {
    c.runtime_init_clocks();
    c.runtime_init_early_resets();
    c.runtime_init_spin_locks_reset();
}

export fn main() void {
    _init();

    const blink_pin = pin.init(c.PICO_DEFAULT_LED_PIN, pin.Direction.Out);
    const read_pin = pin.init(0, pin.Direction.In);

    while (true) {
        c.busy_wait_ms(10);
        if (read_pin.get()) {
            blink_pin.put(true);
            continue;
        }
        blink_pin.put(false);
    }
}

// // FIX ME: probably a hack and will break
export fn _fini() void {}
