# Local H2O builds and examples

Use a separate CMake build directory for the stateful `h2o/` checkout:

```bash
cd h2o
cmake -G "Unix Makefiles" -B build-local -S . -DDISABLE_LIBUV=ON -DWITH_MRUBY=OFF
cmake --build build-local -j"$(nproc)"
timeout -k 10s 15m cmake --build build-local --target check
```

Use a fresh directory if an existing one uses Ninja: the upstream external picotls/quicly projects default to Makefiles, while their build commands inherit the parent's build tool.

The full upstream integration suite is additional to the required Zig/Nix matrix. Before running it, check its optional prerequisites; the FastCGI tests need `perl -MFCGI -e 1`, which the current devshell does not provide. Record a missing prerequisite as incomplete validation, not a pass.

Run long checks with a bounded timeout and inspect progress regularly. `t/run-tests` buffers each test in `/tmp/<temporary-directory>/t__*.out` until it completes. A quiet main log can hide a failed child process. Inspect the current per-test log and process tree rather than waiting on an idle log; its internal timeout can itself block on inherited log locks. Do not rerun the entire suite to diagnose one stalled test.

## Run upstream examples

Build the built-in-event-loop examples, then run them from `h2o/`; the simple server resolves its certificate and document-root paths relative to that directory.

```bash
cd h2o
cmake --build build-local --target lib-examples-evloop
./build-local/examples-simple-evloop
```

The server listens on `https://127.0.0.1:7890` with a self-signed certificate:

```bash
curl -k https://127.0.0.1:7890/chunked-test
curl -k -d 'test data' https://127.0.0.1:7890/post-test/
```

The target always builds `h2o-httpclient`, `examples-socket-client-evloop`, and `examples-latency-optimization-evloop`; with wslay detected (the dev shell supplies it), it also builds `examples-websocket-evloop`.
