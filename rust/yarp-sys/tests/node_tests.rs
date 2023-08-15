use std::{ffi::CString, mem::MaybeUninit};

use yarp_sys::{
    yp_memsize_t, yp_node_destroy, yp_node_memsize, yp_node_type, yp_parse, yp_parser_free,
    yp_parser_init, yp_parser_t,
};

#[test]
fn node_test() {
    let mut parser = MaybeUninit::<yp_parser_t>::uninit();
    let code = CString::new("class Foo; end").unwrap();
    let mut memsize = MaybeUninit::<yp_memsize_t>::uninit();

    unsafe {
        yp_parser_init(
            parser.as_mut_ptr(),
            code.as_ptr(),
            code.as_bytes().len(),
            std::ptr::null(),
        );

        let parser = parser.assume_init_mut();
        let parsed_node = yp_parse(parser);

        assert_eq!(
            (*parsed_node).type_,
            yp_node_type::YP_NODE_PROGRAM_NODE as u16
        );

        yp_node_memsize(parsed_node, memsize.as_mut_ptr());
        let memsize = memsize.assume_init();
        assert_eq!(memsize.memsize, 296);
        assert_eq!(memsize.node_count, 4);

        yp_node_destroy(parser, parsed_node);
        yp_parser_free(parser);
    }
}
