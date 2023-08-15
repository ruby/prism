use std::{
    ffi::{c_char, CString},
    mem::MaybeUninit,
    path::Path,
    slice, str,
};

use yarp_sys::{
    yp_buffer_free, yp_buffer_init, yp_buffer_t, yp_node_destroy, yp_parse, yp_parse_serialize,
    yp_parser_free, yp_parser_init, yp_parser_t, yp_serialize,
};

fn ruby_file_contents() -> (CString, usize) {
    let rust_path = Path::new(env!("CARGO_MANIFEST_DIR"));
    let ruby_file_path = rust_path.join("../../lib/yarp.rb").canonicalize().unwrap();
    let file_contents = std::fs::read_to_string(ruby_file_path).unwrap();
    let len = file_contents.len();

    (CString::new(file_contents).unwrap(), len)
}

#[test]
fn serialize_test() {
    let (ruby_file_contents, len) = ruby_file_contents();
    let source = ruby_file_contents.as_ptr();
    let mut parser = MaybeUninit::<yp_parser_t>::uninit();
    let mut buffer = MaybeUninit::<yp_buffer_t>::uninit();

    unsafe {
        yp_parser_init(parser.as_mut_ptr(), source, len, std::ptr::null());
        let parser = parser.assume_init_mut();
        let node = yp_parse(parser);

        assert!(yp_buffer_init(buffer.as_mut_ptr()), "Failed to init buffer");

        let buffer = buffer.assume_init_mut();
        yp_serialize(parser, node, buffer);

        let serialized = std::slice::from_raw_parts(buffer.value.cast::<u8>(), buffer.length);

        assert_eq!(&serialized[0..4], b"YARP");
        assert_eq!(serialized[4..5][0], 0); // YP_VERSION_MAJOR
        assert_eq!(serialized[5..6][0], 6); // YP_VERSION_MINOR
        assert_eq!(serialized[6..7][0], 0); // YP_VERSION_PATCH

        yp_buffer_free(buffer);
        yp_node_destroy(parser, node);
        yp_parser_free(parser);
    }
}

#[test]
fn parse_serialize_test() {
    let (ruby_file_contents, len) = ruby_file_contents();
    let source = ruby_file_contents.as_ptr();
    let mut parser = MaybeUninit::<yp_parser_t>::uninit();
    let mut serialize_buffer = MaybeUninit::<yp_buffer_t>::uninit();
    let mut parse_serialize_buffer = MaybeUninit::<yp_buffer_t>::uninit();

    let serialized = unsafe {
        yp_parser_init(parser.as_mut_ptr(), source, len, std::ptr::null());
        let parser = parser.assume_init_mut();
        let node = yp_parse(parser);

        assert!(
            yp_buffer_init(serialize_buffer.as_mut_ptr()),
            "Failed to init buffer"
        );

        let serialize_buffer = serialize_buffer.assume_init_mut();
        yp_serialize(parser, node, serialize_buffer);

        yp_node_destroy(parser, node);
        yp_parser_free(parser);

        // Can't use String -> CString here because `value` contains nul bytes.
        slice::from_raw_parts(serialize_buffer.value.cast::<u8>(), serialize_buffer.length)
    };

    unsafe {
        assert!(
            yp_buffer_init(parse_serialize_buffer.as_mut_ptr()),
            "Failed to init buffer"
        );

        let parse_serialize_buffer = parse_serialize_buffer.assume_init_mut();
        let metadata = std::ptr::null();

        yp_parse_serialize(
            serialized.as_ptr().cast::<c_char>(),
            serialized.len(),
            parse_serialize_buffer,
            metadata,
        );

        let slice = slice::from_raw_parts(
            parse_serialize_buffer.value.cast::<u8>(),
            parse_serialize_buffer.length,
        );
        let string = str::from_utf8(slice).unwrap();
        assert!(string.starts_with("YARP"));

        yp_buffer_free(serialize_buffer.as_mut_ptr());
        yp_buffer_free(parse_serialize_buffer);
    }
}
