#ifndef PRISM_WASM_TRAP_H
#define PRISM_WASM_TRAP_H

/* Trap on assertion failure to avoid linking the wasi-libc formatter. */
#if !defined(PRISM_ASSERT) && !defined(PRISM_BUILD_DEBUG) && !defined(NDEBUG)
#   define PRISM_ASSERT(expr_) ((expr_) ? (void) 0 : __builtin_trap())
#endif

/* Trap on allocation failure to avoid linking stdio for the OOM message. */
#if !defined(PRISM_OOM) && !defined(PRISM_BUILD_DEBUG)
#   define PRISM_OOM() __builtin_trap()
#endif

#endif
