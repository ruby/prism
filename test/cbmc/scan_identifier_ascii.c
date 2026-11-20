/*
 * Bounded model checking harness for the SWAR implementation of
 * scan_identifier_ascii in src/prism.c.
 *
 * Run via `make test-cbmc` or:
 *   cbmc -DPRISM_ACCEL_SWAR -Iinclude --unwind 17 --unwinding-assertions \
 *     test/cbmc/scan_identifier_ascii.c
 *
 * Checking all lengths 0..16 exercises tail-only inputs (< 8 bytes), a single
 * 8-byte SWAR chunk plus a 0..7 byte tail, and two consecutive chunks (loop
 * continuation). Because each SWAR iteration carries no state other than
 * advancing cursor += 8, verifying 0..16 bytes establishes the contract
 * inductively for arbitrary buffer lengths.
 */

#include <stdint.h>
#include <unistd.h>

extern uint8_t nondet_uint8_t(void);
extern size_t nondet_size_t(void);

#ifndef __CPROVER__
#error "scan_identifier_ascii.c must be run under CBMC (e.g. make test-cbmc)"
#endif

#include <assert.h>
#include <stddef.h>
#include <stdint.h>

#include "../../src/prism.c"

#ifndef PRISM_HAS_SWAR
#error "scan_identifier_ascii.c requires PRISM_HAS_SWAR (pass -DPRISM_ACCEL_SWAR)"
#endif

static int
is_ascii_ident(uint8_t c) {
    return (c == '_') ||
           (c >= '0' && c <= '9') ||
           (c >= 'A' && c <= 'Z') ||
           (c >= 'a' && c <= 'z');
}

static size_t
ascii_ident_end(const uint8_t *start, const uint8_t *end, size_t initial) {
    size_t idx = initial;
    size_t len = (size_t) (end - start);
    while (idx < len && is_ascii_ident(start[idx])) {
        idx++;
    }
    return idx;
}

/*
 * Verify that scan_identifier_ascii's return count `scanned` satisfies the
 * contract expected by lex_identifier. Fast paths only process full
 * `chunk_width`-byte blocks, so `scanned` may stop short of `expected` due to
 * remaining identifier bytes outside those chunks (< chunk_width), which the
 * caller's byte-at-a-time fallback loop finishes scanning.
 */
static int
ident_scan_valid(const uint8_t *text, size_t size, size_t scanned, size_t expected, size_t chunk_width) {
    if (scanned > expected) return 0;
    if (chunk_width > 1 && (expected - scanned) >= chunk_width) return 0;
    return ascii_ident_end(text, text + size, scanned) == expected;
}

int
main(void) {
    uint8_t buf[16];
    for (size_t i = 0; i < sizeof(buf); i++) buf[i] = nondet_uint8_t();
    size_t len = nondet_size_t();
    __CPROVER_assume(len <= sizeof(buf));

    size_t expected = ascii_ident_end(buf, buf + len, 0);
    size_t scanned = scan_identifier_ascii(buf, buf + len);

    assert(ident_scan_valid(buf, len, scanned, expected, 8));
    return 0;
}
