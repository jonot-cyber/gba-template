const std = @import("std");

pub fn build(b: *std.Build) void {
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
    const optimize = .ReleaseSmall;
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

    const objCopy = b.addObjCopy(elf.getEmittedBin(), .{
        .format = .bin,
    });
    objCopy.step.dependOn(&elf.step);

    const copyBin = b.addInstallBinFile(objCopy.getOutput(), "zig.gba");
    b.default_step.dependOn(&copyBin.step);

    // Add a run step
    const runStepCommand = b.addSystemCommand(&.{
        "flatpak",
        "run",
        "io.mgba.mGBA",
    });
    runStepCommand.addFileArg(objCopy.getOutput());
    runStepCommand.step.dependOn(&objCopy.step);

    const runStep = b.step("run", "Run in an emulator");
    runStep.dependOn(&runStepCommand.step);
}
