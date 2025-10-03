const std = @import("std");

// Determine which file type we re including so we can switch below
const fileTypes = enum {
    c,
    S,

    pub fn getType(name: []u8) fileTypes {
        if (std.mem.eql(u8, &.{name[name.len - 1]}, "S")) return .S;

        return .c;
    }
};

pub fn build(b: *std.Build) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const optimize = b.standardOptimizeOption(.{});

    const target = b.resolveTargetQuery(.{
        .cpu_arch = .thumb,
        .os_tag = .freestanding,
        .abi = .eabi,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.cortex_m0plus },
    });

    const exe = b.addExecutable(.{
        .name = "test",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    exe.addIncludePath(b.path("."));
    exe.link_gc_sections = true;
    exe.link_z_relro = false;
    exe.stack_size = 4096;
    exe.setLinkerScript(b.path("src/link.ld"));

    // Read the config file
    const cincludes = try get_cIncludes(allocator);

    // Include all of the needed macros
    for (cincludes.macros) |macro| exe.root_module.addCMacro(macro.key, macro.value);

    // Add system libs
    exe.root_module.addSystemIncludePath(.{ .cwd_relative = "/usr/arm-none-eabi/include/" });
    exe.root_module.addCSourceFile(.{ .file = .{ .cwd_relative = "/usr/arm-none-eabi/lib/thumb/v7-m/nofp/libc.a" } });
    exe.root_module.addCSourceFile(.{ .file = .{ .cwd_relative = "/usr/arm-none-eabi/lib/thumb/v7-m/nofp/libnosys.a" } });
    exe.root_module.addCSourceFile(.{ .file = .{ .cwd_relative = "/usr/arm-none-eabi/lib/thumb/v7-m/nofp/libg.a" } });
    exe.root_module.addCSourceFile(.{ .file = .{ .cwd_relative = "/usr/arm-none-eabi/lib/thumb/v7-m/nofp/libm.a" } });
    exe.root_module.addCSourceFile(.{ .file = .{ .cwd_relative = "/usr/arm-none-eabi/lib/thumb/v7-m/nofp/librdimon.a" } });
    exe.root_module.addCSourceFile(.{ .file = .{ .cwd_relative = "/usr/arm-none-eabi/lib/thumb/v7-m/nofp/librdimon.a" } });
    exe.root_module.addCSourceFile(.{ .file = .{ .cwd_relative = "/usr/arm-none-eabi/lib/thumb/v7-m/nofp/crt0.o" } });

    // Include everything form JSON
    for (cincludes.includePaths) |path| exe.root_module.addIncludePath(b.path(path));
    for (cincludes.sysIncludePaths) |path| exe.root_module.addSystemIncludePath(b.path(path));

    // Add all C (.c) and assembly_with_preprocessor (.S) files
    for (cincludes.cSourceFiles) |file|
        switch (fileTypes.getType(file)) {
            .c => exe.root_module.addCSourceFile(.{
                .file = b.path(file),
                .flags = &.{
                    "-std=gnu11",
                    "-ffunction-sections",
                    "-fdata-sections",
                    "-fno-exceptions",
                    "-fno-unwind-tables",
                    "-fno-asynchronous-unwind-tables",
                    "-Os",
                    "-fPIC",
                },
            }),
            .S => exe.root_module.addCSourceFile(.{
                .file = b.path(file),
                .language = .assembly_with_preprocessor,
                .flags = &.{
                    "-std=gnu11",
                    "-ffunction-sections",
                    "-fdata-sections",
                    "-fno-exceptions",
                    "-fno-unwind-tables",
                    "-fno-asynchronous-unwind-tables",
                    "-Os",
                    "-fPIC",
                },
            }),
        };

    b.installArtifact(exe);
}

const parsed_cIncludes = struct {
    macros: []macroEntry,
    includePaths: []const []u8,
    sysIncludePaths: []const []u8,
    cSourceFiles: []const []u8,
};

const cIncludes = struct {
    macros: []macroEntry,
    includes: []cIncludesEntry,
};

const cIncludesEntry = struct {
    header: []u8,
    cfiles: []const []u8,
    sys_include: ?bool = null,
    valid: ?bool = null,
};

const macroEntry = struct {
    key: []u8,
    value: []u8,
};

pub fn get_cIncludes(alloc: std.mem.Allocator) !parsed_cIncludes {
    // Read the entire file contents into an allocated buffer
    const file_contents = try std.fs.cwd().readFileAlloc(alloc, "cIncludes.json", std.math.maxInt(usize));
    defer alloc.free(file_contents); // Free the allocated memory when done

    const parsed_result = try std.json.parseFromSlice(cIncludes, alloc, file_contents, .{});
    defer parsed_result.deinit();

    var headers = try std.ArrayList([]u8).initCapacity(alloc, 0);
    var sys_headers = try std.ArrayList([]u8).initCapacity(alloc, 0);
    var source_files = try std.ArrayList([]u8).initCapacity(alloc, 0);

    for (parsed_result.value.includes) |entry| {
        const valid = entry.valid orelse true;
        const sys_include = entry.sys_include orelse false;
        if (!valid) continue;

        if (!std.mem.eql(u8, entry.header, "") and sys_include) try sys_headers.append(alloc, entry.header) else try headers.append(alloc, entry.header);
        for (entry.cfiles) |source_file| try source_files.append(alloc, source_file);
    }

    var macros = try std.ArrayList(macroEntry).initCapacity(alloc, 0);
    for (parsed_result.value.macros) |entry| {
        try macros.append(alloc, entry);
    }

    std.debug.assert(sys_headers.items.len > 0);
    std.debug.assert(source_files.items.len > 0);
    std.debug.assert(macros.items.len > 0);

    return .{
        .macros = try macros.toOwnedSlice(alloc),
        .includePaths = try headers.toOwnedSlice(alloc),
        .sysIncludePaths = try sys_headers.toOwnedSlice(alloc),
        .cSourceFiles = try source_files.toOwnedSlice(alloc),
    };
}
