use std::{ffi::CString, mem::MaybeUninit};

use yarp_sys::{yp_parser_t, yp_parser_init, yp_parse, yp_parser_free};
use yarp_sys::{yp_node_type, yp_node_destroy};

#[test]
fn node_test() {
    let mut parser = MaybeUninit::<yp_parser_t>::uninit();
    let code = CString::new("class Foo; end").unwrap();

    unsafe {
        yp_parser_init(
            parser.as_mut_ptr(),
            code.as_ptr(),
            code.as_bytes().len(),
            std::ptr::null(),
        );

        let parser = parser.assume_init_mut();
        let parsed_node = yp_parse(parser);

        assert_eq!((*parsed_node).type_, yp_node_type::YP_NODE_PROGRAM_NODE as u16);

        yp_node_destroy(parser, parsed_node);
        yp_parser_free(parser);
    }
}
