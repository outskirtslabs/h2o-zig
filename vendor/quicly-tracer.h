/* Generated from h2o/deps/quicly/quicly-probes.d using:
 * perl h2o/deps/quicly/misc/probe2trace.pl -a tracer < h2o/deps/quicly/quicly-probes.d
 *
 * This file is auto-generated during build by default.
 * To use this vendored version instead, build with: -Duse-vendored-quicly-tracer=true
 */
#ifndef callback_probes_h
#define callback_probes_h


#define QUICLY_TRACER_CONNECT(...)

#define QUICLY_TRACER_ACCEPT(...)

#define QUICLY_TRACER_FREE(...)

#define QUICLY_TRACER_SEND(...)

#define QUICLY_TRACER_RECEIVE(...)

#define QUICLY_TRACER_VERSION_SWITCH(...)

#define QUICLY_TRACER_IDLE_TIMEOUT(...)

#define QUICLY_TRACER_HANDSHAKE_TIMEOUT(...)

#define QUICLY_TRACER_INITIAL_HANDSHAKE_PACKET_EXCEED(...)

#define QUICLY_TRACER_STATELESS_RESET_RECEIVE(...)

#define QUICLY_TRACER_NEW_PATH(...)

#define QUICLY_TRACER_DELETE_PATH(...)

#define QUICLY_TRACER_PROMOTE_PATH(...)

#define QUICLY_TRACER_ELICIT_PATH_MIGRATION(...)

#define QUICLY_TRACER_CRYPTO_HANDSHAKE(...)

#define QUICLY_TRACER_CRYPTO_UPDATE_SECRET(...)

#define QUICLY_TRACER_CRYPTO_SEND_KEY_UPDATE(...)

#define QUICLY_TRACER_CRYPTO_SEND_KEY_UPDATE_CONFIRMED(...)

#define QUICLY_TRACER_CRYPTO_RECEIVE_KEY_UPDATE(...)

#define QUICLY_TRACER_CRYPTO_RECEIVE_KEY_UPDATE_PREPARE(...)

static inline void QUICLY_TRACER_PACKET_SENT(struct st_quicly_conn_t * arg0, int64_t arg1, uint64_t arg2, size_t arg3, uint8_t arg4, int arg5)
{
    if (arg0->super.tracer.cb != NULL)
        arg0->super.tracer.cb(arg0->super.tracer.ctx, "{\"type\":\"packet-sent\", \"time\":%lld, \"pn\":%llu, \"len\":%llu, \"packet-type\":%llu, \"ack-only\":%lld}\n", (long long)arg1, (unsigned long long)arg2, (unsigned long long)arg3, (unsigned long long)arg4, (long long)arg5);
}

static inline void QUICLY_TRACER_PACKET_RECEIVED(struct st_quicly_conn_t * arg0, int64_t arg1, uint64_t arg2, const void * arg3, size_t arg4, uint8_t arg5)
{
    if (arg0->super.tracer.cb != NULL)
        arg0->super.tracer.cb(arg0->super.tracer.ctx, "{\"type\":\"packet-received\", \"time\":%lld, \"pn\":%llu, \"decrypted\":\"0x%llx\", \"decrypted-len\":%llu, \"packet-type\":%llu}\n", (long long)arg1, (unsigned long long)arg2, (unsigned long long)arg3, (unsigned long long)arg4, (unsigned long long)arg5);
}

#define QUICLY_TRACER_PACKET_PREPARE(...)

static inline void QUICLY_TRACER_PACKET_ACKED(struct st_quicly_conn_t * arg0, int64_t arg1, uint64_t arg2, int arg3)
{
    if (arg0->super.tracer.cb != NULL)
        arg0->super.tracer.cb(arg0->super.tracer.ctx, "{\"type\":\"packet-acked\", \"time\":%lld, \"pn\":%llu, \"is-late-ack\":%lld}\n", (long long)arg1, (unsigned long long)arg2, (long long)arg3);
}

static inline void QUICLY_TRACER_PACKET_LOST(struct st_quicly_conn_t * arg0, int64_t arg1, uint64_t arg2, uint8_t arg3)
{
    if (arg0->super.tracer.cb != NULL)
        arg0->super.tracer.cb(arg0->super.tracer.ctx, "{\"type\":\"packet-lost\", \"time\":%lld, \"pn\":%llu, \"packet-type\":%llu}\n", (long long)arg1, (unsigned long long)arg2, (unsigned long long)arg3);
}

static inline void QUICLY_TRACER_PACKET_DECRYPTION_FAILED(struct st_quicly_conn_t * arg0, int64_t arg1, uint64_t arg2)
{
    if (arg0->super.tracer.cb != NULL)
        arg0->super.tracer.cb(arg0->super.tracer.ctx, "{\"type\":\"packet-decryption-failed\", \"time\":%lld, \"pn\":%llu}\n", (long long)arg1, (unsigned long long)arg2);
}

static inline void QUICLY_TRACER_PTO(struct st_quicly_conn_t * arg0, int64_t arg1, size_t arg2, uint32_t arg3, int8_t arg4)
{
    if (arg0->super.tracer.cb != NULL)
        arg0->super.tracer.cb(arg0->super.tracer.ctx, "{\"type\":\"pto\", \"time\":%lld, \"inflight\":%llu, \"cwnd\":%llu, \"pto-count\":%lld}\n", (long long)arg1, (unsigned long long)arg2, (unsigned long long)arg3, (long long)arg4);
}

static inline void QUICLY_TRACER_CC_ACK_RECEIVED(struct st_quicly_conn_t * arg0, int64_t arg1, uint64_t arg2, size_t arg3, uint32_t arg4, size_t arg5)
{
    if (arg0->super.tracer.cb != NULL)
        arg0->super.tracer.cb(arg0->super.tracer.ctx, "{\"type\":\"cc-ack-received\", \"time\":%lld, \"largest-acked\":%llu, \"bytes-acked\":%llu, \"cwnd\":%llu, \"inflight\":%llu}\n", (long long)arg1, (unsigned long long)arg2, (unsigned long long)arg3, (unsigned long long)arg4, (unsigned long long)arg5);
}

static inline void QUICLY_TRACER_CC_CONGESTION(struct st_quicly_conn_t * arg0, int64_t arg1, uint64_t arg2, size_t arg3, uint32_t arg4)
{
    if (arg0->super.tracer.cb != NULL)
        arg0->super.tracer.cb(arg0->super.tracer.ctx, "{\"type\":\"cc-congestion\", \"time\":%lld, \"max-lost-pn\":%llu, \"inflight\":%llu, \"cwnd\":%llu}\n", (long long)arg1, (unsigned long long)arg2, (unsigned long long)arg3, (unsigned long long)arg4);
}

#define QUICLY_TRACER_ACK_BLOCK_RECEIVED(...)

#define QUICLY_TRACER_ACK_DELAY_RECEIVED(...)

#define QUICLY_TRACER_ACK_SEND(...)

#define QUICLY_TRACER_PING_SEND(...)

#define QUICLY_TRACER_PING_RECEIVE(...)

#define QUICLY_TRACER_TRANSPORT_CLOSE_SEND(...)

#define QUICLY_TRACER_TRANSPORT_CLOSE_RECEIVE(...)

#define QUICLY_TRACER_APPLICATION_CLOSE_SEND(...)

#define QUICLY_TRACER_APPLICATION_CLOSE_RECEIVE(...)

#define QUICLY_TRACER_STREAM_SEND(...)

#define QUICLY_TRACER_STREAM_RECEIVE(...)

#define QUICLY_TRACER_STREAM_ACKED(...)

#define QUICLY_TRACER_STREAM_LOST(...)

#define QUICLY_TRACER_RESET_STREAM_SEND(...)

#define QUICLY_TRACER_RESET_STREAM_RECEIVE(...)

#define QUICLY_TRACER_STOP_SENDING_SEND(...)

#define QUICLY_TRACER_STOP_SENDING_RECEIVE(...)

static inline void QUICLY_TRACER_MAX_DATA_SEND(struct st_quicly_conn_t * arg0, int64_t arg1, uint64_t arg2)
{
    if (arg0->super.tracer.cb != NULL)
        arg0->super.tracer.cb(arg0->super.tracer.ctx, "{\"type\":\"max-data-send\", \"time\":%lld, \"maximum\":%llu}\n", (long long)arg1, (unsigned long long)arg2);
}

static inline void QUICLY_TRACER_MAX_DATA_RECEIVE(struct st_quicly_conn_t * arg0, int64_t arg1, uint64_t arg2)
{
    if (arg0->super.tracer.cb != NULL)
        arg0->super.tracer.cb(arg0->super.tracer.ctx, "{\"type\":\"max-data-receive\", \"time\":%lld, \"maximum\":%llu}\n", (long long)arg1, (unsigned long long)arg2);
}

#define QUICLY_TRACER_MAX_STREAMS_SEND(...)

#define QUICLY_TRACER_MAX_STREAMS_RECEIVE(...)

static inline void QUICLY_TRACER_MAX_STREAM_DATA_SEND(struct st_quicly_conn_t * arg0, int64_t arg1, struct st_quicly_stream_t * arg2, uint64_t arg3)
{
    if (arg0->super.tracer.cb != NULL)
        arg0->super.tracer.cb(arg0->super.tracer.ctx, "{\"type\":\"max-stream-data-send\", \"time\":%lld, \"stream-id\":%d, \"maximum\":%llu}\n", (long long)arg1, (int)arg2->stream_id, (unsigned long long)arg3);
}

static inline void QUICLY_TRACER_MAX_STREAM_DATA_RECEIVE(struct st_quicly_conn_t * arg0, int64_t arg1, int64_t arg2, uint64_t arg3)
{
    if (arg0->super.tracer.cb != NULL)
        arg0->super.tracer.cb(arg0->super.tracer.ctx, "{\"type\":\"max-stream-data-receive\", \"time\":%lld, \"stream-id\":%lld, \"maximum\":%llu}\n", (long long)arg1, (long long)arg2, (unsigned long long)arg3);
}

#define QUICLY_TRACER_NEW_TOKEN_SEND(...)

#define QUICLY_TRACER_NEW_TOKEN_ACKED(...)

#define QUICLY_TRACER_NEW_TOKEN_RECEIVE(...)

#define QUICLY_TRACER_HANDSHAKE_DONE_SEND(...)

#define QUICLY_TRACER_HANDSHAKE_DONE_RECEIVE(...)

static inline void QUICLY_TRACER_STREAMS_BLOCKED_SEND(struct st_quicly_conn_t * arg0, int64_t arg1, uint64_t arg2, int arg3)
{
    if (arg0->super.tracer.cb != NULL)
        arg0->super.tracer.cb(arg0->super.tracer.ctx, "{\"type\":\"streams-blocked-send\", \"time\":%lld, \"maximum\":%llu, \"is-unidirectional\":%lld}\n", (long long)arg1, (unsigned long long)arg2, (long long)arg3);
}

static inline void QUICLY_TRACER_STREAMS_BLOCKED_RECEIVE(struct st_quicly_conn_t * arg0, int64_t arg1, uint64_t arg2, int arg3)
{
    if (arg0->super.tracer.cb != NULL)
        arg0->super.tracer.cb(arg0->super.tracer.ctx, "{\"type\":\"streams-blocked-receive\", \"time\":%lld, \"maximum\":%llu, \"is-unidirectional\":%lld}\n", (long long)arg1, (unsigned long long)arg2, (long long)arg3);
}

#define QUICLY_TRACER_NEW_CONNECTION_ID_SEND(...)

#define QUICLY_TRACER_NEW_CONNECTION_ID_RECEIVE(...)

#define QUICLY_TRACER_RETIRE_CONNECTION_ID_SEND(...)

#define QUICLY_TRACER_RETIRE_CONNECTION_ID_RECEIVE(...)

#define QUICLY_TRACER_DATA_BLOCKED_SEND(...)

#define QUICLY_TRACER_DATA_BLOCKED_RECEIVE(...)

#define QUICLY_TRACER_STREAM_DATA_BLOCKED_SEND(...)

#define QUICLY_TRACER_STREAM_DATA_BLOCKED_RECEIVE(...)

#define QUICLY_TRACER_ECN_VALIDATION(...)

#define QUICLY_TRACER_ECN_CONGESTION(...)

#define QUICLY_TRACER_PATH_CHALLENGE_SEND(...)

#define QUICLY_TRACER_PATH_CHALLENGE_RECEIVE(...)

#define QUICLY_TRACER_PATH_RESPONSE_SEND(...)

#define QUICLY_TRACER_PATH_RESPONSE_RECEIVE(...)

#define QUICLY_TRACER_DATAGRAM_SEND(...)

#define QUICLY_TRACER_DATAGRAM_RECEIVE(...)

#define QUICLY_TRACER_ACK_FREQUENCY_RECEIVE(...)

#define QUICLY_TRACER_QUICTRACE_SEND_STREAM(...)

#define QUICLY_TRACER_QUICTRACE_RECV_STREAM(...)

static inline void QUICLY_TRACER_QUICTRACE_CC_ACK(struct st_quicly_conn_t * arg0, int64_t arg1, struct quicly_rtt_t * arg2, uint32_t arg3, size_t arg4)
{
    if (arg0->super.tracer.cb != NULL)
        arg0->super.tracer.cb(arg0->super.tracer.ctx, "{\"type\":\"quictrace-cc-ack\", \"time\":%lld, \"min-rtt\":%u, \"smoothed-rtt\":%u, \"latest-rtt\":%u, \"cwnd\":%llu, \"inflight\":%llu}\n", (long long)arg1, arg2->minimum, arg2->smoothed, arg2->latest, (unsigned long long)arg3, (unsigned long long)arg4);
}

static inline void QUICLY_TRACER_QUICTRACE_CC_LOST(struct st_quicly_conn_t * arg0, int64_t arg1, struct quicly_rtt_t * arg2, uint32_t arg3, size_t arg4)
{
    if (arg0->super.tracer.cb != NULL)
        arg0->super.tracer.cb(arg0->super.tracer.ctx, "{\"type\":\"quictrace-cc-lost\", \"time\":%lld, \"min-rtt\":%u, \"smoothed-rtt\":%u, \"latest-rtt\":%u, \"cwnd\":%llu, \"inflight\":%llu}\n", (long long)arg1, arg2->minimum, arg2->smoothed, arg2->latest, (unsigned long long)arg3, (unsigned long long)arg4);
}

static inline void QUICLY_TRACER_STREAM_ON_OPEN(struct st_quicly_conn_t * arg0, int64_t arg1, struct st_quicly_stream_t * arg2)
{
    if (arg0->super.tracer.cb != NULL)
        arg0->super.tracer.cb(arg0->super.tracer.ctx, "{\"type\":\"stream-on-open\", \"time\":%lld, \"stream-id\":%d}\n", (long long)arg1, (int)arg2->stream_id);
}

static inline void QUICLY_TRACER_STREAM_ON_DESTROY(struct st_quicly_conn_t * arg0, int64_t arg1, struct st_quicly_stream_t * arg2, int64_t arg3)
{
    if (arg0->super.tracer.cb != NULL)
        arg0->super.tracer.cb(arg0->super.tracer.ctx, "{\"type\":\"stream-on-destroy\", \"time\":%lld, \"stream-id\":%d, \"err\":%lld}\n", (long long)arg1, (int)arg2->stream_id, (long long)arg3);
}

#define QUICLY_TRACER_STREAM_ON_SEND_SHIFT(...)

#define QUICLY_TRACER_STREAM_ON_SEND_EMIT(...)

#define QUICLY_TRACER_STREAM_ON_SEND_STOP(...)

#define QUICLY_TRACER_STREAM_ON_RECEIVE(...)

#define QUICLY_TRACER_STREAM_ON_RECEIVE_RESET(...)

#define QUICLY_TRACER_ENTER_CC_LIMITED(...)

#define QUICLY_TRACER_EXIT_CC_LIMITED(...)

#define QUICLY_TRACER_ENTER_JUMPSTART(...)

#define QUICLY_TRACER_DEBUG_MESSAGE(...)

#define QUICLY_TRACER_CONN_STATS(...)

#endif
