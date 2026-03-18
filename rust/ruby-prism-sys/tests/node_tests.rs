use std::ffi::CString;

use ruby_prism_sys::{pm_arena_free, pm_arena_new, pm_node_type};
use ruby_prism_sys::{pm_parse, pm_parser_free, pm_parser_new};

#[test]
fn node_test() {
    let code = CString::new("class Foo; end").unwrap();

    unsafe {
        let arena = pm_arena_new();
        let parser = pm_parser_new(
            arena,
            code.as_ptr().cast::<u8>(),
            code.as_bytes().len(),
            std::ptr::null(),
        );
        let node = pm_parse(parser);

        assert_eq!((*node).type_, pm_node_type::PM_PROGRAM_NODE as u16);

        pm_parser_free(parser);
        pm_arena_free(arena);
    }
}
