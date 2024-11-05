const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{ .default_target = .{
        .os_tag = std.Target.Os.Tag.windows,
        .cpu_arch = std.Target.Cpu.Arch.x86_64,
        .abi = std.Target.Abi.msvc,
    } });
    const optimize = b.standardOptimizeOption(.{});

    const SFML_BUILD_AUDIO: bool = b.option(bool, "SFML_BUILD_AUDIO", "Whether to build SFML's Audio module. Defaults to `true`.") orelse true;
    const SFML_BUILD_GRAPHICS: bool = b.option(bool, "SFML_BUILD_GRAPHICS", "Whether to build SFML's Graphics module. Defaults to `true`.") orelse true;
    const SFML_BUILD_NETWORK: bool = b.option(bool, "SFML_BUILD_NETWORK", "Whether to build SFML's Network module. Defaults to `true`.") orelse true;
    const SFML_BUILD_WINDOW: bool = b.option(bool, "SFML_BUILD_WINDOW", "Whether to build SFML's Window module. Defaults to `true`.") orelse true;

    const sfml_system: *std.Build.Step.Compile = build_sfml_system(b, target, optimize);
    b.installArtifact(sfml_system);

    const sfml_main = build_sfml_main(b, target, optimize);
    b.installArtifact(sfml_main.?);

    if (SFML_BUILD_AUDIO) {
        const vorbis: *std.Build.Step.Compile = build_vorbis(b, target, optimize);
        b.installArtifact(vorbis);

        const flac: *std.Build.Step.Compile = build_flac(b, target, optimize);
        b.installArtifact(flac);

        const sfml_audio = build_sfml_audio(b, target, optimize, vorbis, flac, sfml_system);
        b.installArtifact(sfml_audio);
    }

    if (SFML_BUILD_GRAPHICS) {
        var sfml_graphics: *std.Build.Step.Compile = build_sfml_graphics(b, target, optimize);
        b.installArtifact(sfml_graphics);
    }

    if (SFML_BUILD_NETWORK) {
        var sfml_network: *std.Build.Step.Compile = undefined;
        b.installArtifact(sfml_network);
    }

    if (SFML_BUILD_WINDOW) {
        var sfml_window: *std.Build.Step.Compile = undefined;
        b.installArtifact(sfml_window);
    }
}

fn build_sfml_system(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) *std.Build.Step.Compile {
    const lib = b.addStaticLibrary(.{
        .name = "sfml-system",
        .target = target,
        .optimize = optimize,
    });

    lib.addIncludePath(b.path("src"));
    lib.addIncludePath(b.path("include"));

    const source_files = [_][]const u8{
        "Clock.cpp",
        "Err.cpp",
        "Sleep.cpp",
        "String.cpp",
        "Utils.cpp",
        "Vector2.cpp",
        "Vector3.cpp",
        "FileInputStream.cpp",
        "MemoryInputStream.cpp",
    };
    lib.addCSourceFiles(.{
        .root = b.path("src/SFML/System"),
        .files = &source_files,
        .flags = &[_][]const u8{"-std=c++17"},
    });

    if (target.result.os.tag == std.Target.Os.Tag.windows) {
        lib.addCSourceFile(.{
            .file = b.path("src/SFML/System/Win32/SleepImpl.cpp"),
            .flags = &[_][]const u8{"-std=c++17"},
        });
        lib.addIncludePath(b.path("src/SFML/System/Win32"));
    } else {
        lib.addCSourceFile(.{
            .file = b.path("src/SFML/System/Unix/SleepImpl.cpp"),
            .flags = &[_][]const u8{"-std=c++17"},
        });
        lib.addIncludePath(b.path("src/SFML/System/Unix"));

        if (target.result.isAndroid()) {
            lib.addIncludePath(b.path("src/SFML/System/Android"));

            const android_source_files = [_][]const u8{
                "Activity.cpp",
                "NativeActivity.cpp",
                "ResourceStream.cpp",
                "ResourceStream.cpp",
                "SuspendAwareClock.cpp",
            };
            lib.addCSourceFiles(.{
                .root = b.path("src/SFML/System/Android"),
                .files = &android_source_files,
                .flags = &[_][]const u8{"-std=c++17"},
            });
        }
    }

    if (target.result.os.tag == std.Target.Os.Tag.windows) {
        lib.linkSystemLibrary("kernel32");
    } else {
        lib.linkSystemLibrary("pthread");
    }

    lib.linkLibCpp();

    return lib;
}

fn build_sfml_main(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) ?*std.Build.Step.Compile {
    // define the sfml-main target
    const lib = b.addStaticLibrary(.{
        .name = "sfml-main",
        .target = target,
        .optimize = optimize,
    });

    lib.addIncludePath(b.path("src"));
    lib.addIncludePath(b.path("include"));

    // sources
    if (target.result.os.tag == std.Target.Os.Tag.windows) {
        lib.addCSourceFile(.{
            .file = b.path("src/SFML/Main/MainWin32.cpp"),
        });
        lib.linkLibC(); // for windows.h
    } else if (target.result.os.tag == std.Target.Os.Tag.ios) {
        lib.addCSourceFile(.{
            .file = b.path("src/SFML/Main/MainiOS.mm"),
        });
    } else if (target.result.isAndroid()) {
        // ensure that linking into shared libraries doesn't fail
        lib.addCSourceFile(.{
            .file = b.path("src/SFML/Main/MainAndroid.cpp"),
            .flags = &[_][]const u8{"-fPIC"},
        });

        // glad sources
        lib.addIncludePath(b.path("extlibs/headers/glad/include"));
    } else {
        return null;
    }
    return lib;
}

fn build_vorbis(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) *std.Build.Step.Compile {
    const lib = b.addStaticLibrary(.{
        .name = "vorbis",
        .target = target,
        .optimize = optimize,
    });

    lib.addIncludePath(b.path("extlibs/headers/ogg"));
    lib.addIncludePath(b.path("extlibs/headers/vorbis"));

    if (target.result.isAndroid()) {
        std.debug.print("@todo: include android libs based on ARCH\n", .{});
    } else if (target.result.os.tag == std.Target.Os.Tag.ios) {
        lib.addObjectFile(b.path("extlibs/libs-ios/libvorbis.a"));
    } else if (target.result.os.tag == std.Target.Os.Tag.macos) {
        std.debug.print("@todo include macos libs from .framework\n", .{});
    } else if (target.result.isMinGW()) {
        std.debug.print("@todo: how do i check for URT?\n", .{});
        if (target.result.cpu.arch.isX86()) {
            lib.addObjectFile(b.path("extlibs/libs-mingw/x86/libvorbis.a"));
            lib.addObjectFile(b.path("extlibs/libs-mingw/x86/libvorbisenc.a"));
            lib.addObjectFile(b.path("extlibs/libs-mingw/x86/libvorbisfile.a"));
        } else {
            std.debug.print("@todo: is this correctly x64?\n", .{});
            lib.addObjectFile(b.path("extlibs/libs-mingw/x64/libvorbis.a"));
            lib.addObjectFile(b.path("extlibs/libs-mingw/x64/libvorbisenc.a"));
            lib.addObjectFile(b.path("extlibs/libs-mingw/x64/libvorbisfile.a"));
        }
    } else if (target.result.os.tag == std.Target.Os.Tag.windows) {
        if (target.result.cpu.arch.isARM() and !target.result.cpu.arch.isX86()) {
            std.debug.print("@todo: is this correctly ARM64?\n", .{});
            lib.addObjectFile(b.path("extlibs/libs-msvc-universal/ARM64/vorbis.lib"));
            lib.addObjectFile(b.path("extlibs/libs-msvc-universal/ARM64/vorbisenc.lib"));
            lib.addObjectFile(b.path("extlibs/libs-msvc-universal/ARM64/vorbisfile.lib"));
        } else if (target.result.cpu.arch.isX86()) {
            lib.addObjectFile(b.path("extlibs/libs-msvc-universal/x86/vorbis.lib"));
            lib.addObjectFile(b.path("extlibs/libs-msvc-universal/x86/vorbisenc.lib"));
            lib.addObjectFile(b.path("extlibs/libs-msvc-universal/x86/vorbisfile.lib"));
        } else {
            std.debug.print("@todo: is this correctly x64?", .{});
            lib.addObjectFile(b.path("extlibs/libs-msvc-universal/x64/vorbis.lib"));
            lib.addObjectFile(b.path("extlibs/libs-msvc-universal/x64/vorbisenc.lib"));
            lib.addObjectFile(b.path("extlibs/libs-msvc-universal/x64/vorbisfile.lib"));
        }
    }
    return lib;
}

fn build_flac(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) *std.Build.Step.Compile {
    const lib = b.addStaticLibrary(.{
        .name = "flac",
        .target = target,
        .optimize = optimize,
    });

    lib.addIncludePath(b.path("extlibs/headers/FLAC"));
    lib.addLibraryPath(b.path(""));

    if (target.result.isAndroid()) {
        std.debug.print("@todo: include android libs based on ARCH\n", .{});
    } else if (target.result.os.tag == std.Target.Os.Tag.ios) {
        lib.addObjectFile(b.path("extlibs/libs-ios/libflac.a"));
    } else if (target.result.os.tag == std.Target.Os.Tag.macos) {
        std.debug.print("@todo include macos libs from .framework\n", .{});
    } else if (target.result.isMinGW()) {
        std.debug.print("@todo: how do i check for URT?\n", .{});
        if (target.result.cpu.arch.isX86()) {
            lib.addObjectFile(b.path("extlibs/libs-mingw/x86/libFLAC.a"));
        } else {
            std.debug.print("@todo: is this correctly x64?\n", .{});
            lib.addObjectFile(b.path("extlibs/libs-mingw/x64/libFLAC.a"));
        }
    } else if (target.result.os.tag == std.Target.Os.Tag.windows) {
        if (target.result.cpu.arch.isARM() and !target.result.cpu.arch.isX86()) {
            std.debug.print("@todo: is this correctly ARM64?\n", .{});
            lib.addObjectFile(b.path("extlibs/libs-msvc-universal/ARM64/flac.lib"));
        } else if (target.result.cpu.arch.isX86()) {
            lib.addObjectFile(b.path("extlibs/libs-msvc-universal/x86/flac.lib"));
        } else {
            std.debug.print("@todo: is this correctly x64?\n", .{});
            lib.addObjectFile(b.path("extlibs/libs-msvc-universal/x64/flac.lib"));
        }
    }

    return lib;
}

fn build_sfml_audio(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode, vorbis: *std.Build.Step.Compile, flac: *std.Build.Step.Compile, sfml_system: *std.Build.Step.Compile) *std.Build.Step.Compile {
    const lib = b.addStaticLibrary(.{
        .name = "sfml-audio",
        .target = target,
        .optimize = optimize,
    });

    lib.addIncludePath(b.path("src"));
    lib.addIncludePath(b.path("include"));

    // all source files
    const source_files = [_][]const u8{
        "AudioResource.cpp",
        "AudioDevice.cpp",
        "Listener.cpp",
        "Miniaudio.cpp",
        "MiniaudioUtils.cpp",
        "Music.cpp",
        "PlaybackDevice.cpp",
        "Sound.cpp",
        "SoundBuffer.cpp",
        "SoundBufferRecorder.cpp",
        "InputSoundFile.cpp",
        "OutputSoundFile.cpp",
        "SoundRecorder.cpp",
        "SoundSource.cpp",
        "SoundStream.cpp",
    };
    lib.addCSourceFiles(.{
        .root = b.path("src/SFML/Audio"),
        .files = &source_files,
        .flags = &[_][]const u8{"-std=c++17"},
    });

    const codec_files = [_][]const u8{
        "SoundFileFactory.cpp",
        "SoundFileReaderFlac.cpp",
        "SoundFileReaderMp3.cpp",
        "SoundFileReaderOgg.cpp",
        "SoundFileReaderWav.cpp",
        "SoundFileWriterFlac.cpp",
        "SoundFileWriterOgg.cpp",
        "SoundFileWriterWav.cpp",
    };

    // Ensure certain files are compiled as Objective-C++
    // See: https://miniaud.io/docs/manual/index.html#Building
    if (target.result.os.tag == std.Target.Os.Tag.ios) {
        std.debug.print("OBJCXX and Miniaudio.cpp not set", .{});
    }

    // let CMake know about our additional audio libraries paths (on Android and macOS)
    if (target.result.os.tag == std.Target.Os.Tag.macos) {
        std.debug.print("NEED TO ADD extlibs/libs-macos/Frameworks to LIBRARY PATH", .{});
    } else if (target.result.isAndroid()) {
        std.debug.print("NEED TO ADD extlibs/android to INCLUDE PATH", .{});
    }

    lib.addCSourceFiles(.{
        .root = b.path("src/SFML/Audio"),
        .files = &codec_files,
        .flags = &[_][]const u8{"-std=c++17"},
    });

    // avoids warnings in vorbisfile.h
    lib.defineCMacro("OV_EXCLUDE_STATIC_CALLBACKS", null);
    lib.defineCMacro("FLAC__NO_DLL", null);

    // disable miniaudio features we do not use
    lib.defineCMacro("MA_NO_MP3", null);
    lib.defineCMacro("MA_NO_FLAC", null);
    lib.defineCMacro("MA_NO_ENCODING", null);
    lib.defineCMacro("MA_NO_RESOURCE_MANAGER", null);
    lib.defineCMacro("MA_NO_GENERATION", null);

    // use standard fixed-width integer types
    lib.defineCMacro("MA_USE_STDINT", null);

    // miniaudio sources
    lib.addIncludePath(b.path("extlibs/headers/miniaudio"));

    // minimp3 sources
    lib.addIncludePath(b.path("extlibs/headers/minimp3"));

    if (target.result.isAndroid()) {
        lib.linkSystemLibrary("android");
        lib.linkSystemLibrary("OpenSLES");
    }

    if (target.result.os.tag == std.Target.Os.Tag.linux) {
        lib.linkSystemLibrary("dl");
    }

    lib.linkLibrary(sfml_system);

    lib.addIncludePath(b.path("extlibs/headers"));
    lib.linkLibrary(vorbis);
    lib.linkLibrary(flac);
    lib.linkLibCpp();

    return lib;
}

fn build_sfml_graphics(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode, vorbis: *std.Build.Step.Compile, flac: *std.Build.Step.Compile, sfml_system: *std.Build.Step.Compile) *std.Build.Step.Compile {
    const lib = b.addStaticLibrary(.{
        .name = "sfml-graphics",
        .target = target,
        .optimize = optimize,
    });

    return lib;
}
