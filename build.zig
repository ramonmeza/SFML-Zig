const std = @import("std");

pub fn build(b: *std.Build) void {
    const targets = [_]std.Target.Query{.{
        .os_tag = std.Target.Os.Tag.windows,
        .cpu_arch = std.Target.Cpu.Arch.x86_64,
    }};
    const target = b.standardTargetOptions(.{ .whitelist = &targets });
    const optimize = b.standardOptimizeOption(.{});

    // sfml-main
    const sfml_main = b.addStaticLibrary(.{
        .name = "sfml-main",
        .target = target,
        .optimize = optimize,
    });

    sfml_main.addCSourceFile(.{ .file = b.path("src/SFML/Main/MainWin32.cpp") });

    sfml_main.addIncludePath(b.path("include"));
    sfml_main.addIncludePath(b.path("src"));

    sfml_main.linkLibCpp();

    b.installArtifact(sfml_main);

    // sfml-system
    const sfml_system = b.addStaticLibrary(.{
        .name = "sfml-system",
        .target = target,
        .optimize = optimize,
    });

    const sfml_system_source_files = [_][]const u8{
        "Clock.cpp",
        "Err.cpp",
        "Sleep.cpp",
        "String.cpp",
        "Utils.cpp",
        "Vector3.cpp",
        "FileInputStream.cpp",
        "MemoryInputStream.cpp",
    };
    sfml_system.addCSourceFiles(.{ .root = b.path("src/SFML/System"), .files = &sfml_system_source_files });

    sfml_system.addIncludePath(b.path("include"));
    sfml_system.addIncludePath(b.path("src"));

    sfml_system.linkLibCpp();

    b.installArtifact(sfml_system);

    // sfml-audio

    // vorbis
    const vorbis = b.addStaticLibrary(.{
        .name = "vorbis",
        .target = target,
        .optimize = optimize,
    });

    vorbis.addIncludePath(b.path("extlibs/headers/ogg"));
    vorbis.addIncludePath(b.path("extlibs/headers/vorbis"));

    vorbis.addObjectFile(b.path("extlibs/libs-msvc-universal/x64/ogg.lib"));
    vorbis.addObjectFile(b.path("extlibs/libs-msvc-universal/x64/vorbis.lib"));
    vorbis.addObjectFile(b.path("extlibs/libs-msvc-universal/x64/vorbisfile.lib"));
    vorbis.addObjectFile(b.path("extlibs/libs-msvc-universal/x64/vorbisenc.lib"));

    b.installArtifact(vorbis);

    // flac
    const flac = b.addStaticLibrary(.{
        .name = "flac",
        .target = target,
        .optimize = optimize,
    });

    flac.addIncludePath(b.path("extlibs/headers"));

    flac.addObjectFile(b.path("extlibs/libs-msvc-universal/x64/flac.lib"));

    b.installArtifact(flac);

    // sfml-audio
    const sfml_audio = b.addStaticLibrary(.{
        .name = "sfml-audio",
        .target = target,
        .optimize = optimize,
    });

    const sfml_audio_source_files = [_][]const u8{
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
    const sfml_audio_codedc_source_files = [_][]const u8{
        "SoundFileFactory.cpp",
        "SoundFileReaderFlac.cpp",
        "SoundFileReaderMp3.cpp",
        "SoundFileReaderOgg.cpp",
        "SoundFileReaderWav.cpp",
        "SoundFileWriterFlac.cpp",
        "SoundFileWriterOgg.cpp",
        "SoundFileWriterWav.cpp",
    };
    sfml_audio.addCSourceFiles(.{ .root = b.path("src/SFML/Audio"), .files = &sfml_audio_source_files });
    sfml_audio.addCSourceFiles(.{ .root = b.path("src/SFML/Audio"), .files = &sfml_audio_codedc_source_files });

    sfml_audio.addIncludePath(b.path("include"));
    sfml_audio.addIncludePath(b.path("src"));
    sfml_audio.addIncludePath(b.path("extlibs/headers"));
    sfml_audio.addIncludePath(b.path("extlibs/headers/miniaudio"));
    sfml_audio.addIncludePath(b.path("extlibs/headers/minimp3"));

    sfml_audio.linkLibrary(vorbis);
    sfml_audio.linkLibrary(flac);
    sfml_audio.linkLibCpp();

    b.installArtifact(sfml_audio);

    // sfml-window
    const sfml_window = b.addStaticLibrary(.{
        .name = "sfml-window",
        .target = target,
        .optimize = optimize,
    });

    const sfml_window_source_files = [_][]const u8{
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
    const sfml_window_source_files_win32 = [_][]const u8{
        "CursorImpl.cpp",
        "ClipboardImpl.cpp",
        "InputImpl.cpp",
        "JoystickImpl.cpp",
        "SensorImpl.cpp",
        "VideoModeImpl.cpp",
        "VulkanImplWin32.cpp",
        "WindowImplWin32.cpp",

        // no opengl es support yet
        "WglContext.cpp",
    };
    sfml_window.addCSourceFiles(.{ .root = b.path("src/SFML/Window"), .files = &sfml_window_source_files });
    sfml_window.addCSourceFiles(.{ .root = b.path("src/SFML/Window/Win32"), .files = &sfml_window_source_files_win32 });

    sfml_window.addIncludePath(b.path("include"));
    sfml_window.addIncludePath(b.path("src"));
    sfml_window.addIncludePath(b.path("extlibs/headers/glad/include"));
    sfml_window.addIncludePath(b.path("extlibs/headers/vulkan"));

    sfml_window.linkLibrary(sfml_system);
    sfml_window.linkSystemLibrary("winmm");
    sfml_window.linkSystemLibrary("gdi32");
    sfml_window.linkSystemLibrary("opengl32");
    sfml_window.linkLibCpp();

    b.installArtifact(sfml_window);

    // freetype
    const freetype = b.addStaticLibrary(.{
        .name = "freetype",
        .target = target,
        .optimize = optimize,
    });

    freetype.addIncludePath(b.path("extlibs/headers/freetype2"));

    freetype.addObjectFile(b.path("extlibs/libs-msvc-universal/x64/freetype.lib"));

    b.installArtifact(freetype);

    // sfml-graphics
    const sfml_graphics = b.addStaticLibrary(.{
        .name = "sfml-graphics",
        .target = target,
        .optimize = optimize,
    });

    const sfml_graphics_source_files = [_][]const u8{
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
    const sfml_graphics_drawables_source_files = [_][]const u8{
        "Shape.cpp",
        "CircleShape.cpp",
        "RectangleShape.cpp",
        "ConvexShape.cpp",
        "Sprite.cpp",
        "Text.cpp",
        "VertexArray.cpp",
        "VertexBuffer.cpp",
    };
    const sfml_graphics_render_texture_source_files = [_][]const u8{
        "RenderTextureImplFBO.cpp",
        "RenderTextureImplDefault.cpp",
    };
    sfml_graphics.addCSourceFiles(.{
        .root = b.path("src/SFML/Graphics"),
        .files = &sfml_graphics_source_files,
    });
    sfml_graphics.addCSourceFiles(.{
        .root = b.path("src/SFML/Graphics"),
        .files = &sfml_graphics_drawables_source_files,
    });
    sfml_graphics.addCSourceFiles(.{
        .root = b.path("src/SFML/Graphics"),
        .files = &sfml_graphics_render_texture_source_files,
    });

    sfml_graphics.addIncludePath(b.path("include"));
    sfml_graphics.addIncludePath(b.path("src"));
    sfml_graphics.addIncludePath(b.path("extlibs/headers/stb_image"));
    sfml_graphics.addIncludePath(b.path("extlibs/headers/glad/include"));
    sfml_graphics.addIncludePath(b.path("extlibs/headers/freetype2"));

    sfml_graphics.linkLibrary(freetype);
    sfml_graphics.linkLibrary(sfml_window);
    sfml_graphics.linkLibCpp();

    sfml_graphics.defineCMacro("STBI_FAILURE_USERMSG", null);

    b.installArtifact(
        sfml_graphics,
    );

    // sfml-network
    const sfml_network = b.addStaticLibrary(.{
        .name = "sfml-network",
        .target = target,
        .optimize = optimize,
    });

    const sfml_network_source_files = [_][]const u8{
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
    sfml_network.addCSourceFiles(.{
        .root = b.path("src/SFML/Network"),
        .files = &sfml_network_source_files,
    });
    sfml_network.addIncludePath(b.path("include"));
    sfml_network.addIncludePath(b.path("src"));

    switch (target.result.os.tag) {
        std.Target.Os.Tag.windows => {
            sfml_network.addCSourceFile(.{
                .file = b.path("src/SFML/Network/Win32/SocketImpl.cpp"),
            });
            sfml_network.linkSystemLibrary("ws2_32");
        },
        else => {
            sfml_network.addCSourceFile(.{
                .file = b.path("src/SFML/Network/Unix/SocketImpl.cpp"),
            });
        },
    }

    sfml_network.linkLibrary(sfml_system);
    b.installArtifact(sfml_network);
}
