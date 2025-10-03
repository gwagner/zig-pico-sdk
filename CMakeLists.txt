cmake_minimum_required(VERSION 3.13)

# Initialize the Pico SDK
include(${PICO_SDK_PATH}/external/pico_sdk_import.cmake)
project(${PROJ_NAME})
pico_sdk_init()
add_executable(${PROJ_NAME})

if (STDIO_USB)
    pico_enable_stdio_uart(${PROJ_NAME} 0)
    pico_enable_stdio_usb(${PROJ_NAME} 1)
endif()

if (STDIO_UART)
    pico_enable_stdio_uart(${PROJ_NAME} 1)
    pico_enable_stdio_usb(${PROJ_NAME} 0)   
endif()

# Adjust libraries as needed
target_link_libraries(${PROJ_NAME} ${APP_PICO_LIBS} ${CMAKE_SOURCE_DIR}/zig-out/${PROJ_NAME}.a)

# Generate binary
pico_add_extra_outputs(${PROJ_NAME})
