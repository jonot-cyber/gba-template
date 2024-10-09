const std = @import("std");

pub fn build(b: *std.Build) void {
    const gba_img = b.addExecutable(.{
        .name = "gbaimg",
        .root_source_file = b.path("tools/gbaimg.zig"),
        .target = b.host,
        .link_libc = true,
    });
    _ = gba_img;

    const target = b.standardTargetOptions(.{
        .default_target = .{
            .cpu_arch = .thumb,
            .cpu_model = .{
                .explicit = &std.Target.arm.cpu.arm7tdmi,
            },
            .os_tag = .freestanding,
            .abi = .eabi,
        },
    });
    const optimize = b.standardOptimizeOption(.{});
    const elf = b.addExecutable(.{
        .name = "zig.elf",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .single_threaded = true,
        .link_libc = false,
        .linkage = .static,
        .omit_frame_pointer = true,
        .use_lld = true,
    });
    elf.addAssemblyFile(b.path("src/start.s"));
    elf.setLinkerScript(b.path("src/link.ld"));
    elf.addIncludePath(b.path("assets/"));

    _ = b.addInstallArtifact(elf, .{});

    const obj_copy = b.addObjCopy(elf.getEmittedBin(), .{
        .format = .bin,
    });
    obj_copy.step.dependOn(&elf.step);

    const copy_bin = b.addInstallBinFile(obj_copy.getOutput(), "zig.gba");
    b.default_step.dependOn(&copy_bin.step);

    // Add a run step
    const run_step_command = b.addSystemCommand(&.{
        "flatpak",
        "run",
        "io.mgba.mGBA",
    });
    run_step_command.addFileArg(obj_copy.getOutput());
    run_step_command.step.dependOn(&obj_copy.step);

    const run_step = b.step("run", "Run in an emulator");
    run_step.dependOn(&run_step_command.step);
}
