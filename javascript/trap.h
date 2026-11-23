/* Trap on assertion failure to avoid linking the wasi-libc formatter. */
#if !defined(PRISM_ASSERT) && !defined(PRISM_BUILD_DEBUG) && !defined(NDEBUG)
#   define PRISM_ASSERT(expr_) ((expr_) ? (void) 0 : __builtin_trap())
#endif
