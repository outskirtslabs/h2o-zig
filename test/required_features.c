#include "h2o.h"
#include "h2o/http1.h"
#include "h2o/http2.h"
#include "h2o/http3_server.h"
#include "h2o/websocket.h"
#include "quicly.h"

#if H2O_USE_LIBUV != 0
#error "h2o-zig must use h2o's built-in event loop"
#endif

#if H2O_USE_BROTLI != 1
#error "h2o-zig must enable Brotli compression"
#endif

#if H2O_USE_ZSTD != 1
#error "h2o-zig must enable Zstandard compression"
#endif

#define REQUIRE_SYMBOL(name) static __typeof__(&name) volatile required_##name __attribute__((used)) = &name

REQUIRE_SYMBOL(h2o_http1_accept);
REQUIRE_SYMBOL(h2o_http2_accept);
REQUIRE_SYMBOL(h2o_http3_server_accept);
REQUIRE_SYMBOL(h2o_accept);
REQUIRE_SYMBOL(quicly_connect);
REQUIRE_SYMBOL(quicly_accept);
REQUIRE_SYMBOL(h2o_compress_brotli_open);
REQUIRE_SYMBOL(h2o_compress_zstd_open);
REQUIRE_SYMBOL(h2o_upgrade_to_websocket);

int main(void)
{
    return required_h2o_http1_accept == NULL || required_h2o_http2_accept == NULL ||
           required_h2o_http3_server_accept == NULL || required_h2o_accept == NULL || required_quicly_connect == NULL ||
           required_quicly_accept == NULL || required_h2o_compress_brotli_open == NULL ||
           required_h2o_compress_zstd_open == NULL || required_h2o_upgrade_to_websocket == NULL;
}
