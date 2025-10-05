# Zig Import Pico SDK

This project is by no means mature, just goofing around trying to see if I can get Zig and the Pico-SDK to play well together.

## Setup

1. Create a deps/ folder
2. Clone git@github.com:raspberrypi/pico-sdk.git into deps/pico-sdk/
3. Checkout version 2.2.0 in deps/pico-sdk/
4. Clone git@github.com:hathach/tinyusb.git into deps/tinyusb/

## Build

Start by running `./openocd` from the root of the dir.  As long as your Pico is plugged in, this should start an openocd session.

Next, run `./build`, this should build and open up GDB with a debug session to load and run your program.

I still need to do work for the external dependencies. 
