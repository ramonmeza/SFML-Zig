const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const SFML_BUILD_AUDIO: bool = b.option(bool, "SFML_BUILD_AUDIO", "Whether to build SFML's Audio module.") orelse true;
    const SFML_BUILD_GRAPHICS: bool = b.option(bool, "SFML_BUILD_GRAPHICS", "Whether to build SFML's Graphics module.") orelse true;

    // sfml-audio
    if (SFML_BUILD_AUDIO) {
        const sfml_audio = b.addStaticLibrary(.{ .name = "sfml-audio", .target = target, .optimize = optimize });
        const sfml_audio_sources = [_][]const u8{
            "AudioDevice.cpp",
            "AudioResource.cpp",
            "InputSoundFile.cpp",
            "Listener.cpp",
            "Miniaudio.cpp",
            "MiniaudioUtils.cpp",
            "Music.cpp",
            "OutputSoundFile.cpp",
            "PlaybackDevice.cpp",
            "Sound.cpp",
            "SoundBuffer.cpp",
            "SoundBufferRecorder.cpp",
            "SoundFileFactory.cpp",
            "SoundFileReaderFlac.cpp",
            "SoundFileReaderMp3.cpp",
            "SoundFileReaderOgg.cpp",
            "SoundFileReaderWav.cpp",
            "SoundFileWriterFlac.cpp",
            "SoundFileWriterOgg.cpp",
            "SoundFileWriterWav.cpp",
            "SoundRecorder.cpp",
            "SoundSource.cpp",
            "SoundStream.cpp",
        };
        sfml_audio.addIncludePath(b.path("include"));
        sfml_audio.addIncludePath(b.path("src"));
        sfml_audio.addIncludePath(b.path("extlibs/headers"));
        sfml_audio.addIncludePath(b.path("extlibs/headers/miniaudio"));
        sfml_audio.addIncludePath(b.path("extlibs/headers/minimp3"));
        sfml_audio.addCSourceFiles(.{
            .root = b.path("src/SFML/Audio"),
            .files = &sfml_audio_sources,
        });

        sfml_audio.linkLibCpp();
        b.installArtifact(sfml_audio);
    }

    // sfml-graphics
    if (SFML_BUILD_GRAPHICS) {
        const sfml_graphics = b.addStaticLibrary(.{ .name = "sfml-graphics", .target = target, .optimize = optimize });
        const sfml_graphics_sources = [_][]const u8{
            "BlendMode.cpp",
            "CircleShape.cpp",
            "ConvexShape.cpp",
            "Font.cpp",
            "GLCheck.cpp",
            "GLExtensions.cpp",
            "Glsl.cpp",
            "Image.cpp",
            "RectangleShape.cpp",
            "RenderStates.cpp",
            "RenderTarget.cpp",
            "RenderTexture.cpp",
            "RenderTextureImplDefault.cpp",
            "RenderTextureImplFBO.cpp",
            "RenderWindow.cpp",
            "Shader.cpp",
            "Shape.cpp",
            "Sprite.cpp",
            "StencilMode.cpp",
            "Text.cpp",
            "Texture.cpp",
            "TextureSaver.cpp",
            "Transform.cpp",
            "Transformable.cpp",
            "VertexArray.cpp",
            "VertexBuffer.cpp",
            "View.cpp",
        };
        sfml_graphics.addIncludePath(b.path("include"));
        sfml_graphics.addIncludePath(b.path("src"));
        sfml_graphics.addIncludePath(b.path("extlibs/headers/freetype2"));
        sfml_graphics.addIncludePath(b.path("extlibs/headers/glad/include"));
        sfml_graphics.addIncludePath(b.path("extlibs/headers/stb_image"));
        sfml_graphics.addCSourceFiles(.{
            .root = b.path("src/SFML/Graphics"),
            .files = &sfml_graphics_sources,
        });

        sfml_graphics.linkLibCpp();
        b.installArtifact(sfml_graphics);
    }

    // sfml-network
    // sfml-system
    // sfml-window

    // sfml-main
}
