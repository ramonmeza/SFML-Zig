const std = @import("std");

const CXX_FLAGS = &[_][]const u8{"-std=c++17"};

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

    std.debug.print("Building sfml-system...", .{});
    const sfml_system: *std.Build.Step.Compile = build_sfml_system(b, target, optimize);
    b.installArtifact(sfml_system);
    std.debug.print("done\n", .{});

    std.debug.print("Building sfml-main...", .{});
    const sfml_main = build_sfml_main(b, target, optimize);
    b.installArtifact(sfml_main.?);
    std.debug.print("done\n", .{});

    var sfml_window: ?*std.Build.Step.Compile = null;

    if (SFML_BUILD_AUDIO) {
        std.debug.print("Building vorbis...", .{});
        const vorbis: *std.Build.Step.Compile = build_vorbis(b, target, optimize);
        b.installArtifact(vorbis);
        std.debug.print("done\n", .{});

        std.debug.print("Building flac...", .{});
        const flac: *std.Build.Step.Compile = build_flac(b, target, optimize);
        b.installArtifact(flac);
        std.debug.print("done\n", .{});

        std.debug.print("Building sfml-audio...", .{});
        const sfml_audio = build_sfml_audio(b, target, optimize, vorbis, flac, sfml_system);
        b.installArtifact(sfml_audio);
        std.debug.print("done\n", .{});
    }

    if (SFML_BUILD_GRAPHICS) {
        std.debug.print("Building sfml-window...", .{});
        sfml_window = build_sfml_window(b, target, optimize, sfml_system);
        b.installArtifact(sfml_window.?);
        std.debug.print("done\n", .{});

        std.debug.print("Building freetype...", .{});
        const freetype = build_freetype(b, target, optimize);
        b.installArtifact(freetype);
        std.debug.print("done\n", .{});

        std.debug.print("Building sfml-graphics...", .{});
        const sfml_graphics: *std.Build.Step.Compile = build_sfml_graphics(b, target, optimize, sfml_window.?, freetype);
        b.installArtifact(sfml_graphics);
        std.debug.print("done\n", .{});
    }

    if (SFML_BUILD_NETWORK) {
        std.debug.print("Building sfml-network...", .{});
        const sfml_network: *std.Build.Step.Compile = build_sfml_network(b, target, optimize, sfml_system);
        b.installArtifact(sfml_network);
        std.debug.print("done\n", .{});
    }

    if (SFML_BUILD_WINDOW) {
        if (sfml_window == null) {
            std.debug.print("Building sfml-window...", .{});
            sfml_window = build_sfml_window(b, target, optimize, sfml_system);
            b.installArtifact(sfml_window.?);
            std.debug.print("done\n", .{});
        }
    }
}

fn build_sfml_network(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode, sfml_system: *std.Build.Step.Compile) *std.Build.Step.Compile {
    // define the sfml-network target
    const lib = b.addStaticLibrary(.{
        .name = "sfml-network",
        .target = target,
        .optimize = optimize,
    });

    lib.addIncludePath(b.path("src"));
    lib.addIncludePath(b.path("include"));

    // all source files
    const source_files = [_][]const u8{
        "Ftp.cpp",
        "Http.cpp",
        "IpAddress.cpp",
        "Packet.cpp",
        "Socket.cpp",
        "SocketSelector.cpp",
        "TcpListener.cpp",
        "TcpSocket.cpp",
        "UdpSocket.cpp",
    };
    lib.addCSourceFiles(.{
        .root = b.path("src/SFML/Network"),
        .files = &source_files,
        .flags = CXX_FLAGS,
    });

    // add platform specific sources
    if (target.result.os.tag == std.Target.Os.Tag.windows) {
        lib.addCSourceFile(.{
            .file = b.path("src/SFML/Network/Win32/SocketImpl.cpp"),
            .flags = CXX_FLAGS,
        });
    } else {
        lib.addCSourceFile(.{
            .file = b.path("src/SFML/Network/Unix/SocketImpl.cpp"),
            .flags = CXX_FLAGS,
        });
    }

    // setup dependencies
    lib.linkLibrary(sfml_system);
    if (target.result.os.tag == std.Target.Os.Tag.windows) {
        lib.linkSystemLibrary("ws2_32");
    }

    return lib;
}

fn build_sfml_window(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode, sfml_system: *std.Build.Step.Compile) *std.Build.Step.Compile {
    const SFML_USE_DRM: bool = b.option(bool, "SFML_USE_DRM", "Whether to use DRM windowing backend. Defaults to false.") orelse false;
    const SFML_OPENGL_ES = b.option(bool, "SFML_OPENGL_ES", "Whether to use OpenGL ES implementation. Defaults to false.") orelse false;

    // define the sfml-window target
    const lib = b.addStaticLibrary(.{
        .name = "sfml-window",
        .target = target,
        .optimize = optimize,
    });

    lib.addIncludePath(b.path("src"));
    lib.addIncludePath(b.path("include"));

    const source_files = [_][]const u8{
        "Clipboard.cpp",
        "Context.cpp",
        "Cursor.cpp",
        "GlContext.cpp",
        "GlResource.cpp",
        "Joystick.cpp",
        "JoystickManager.cpp",
        "Keyboard.cpp",
        "Mouse.cpp",
        "Touch.cpp",
        "Sensor.cpp",
        "SensorManager.cpp",
        "VideoMode.cpp",
        "Vulkan.cpp",
        "Window.cpp",
        "WindowBase.cpp",
        "WindowImpl.cpp",
    };

    lib.addCSourceFiles(.{
        .root = b.path("src/SFML/Window"),
        .files = &source_files,
        .flags = CXX_FLAGS,
    });

    if (target.result.os.tag == std.Target.Os.Tag.windows) {
        lib.addCSourceFiles(.{
            .root = b.path("src/SFML/Window/Win32"),
            .files = &[_][]const u8{
                "CursorImpl.cpp",
                "ClipboardImpl.cpp",
                "InputImpl.cpp",
                "JoystickImpl.cpp",
                "SensorImpl.cpp",
                "VideoModeImpl.cpp",
                "VulkanImplWin32.cpp",
                "WindowImplWin32.cpp",
            },
            .flags = CXX_FLAGS,
        });

        if (SFML_OPENGL_ES) {
            lib.addCSourceFiles(.{
                .root = b.path("src/SFML/Window"),
                .files = &[_][]const u8{
                    "EGLCheck.cpp",
                    "EglContext.cpp",
                },
                .flags = CXX_FLAGS,
            });
        } else {
            lib.addCSourceFiles(.{
                .root = b.path("src/SFML/Window/Win32"),
                .files = &[_][]const u8{
                    "WglContext.cpp",
                },
                .flags = CXX_FLAGS,
            });
        }
    } else if (target.result.os.tag == std.Target.Os.Tag.linux or
        target.result.os.tag == std.Target.Os.Tag.freebsd or
        target.result.os.tag == std.Target.Os.Tag.openbsd or
        target.result.os.tag == std.Target.Os.Tag.netbsd)
    {
        if (SFML_USE_DRM) {
            lib.defineCMacro("SFML_USE_DRM", null);
            lib.addCSourceFiles(.{
                .root = b.path("src/SFML/Window"),
                .files = &[_][]const u8{
                    "EGLCheck.cpp",
                    "DRM/CursorImpl.cpp",
                    "DRM/ClipboardImpl.cpp",
                    "Unix/SensorImpl.cpp",
                    "DRM/InputImpl.cpp",
                    "DRM/VideoModeImpl.cpp",
                    "DRM/DRMContext.cpp",
                    "DRM/WindowImplDRM.cpp",
                },
                .flags = CXX_FLAGS,
            });
        } else {
            lib.addCSourceFiles(.{
                .root = b.path("src/SFML/Window/Unix"),
                .files = &[_][]const u8{
                    "CursorImpl.cpp",
                    "ClipboardImpl.cpp",
                    "InputImpl.cpp",
                    "KeyboardImpl.cpp",
                    "KeySymToKeyMapping.cpp",
                    "KeySymToUnicodeMapping.cpp",
                    "SensorImpl.cpp",
                    "Display.cpp",
                    "VideoModeImpl.cpp",
                    "VulkanImplX11.cpp",
                    "WindowImplX11.cpp",
                },
                .flags = CXX_FLAGS,
            });
        }

        if (SFML_OPENGL_ES) {
            lib.addCSourceFiles(.{
                .root = b.path("src/SFML/Window"),
                .files = &[_][]const u8{
                    "EGLCheck.cpp",
                    "EglContext.cpp",
                },
                .flags = CXX_FLAGS,
            });
        } else {
            lib.addCSourceFiles(.{
                .root = b.path("src/SFML/Window/Unix"),
                .files = &[_][]const u8{
                    "GlxContext.cpp",
                },
                .flags = CXX_FLAGS,
            });
        }

        if (target.result.os.tag == std.Target.Os.Tag.linux) {
            lib.addCSourceFiles(.{
                .root = b.path("src/SFML/Window/Unix"),
                .files = &[_][]const u8{
                    "JoystickImpl.cpp",
                },
                .flags = CXX_FLAGS,
            });
        } else if (target.result.os.tag == std.Target.Os.Tag.freebsd) {
            lib.addCSourceFiles(.{
                .root = b.path("src/SFML/Window/FreeBSD"),
                .files = &[_][]const u8{
                    "JoystickImpl.cpp",
                },
                .flags = CXX_FLAGS,
            });
        } else if (target.result.os.tag == std.Target.Os.Tag.openbsd) {
            lib.addCSourceFiles(.{
                .root = b.path("src/SFML/Window/OpenBSD"),
                .files = &[_][]const u8{
                    "JoystickImpl.cpp",
                },
                .flags = CXX_FLAGS,
            });
        } else if (target.result.os.tag == std.Target.Os.Tag.netbsd) {
            lib.addCSourceFiles(.{
                .root = b.path("src/SFML/Window/NetBSD"),
                .files = &[_][]const u8{
                    "JoystickImpl.cpp",
                },
                .flags = CXX_FLAGS,
            });
        }
    } else if (target.result.os.tag == std.Target.Os.Tag.macos) {
        std.debug.print("@todo: build_sfml_window(): I don't think zig can compile OBJCXX :)\n", .{});
        lib.addCSourceFiles(.{
            .root = b.path("src/SFML/Window/NetBSD"),
            .files = &[_][]const u8{
                "cg_sf_conversion.mm",
                "CursorImpl.mm",
                "ClipboardImpl.mm",
                "InputImpl.mm",
                "HIDInputManager.mm",
                "HIDJoystickManager.cpp",
                "JoystickImpl.cpp",
                "NSImage+raw.mm",
                "SensorImpl.cpp",
                "SFApplication.m",
                "SFApplicationDelegate.m",
                "SFContext.mm",
                "SFKeyboardModifiersHelper.mm",
                "SFOpenGLView.mm",
                "SFOpenGLView+keyboard.mm",
                "SFOpenGLView+mouse.mm",
                "SFSilentResponder.m",
                "SFWindow.m",
                "SFWindowController.mm",
                "SFViewController.mm",
                "VideoModeImpl.cpp",
                "WindowImplCocoa.mm",
                "AutoreleasePoolWrapper.mm",
            },
        });
    } else if (target.result.os.tag == std.Target.Os.Tag.ios) {
        std.debug.print("@todo: build_sfml_window(): I don't think zig can compile OBJCXX :)\n", .{});
        lib.addCSourceFiles(.{
            .root = b.path("src/SFML/Window/iOS"),
            .files = &[_][]const u8{
                "CursorImpl.cpp",
                "ClipboardImpl.mm",
                "EaglContext.mm",
                "InputImpl.mm",
                "JoystickImpl.mm",
                "SensorImpl.mm",
                "VideoModeImpl.mm",
                "WindowImplUIKit.mm",
                "SFAppDelegate.mm",
                "SFView.mm",
                "SFViewController.mm",
                "SFMain.mm",
            },
        });
    } else if (target.result.isAndroid()) {
        lib.addCSourceFiles(.{
            .root = b.path("src/SFML/Window"),
            .files = &[_][]const u8{
                "EGLCheck.cpp",
                "EglContext.cpp",
                "Android/CursorImpl.cpp",
                "Android/ClipboardImpl.cpp",
                "Android/WindowImplAndroid.cpp",
                "Android/VideoModeImpl.cpp",
                "Android/InputImpl.cpp",
                "Android/JoystickImpl.cpp",
                "Android/SensorImpl.cpp",
            },
            .flags = CXX_FLAGS,
        });
    }

    if (target.result.os.tag == std.Target.Os.Tag.linux or
        target.result.os.tag == std.Target.Os.Tag.freebsd or
        target.result.os.tag == std.Target.Os.Tag.openbsd or
        target.result.os.tag == std.Target.Os.Tag.netbsd)
    {
        if (SFML_USE_DRM) {
            // drm
            lib.linkSystemLibrary("libdrm");

            // gbm
            lib.linkSystemLibrary("gbm");
        } else {
            lib.linkSystemLibrary("X11");
            lib.linkSystemLibrary("Xrandr");
            lib.linkSystemLibrary("Xcursor");
            lib.linkSystemLibrary("Xi");
        }
    }

    lib.linkLibrary(sfml_system);

    // glad sources
    lib.addIncludePath(b.path("extlibs/headers/glad/include"));

    // @todo: link -ObjC when !BUILD_SHARED_LIBS and SFML_OS_MACOS

    // Vulkan headers
    lib.addIncludePath(b.path("extlibs/headers/vulkan"));

    if (target.result.os.tag == std.Target.Os.Tag.ios) {
        // @todo: target_link_libraries(sfml-window PRIVATE "-framework OpenGLES")
        std.debug.print("build_sfml_window(): target_link_libraries(sfml-window PRIVATE \"-framework OpenGLES\")\n", .{});
    } else if (target.result.isAndroid()) {
        // EGL
        std.debug.print("build_sfml_window(): find_package(EGL REQUIRED)\n", .{});
        // GLES
        std.debug.print("build_sfml_window(): find_package(GLES REQUIRED)\n", .{});
    } else {
        std.debug.print("@todo: remember to link opengl properly on all platforms\n", .{});
        lib.linkSystemLibrary("opengl32");
    }

    // @todo: include dinput for windows and !msvc

    if (target.result.os.tag == std.Target.Os.Tag.linux) {
        // UDev
        std.debug.print("build_sfml_window(): find_package(UDev REQUIRED)\n", .{});
    } else if (target.result.os.tag == std.Target.Os.Tag.windows) {
        lib.linkSystemLibrary("winmm");
        lib.linkSystemLibrary("gdi32");
    } else if (target.result.os.tag == std.Target.Os.Tag.freebsd) {
        lib.linkSystemLibrary("usbhid");
    } else if (target.result.os.tag == std.Target.Os.Tag.macos) {
        lib.linkSystemLibrary("-framework Foundation");
        lib.linkSystemLibrary("-framework AppKit");
        lib.linkSystemLibrary("-framework IOKit");
        lib.linkSystemLibrary("-framework Carbon");
    } else if (target.result.os.tag == std.Target.Os.Tag.ios) {
        lib.linkSystemLibrary("-framework Foundation");
        lib.linkSystemLibrary("-framework UIKit");
        lib.linkSystemLibrary("-framework CoreGraphics");
        lib.linkSystemLibrary("-framework QuartzCore");
        lib.linkSystemLibrary("-framework CoreMotion");
    } else if (target.result.isAndroid()) {
        lib.linkSystemLibrary("android");
    }

    // @todo: for gcc, link to atomic

    return lib;
}

fn build_freetype(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) *std.Build.Step.Compile {
    const lib = b.addStaticLibrary(.{
        .name = "freetype",
        .target = target,
        .optimize = optimize,
    });

    if (target.result.isAndroid()) {
        lib.addIncludePath(b.path("extlibs/headers/freetype2"));
        std.debug.print("@todo: include android libs based on ARCH\n", .{});
    } else if (target.result.os.tag == std.Target.Os.Tag.ios) {
        lib.addIncludePath(b.path("extlibs/headers/freetype2"));
        lib.addObjectFile(b.path("extlibs/libs-ios/libfreetype.a"));
    } else if (target.result.os.tag == std.Target.Os.Tag.macos) {
        std.debug.print("@todo include macos libs from .framework\n", .{});
        lib.addIncludePath(b.path("extlibs/headers/freetype2"));
        lib.addIncludePath(b.path("extlibs/libs-macos/Frameworks"));
    } else if (target.result.isMinGW()) {
        std.debug.print("@todo: how do i check for URT?\n", .{});
        if (target.result.cpu.arch.isX86()) {
            lib.addObjectFile(b.path("extlibs/libs-mingw/x86/libfreetype.a"));
        } else {
            std.debug.print("@todo: is this correctly x64?\n", .{});
            lib.addObjectFile(b.path("extlibs/libs-mingw/x64/libfreetype.a"));
        }
    } else if (target.result.os.tag == std.Target.Os.Tag.windows) {
        lib.addIncludePath(b.path("extlibs/headers/freetype2"));
        if (target.result.cpu.arch.isARM() and !target.result.cpu.arch.isX86()) {
            std.debug.print("@todo: is this correctly ARM64?\n", .{});
            lib.addObjectFile(b.path("extlibs/libs-msvc-universal/ARM64/freetype.lib"));
        } else if (target.result.cpu.arch.isX86()) {
            lib.addObjectFile(b.path("extlibs/libs-msvc-universal/x86/freetype.lib"));
        } else {
            std.debug.print("@todo: is this correctly x64?\n", .{});
            lib.addObjectFile(b.path("extlibs/libs-msvc-universal/x64/freetype.lib"));
        }
    }

    return lib;
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
        .flags = CXX_FLAGS,
    });

    if (target.result.os.tag == std.Target.Os.Tag.windows) {
        lib.addCSourceFile(.{
            .file = b.path("src/SFML/System/Win32/SleepImpl.cpp"),
            .flags = CXX_FLAGS,
        });
        lib.addIncludePath(b.path("src/SFML/System/Win32"));
    } else {
        lib.addCSourceFile(.{
            .file = b.path("src/SFML/System/Unix/SleepImpl.cpp"),
            .flags = CXX_FLAGS,
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
                .flags = CXX_FLAGS,
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
            std.debug.print("@todo: is this correctly x64?\n", .{});
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
        .flags = CXX_FLAGS,
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
        std.debug.print("OBJCXX and Miniaudio.cpp not set\n", .{});
    }

    // let CMake know about our additional audio libraries paths (on Android and macOS)
    if (target.result.os.tag == std.Target.Os.Tag.macos) {
        std.debug.print("NEED TO ADD extlibs/libs-macos/Frameworks to LIBRARY PATH\n", .{});
    } else if (target.result.isAndroid()) {
        std.debug.print("NEED TO ADD extlibs/android to INCLUDE PATH\n", .{});
    }

    lib.addCSourceFiles(.{
        .root = b.path("src/SFML/Audio"),
        .files = &codec_files,
        .flags = CXX_FLAGS,
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

fn build_sfml_graphics(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode, sfml_window: *std.Build.Step.Compile, freetype: *std.Build.Step.Compile) *std.Build.Step.Compile {
    // define the sfml-graphics target
    const lib = b.addStaticLibrary(.{
        .name = "sfml-graphics",
        .target = target,
        .optimize = optimize,
    });

    lib.addIncludePath(b.path("src"));
    lib.addIncludePath(b.path("include"));

    // all source files
    const source_files = [_][]const u8{
        "BlendMode.cpp",
        "Font.cpp",
        "Glsl.cpp",
        "GLCheck.cpp",
        "GLExtensions.cpp",
        "Image.cpp",
        "RenderStates.cpp",
        "RenderTexture.cpp",
        "RenderTarget.cpp",
        "RenderWindow.cpp",
        "Shader.cpp",
        "StencilMode.cpp",
        "Texture.cpp",
        "TextureSaver.cpp",
        "Transform.cpp",
        "Transformable.cpp",
        "View.cpp",
    };
    lib.addCSourceFiles(.{
        .root = b.path("src/SFML/Graphics"),
        .files = &source_files,
        .flags = CXX_FLAGS,
    });

    // drawables sources
    const drawables_source_files = [_][]const u8{
        "Shape.cpp",
        "CircleShape.cpp",
        "RectangleShape.cpp",
        "ConvexShape.cpp",
        "Sprite.cpp",
        "Text.cpp",
        "VertexArray.cpp",
        "VertexBuffer.cpp",
    };
    lib.addCSourceFiles(.{
        .root = b.path("src/SFML/Graphics"),
        .files = &drawables_source_files,
        .flags = CXX_FLAGS,
    });

    // render-texture sources
    const render_texture_source_files = [_][]const u8{
        "RenderTextureImplFBO.cpp",
        "RenderTextureImplDefault.cpp",
    };
    lib.addCSourceFiles(.{
        .root = b.path("src/SFML/Graphics"),
        .files = &render_texture_source_files,
        .flags = CXX_FLAGS,
    });

    // setup dependencies
    lib.linkLibrary(sfml_window);

    // stb_image sources
    lib.addIncludePath(b.path("extlibs/headers/stb_image"));

    // glad sources
    lib.addIncludePath(b.path("extlibs/headers/glad/include/"));

    // let build know about our additional graphics libraries paths
    if (target.result.os.tag == std.Target.Os.Tag.windows) {
        lib.addIncludePath(b.path("extlibs/headers/freetype2"));
    } else if (target.result.os.tag == std.Target.Os.Tag.macos) {
        lib.addIncludePath(b.path("extlibs/headers/freetype2"));
        lib.addIncludePath(b.path("extlibs/libs-macos/Frameworks"));
    } else if (target.result.os.tag == std.Target.Os.Tag.ios) {
        lib.addIncludePath(b.path("extlibs/headers/freetype2"));
    } else if (target.result.isAndroid()) {
        lib.addIncludePath(b.path("extlibs/headers/freetype2"));
    }

    // find external libraries
    if (target.result.isAndroid()) {
        lib.linkSystemLibrary("z");
    } else if (target.result.os.tag == std.Target.Os.Tag.ios) {
        lib.linkSystemLibrary("z");
        lib.linkSystemLibrary("bz2");
    }

    // freetype
    lib.linkLibrary(freetype);

    return lib;
}
