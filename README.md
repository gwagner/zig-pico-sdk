# Zig Import Pico SDK

This project is by no means mature, just goofing around trying to see if I can get Zig and the Pico-SDK to play well together.

## Setup

1. Create a deps/ folder
2. Clone git@github.com:raspberrypi/pico-sdk.git into deps/pico-sdk/
3. Checkout version 2.2.0 in deps/pico-sdk/
4. Clone git@github.com:hathach/tinyusb.git into deps/tinyusb/

## Build

I need to do work for the external dependencies, but you should be able to run `zig build && elfuf2-rs zig-out/bin/test image.uf2` from the root of the project, and a build should pop out?
