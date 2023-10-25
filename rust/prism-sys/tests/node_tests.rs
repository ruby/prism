use std::{ffi::CString, mem::MaybeUninit};

use prism_sys::{pm_node_destroy, pm_node_type};
use prism_sys::{pm_parse, pm_parser_free, pm_parser_init, pm_parser_t};

#[test]
fn node_test() {
    let mut parser = MaybeUninit::<pm_parser_t>::uninit();
    let code = CString::new("class Foo; end").unwrap();

    unsafe {
        pm_parser_init(
            parser.as_mut_ptr(),
            code.as_ptr().cast::<u8>(),
            code.as_bytes().len(),
            std::ptr::null(),
        );

        let parser = parser.assume_init_mut();
        let parsed_node = pm_parse(parser);

        assert_eq!((*parsed_node).type_, pm_node_type::PM_PROGRAM_NODE as u16);

        pm_node_destroy(parser, parsed_node);
        pm_parser_free(parser);
    }
}
