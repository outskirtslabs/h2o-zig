# Local H2O builds and examples

Use a separate CMake build directory for the stateful `h2o/` checkout:

```bash
cd h2o
cmake -G Ninja -B build-local -S . -DDISABLE_LIBUV=ON -DWITH_MRUBY=OFF
cmake --build build-local -j"$(nproc)"
cmake --build build-local --target check
```

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
