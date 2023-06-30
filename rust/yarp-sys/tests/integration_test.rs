use core::slice;
use std::ptr;

use yarp_sys::{yp_buffer_init, yp_parse, yp_parser_init, yp_prettyprint, Buffer, Parser};

#[test]
fn test_prettyprint() {
    unsafe {
        let s = b":hello_world";

        let mut buffer = Buffer::default();
        yp_buffer_init(&mut buffer);

        let mut parser = Parser::default();
        yp_parser_init(&mut parser, s.as_ptr() as _, s.len(), ptr::null());

        let node = yp_parse(&mut parser);
        yp_prettyprint(&mut parser, node, &mut buffer);

        let result = slice::from_raw_parts(buffer.value as *mut u8, buffer.length);
        let result = std::str::from_utf8_unchecked(result);

        assert_eq!(
            "ProgramNode(, StatementsNode(SymbolNode([0000-0001], [0001-0012], nil, \"hello_world\")))",
            result
        );
    }
}
