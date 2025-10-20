const std = @import("std");

pub fn build(b: *std.Build) void {
    const use_boringssl = b.option(bool, "use-boringssl", "Use BoringSSL instead of OpenSSL (default: false)") orelse false;
    const use_external_brotli = b.option(bool, "use-external-brotli", "Use external brotli Zig dependency instead of vendored sources (default: false)") orelse false;
    const use_vendored_tracer = b.option(bool, "use-vendored-quicly-tracer", "Use vendored quicly-tracer.h instead of generating from quicly-probes.d (default: true)") orelse true;

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const needs_pic = true;

    const is_linux = target.result.os.tag == .linux;
    const is_macos_cross = target.result.os.tag == .macos and @import("builtin").os.tag != .macos;

    const h2o_dep = b.dependency("h2o", .{});
    const zlib = b.dependency("zlib", .{
        .target = target,
        .optimize = optimize,
        .pie = needs_pic,
    });
    const zstd = b.dependency("zstd", .{
        .target = target,
        .optimize = optimize,
        .pie = needs_pic,
    });

    const h2o = b.addLibrary(.{
        .name = "h2o-evloop",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
        }),
        .linkage = .dynamic,
    });

    if (is_macos_cross) {
        const sdk_path = b.graph.env_map.get("APPLE_SDK_PATH") orelse
            @panic("Cross-compiling to macOS requires APPLE_SDK_PATH environment variable");
        var sdk_include_buf: [1024]u8 = undefined;
        const sdk_include = std.fmt.bufPrint(&sdk_include_buf, "{s}/usr/include", .{sdk_path}) catch unreachable;
        h2o.addSystemIncludePath(.{ .cwd_relative = sdk_include });
    }

    h2o.addIncludePath(h2o_dep.path("include"));
    h2o.addIncludePath(h2o_dep.path("deps/cloexec"));
    if (!use_external_brotli) {
        h2o.addIncludePath(h2o_dep.path("deps/brotli/c/include"));
    }
    h2o.addIncludePath(h2o_dep.path("deps/golombset"));
    h2o.addIncludePath(h2o_dep.path("deps/hiredis"));
    h2o.addIncludePath(h2o_dep.path("deps/libgkc"));
    h2o.addIncludePath(h2o_dep.path("deps/libyrmcds"));
    h2o.addIncludePath(h2o_dep.path("deps/klib"));
    h2o.addIncludePath(h2o_dep.path("deps/neverbleed"));
    h2o.addIncludePath(h2o_dep.path("deps/picohttpparser"));
    h2o.addIncludePath(h2o_dep.path("deps/picotest"));
    h2o.addIncludePath(h2o_dep.path("deps/picotls/deps/cifra/src/ext"));
    h2o.addIncludePath(h2o_dep.path("deps/picotls/deps/cifra/src"));
    h2o.addIncludePath(h2o_dep.path("deps/picotls/deps/micro-ecc"));
    h2o.addIncludePath(h2o_dep.path("deps/picotls/include"));
    h2o.addIncludePath(h2o_dep.path("deps/quicly/include"));
    h2o.addIncludePath(h2o_dep.path("deps/yaml/include"));
    h2o.addIncludePath(h2o_dep.path("deps/yoml"));

    if (use_boringssl) {
        if (b.lazyDependency("boringssl", .{
            .target = target,
            .optimize = optimize,
        })) |boringssl| {
            h2o.linkLibrary(boringssl.artifact("bcm"));
            h2o.linkLibrary(boringssl.artifact("crypto"));
            h2o.linkLibrary(boringssl.artifact("ssl"));
            h2o.linkLibrary(boringssl.artifact("decrepit"));
        }
    } else {
        if (b.lazyDependency("openssl", .{
            .target = target,
            .optimize = optimize,
        })) |openssl| {
            const ssl_artifact = openssl.artifact("ssl");
            const crypto_artifact = openssl.artifact("crypto");
            if (is_macos_cross) {
                const sdk_path = b.graph.env_map.get("APPLE_SDK_PATH") orelse
                    @panic("Cross-compiling to macOS requires APPLE_SDK_PATH environment variable");
                var sdk_include_buf: [1024]u8 = undefined;
                const sdk_include = std.fmt.bufPrint(&sdk_include_buf, "{s}/usr/include", .{sdk_path}) catch unreachable;

                ssl_artifact.addSystemIncludePath(.{ .cwd_relative = sdk_include });
                crypto_artifact.addSystemIncludePath(.{ .cwd_relative = sdk_include });
            }
            h2o.linkLibrary(ssl_artifact);
            h2o.linkLibrary(crypto_artifact);
        }
    }
    h2o.linkLibrary(zlib.artifact("z"));
    h2o.linkLibrary(zstd.artifact("zstd"));
    if (use_external_brotli) {
        if (b.lazyDependency("brotli_build", .{
            .target = target,
            .optimize = optimize,
            .pie = needs_pic,
        })) |brotli| {
            h2o.linkLibrary(brotli.artifact("brotli_lib"));
        }
    }

    const base_cflags = [_][]const u8{
        "-std=gnu99",
        "-Wall",
        "-Wno-unused-value",
        "-Wno-unused-function",
        "-DH2O_USE_LIBUV=0",
        "-DH2O_USE_BROTLI=1",
        "-DQUICLY_USE_TRACER=1",
    };

    // Build cflags dynamically based on target
    // NOTE: On Linux, we define _GNU_SOURCE (needed for splice, recvmmsg, etc) but
    // undefine __gnu_linux__ because Zig defines it with musl libc. h2o's musl
    // support (PR #3118) uses `!(defined(_GNU_SOURCE) && defined(__gnu_linux__))`
    // to detect musl, so we must undefine __gnu_linux__ for the detection to work.
    var cflags_list = std.ArrayList([]const u8).initCapacity(b.allocator, base_cflags.len + 3) catch unreachable;
    defer cflags_list.deinit(b.allocator);

    cflags_list.appendSlice(b.allocator, &base_cflags) catch unreachable;

    if (is_linux) {
        cflags_list.append(b.allocator, "-D_GNU_SOURCE") catch unreachable;
        cflags_list.append(b.allocator, "-U__gnu_linux__") catch unreachable;
    }

    if (needs_pic) {
        cflags_list.append(b.allocator, "-fPIC") catch unreachable;
    }

    const cflags_slice = cflags_list.toOwnedSlice(b.allocator) catch unreachable;

    const yaml_sources = [_][]const u8{
        "deps/yaml/src/api.c",
        "deps/yaml/src/dumper.c",
        "deps/yaml/src/emitter.c",
        "deps/yaml/src/loader.c",
        "deps/yaml/src/parser.c",
        "deps/yaml/src/reader.c",
        "deps/yaml/src/scanner.c",
        "deps/yaml/src/writer.c",
    };

    const brotli_sources_external = [_][]const u8{
        "lib/handler/compress/brotli.c",
    };
    const brotli_sources_vendored = [_][]const u8{
        "deps/brotli/c/common/dictionary.c",
        "deps/brotli/c/dec/bit_reader.c",
        "deps/brotli/c/dec/decode.c",
        "deps/brotli/c/dec/huffman.c",
        "deps/brotli/c/dec/state.c",
        "deps/brotli/c/enc/backward_references.c",
        "deps/brotli/c/enc/backward_references_hq.c",
        "deps/brotli/c/enc/bit_cost.c",
        "deps/brotli/c/enc/block_splitter.c",
        "deps/brotli/c/enc/brotli_bit_stream.c",
        "deps/brotli/c/enc/cluster.c",
        "deps/brotli/c/enc/compress_fragment.c",
        "deps/brotli/c/enc/compress_fragment_two_pass.c",
        "deps/brotli/c/enc/dictionary_hash.c",
        "deps/brotli/c/enc/encode.c",
        "deps/brotli/c/enc/entropy_encode.c",
        "deps/brotli/c/enc/histogram.c",
        "deps/brotli/c/enc/literal_cost.c",
        "deps/brotli/c/enc/memory.c",
        "deps/brotli/c/enc/metablock.c",
        "deps/brotli/c/enc/static_dict.c",
        "deps/brotli/c/enc/utf8_util.c",
        "lib/handler/compress/brotli.c",
    };
    const brotli_sources = if (use_external_brotli) &brotli_sources_external else &brotli_sources_vendored;

    const lib_sources = [_][]const u8{
        "deps/cloexec/cloexec.c",
        "deps/hiredis/async.c",
        "deps/hiredis/hiredis.c",
        "deps/hiredis/net.c",
        "deps/hiredis/read.c",
        "deps/hiredis/sds.c",
        "deps/hiredis/alloc.c",
        "deps/libgkc/gkc.c",
        "deps/libyrmcds/close.c",
        "deps/libyrmcds/connect.c",
        "deps/libyrmcds/recv.c",
        "deps/libyrmcds/send.c",
        "deps/libyrmcds/send_text.c",
        "deps/libyrmcds/socket.c",
        "deps/libyrmcds/strerror.c",
        "deps/libyrmcds/text_mode.c",
        "deps/picohttpparser/picohttpparser.c",
        "deps/picotls/deps/cifra/src/blockwise.c",
        "deps/picotls/deps/cifra/src/chash.c",
        "deps/picotls/deps/cifra/src/curve25519.c",
        "deps/picotls/deps/cifra/src/drbg.c",
        "deps/picotls/deps/cifra/src/hmac.c",
        "deps/picotls/deps/cifra/src/sha256.c",
        "deps/picotls/lib/certificate_compression.c",
        "deps/picotls/lib/hpke.c",
        "deps/picotls/lib/pembase64.c",
        "deps/picotls/lib/picotls.c",
        "deps/picotls/lib/openssl.c",
        "deps/picotls/lib/cifra/random.c",
        "deps/picotls/lib/cifra/x25519.c",
        "deps/quicly/lib/cc-cubic.c",
        "deps/quicly/lib/cc-pico.c",
        "deps/quicly/lib/cc-reno.c",
        "deps/quicly/lib/defaults.c",
        "deps/quicly/lib/frame.c",
        "deps/quicly/lib/local_cid.c",
        "deps/quicly/lib/loss.c",
        "deps/quicly/lib/quicly.c",
        "deps/quicly/lib/ranges.c",
        "deps/quicly/lib/rate.c",
        "deps/quicly/lib/recvstate.c",
        "deps/quicly/lib/remote_cid.c",
        "deps/quicly/lib/sendstate.c",
        "deps/quicly/lib/sentmap.c",
        "deps/quicly/lib/streambuf.c",
        "lib/common/cache.c",
        "lib/common/file.c",
        "lib/common/filecache.c",
        "lib/common/hostinfo.c",
        "lib/common/http1client.c",
        "lib/common/http2client.c",
        "lib/common/http3client.c",
        "lib/common/httpclient.c",
        "lib/common/memcached.c",
        "lib/common/memory.c",
        "lib/common/multithread.c",
        "lib/common/redis.c",
        "lib/common/serverutil.c",
        "lib/common/socket.c",
        "lib/common/socketpool.c",
        "lib/common/string.c",
        "lib/common/rand.c",
        "lib/common/time.c",
        "lib/common/timerwheel.c",
        "lib/common/token.c",
        "lib/common/url.c",
        "lib/common/balancer/roundrobin.c",
        "lib/common/balancer/least_conn.c",
        "lib/common/absprio.c",
        "lib/core/config.c",
        "lib/core/configurator.c",
        "lib/core/context.c",
        "lib/core/headers.c",
        "lib/core/logconf.c",
        "lib/core/pipe_sender.c",
        "lib/core/proxy.c",
        "lib/core/request.c",
        "lib/core/util.c",
        "lib/handler/access_log.c",
        "lib/handler/compress.c",
        "lib/handler/compress/gzip.c",
        "lib/handler/errordoc.c",
        "lib/handler/expires.c",
        "lib/handler/fastcgi.c",
        "lib/handler/file.c",
        "lib/handler/h2olog.c",
        "lib/handler/headers.c",
        "lib/handler/headers_util.c",
        "lib/handler/http2_debug_state.c",
        "lib/handler/mimemap.c",
        "lib/handler/proxy.c",
        "lib/handler/connect.c",
        "lib/handler/redirect.c",
        "lib/handler/reproxy.c",
        "lib/handler/throttle_resp.c",
        "lib/handler/self_trace.c",
        "lib/handler/server_timing.c",
        "lib/handler/status.c",
        "lib/handler/status/events.c",
        "lib/handler/status/memory.c",
        "lib/handler/status/requests.c",
        "lib/handler/status/ssl.c",
        "lib/handler/status/durations.c",
        "lib/handler/configurator/access_log.c",
        "lib/handler/configurator/compress.c",
        "lib/handler/configurator/errordoc.c",
        "lib/handler/configurator/expires.c",
        "lib/handler/configurator/fastcgi.c",
        "lib/handler/configurator/file.c",
        "lib/handler/configurator/h2olog.c",
        "lib/handler/configurator/headers.c",
        "lib/handler/configurator/headers_util.c",
        "lib/handler/configurator/http2_debug_state.c",
        "lib/handler/configurator/proxy.c",
        "lib/handler/configurator/redirect.c",
        "lib/handler/configurator/reproxy.c",
        "lib/handler/configurator/throttle_resp.c",
        "lib/handler/configurator/self_trace.c",
        "lib/handler/configurator/server_timing.c",
        "lib/handler/configurator/status.c",
        "lib/http1.c",
        "lib/http2/cache_digests.c",
        "lib/http2/casper.c",
        "lib/http2/connection.c",
        "lib/http2/frame.c",
        "lib/http2/hpack.c",
        "lib/http2/scheduler.c",
        "lib/http2/stream.c",
        "lib/http2/http2_debug_state.c",
        "lib/http3/frame.c",
        "lib/http3/qpack.c",
        "lib/http3/common.c",
        "lib/http3/server.c",
    };

    for (yaml_sources) |src| {
        h2o.addCSourceFile(.{ .file = h2o_dep.path(src), .flags = cflags_slice });
    }
    for (brotli_sources) |src| {
        h2o.addCSourceFile(.{ .file = h2o_dep.path(src), .flags = cflags_slice });
    }
    for (lib_sources) |src| {
        h2o.addCSourceFile(.{ .file = h2o_dep.path(src), .flags = cflags_slice });
    }

    h2o.linkLibC();
    h2o.linkSystemLibrary("pthread");
    h2o.linkSystemLibrary("dl");
    h2o.linkSystemLibrary("m");

    b.installArtifact(h2o);

    h2o.installHeader(h2o_dep.path("include/h2o.h"), "h2o.h");
    h2o.installHeadersDirectory(h2o_dep.path("include/h2o"), "h2o", .{});

    h2o.installHeader(h2o_dep.path("deps/picotls/include/picotls.h"), "picotls.h");
    h2o.installHeadersDirectory(h2o_dep.path("deps/picotls/include/picotls"), "picotls", .{});

    h2o.installHeader(h2o_dep.path("deps/quicly/include/quicly.h"), "quicly.h");
    h2o.installHeadersDirectory(h2o_dep.path("deps/quicly/include/quicly"), "quicly", .{});

    const quicly_tracer_header = if (use_vendored_tracer) blk: {
        h2o.addIncludePath(b.path("vendor"));
        break :blk b.path("vendor/quicly-tracer.h");
    } else blk: {
        const gen_tracer = b.addSystemCommand(&[_][]const u8{
            "perl",
            h2o_dep.path("deps/quicly/misc/probe2trace.pl").getPath(b),
            "-a",
            "tracer",
        });
        gen_tracer.setStdIn(.{ .lazy_path = h2o_dep.path("deps/quicly/quicly-probes.d") });
        const generated_header = gen_tracer.captureStdOut();
        const write_files = b.addWriteFiles();
        const tracer_header_in_cache = write_files.addCopyFile(generated_header, "quicly-tracer.h");
        h2o.addIncludePath(write_files.getDirectory());
        h2o.step.dependOn(&write_files.step);

        break :blk tracer_header_in_cache;
    };

    h2o.installHeader(quicly_tracer_header, "quicly/quicly-tracer.h");
}
