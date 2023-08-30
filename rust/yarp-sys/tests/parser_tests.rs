use std::{
    ffi::{CStr, CString},
    mem::MaybeUninit,
    path::Path,
};

use yarp_sys::{
    yp_comment_t, yp_comment_type_t, yp_diagnostic_t,
    yp_node_destroy, yp_parse, yp_parser_free, yp_parser_init,
    yp_parser_t,
};

fn ruby_file_contents() -> (CString, usize) {
    let rust_path = Path::new(env!("CARGO_MANIFEST_DIR"));
    let ruby_file_path = rust_path.join("../../lib/yarp.rb").canonicalize().unwrap();
    let file_contents = std::fs::read_to_string(ruby_file_path).unwrap();
    let len = file_contents.len();

    (CString::new(file_contents).unwrap(), len)
}

#[test]
fn init_test() {
    let (ruby_file_contents, len) = ruby_file_contents();
    let source = ruby_file_contents.as_ptr().cast::<u8>();
    let mut parser = MaybeUninit::<yp_parser_t>::uninit();

    unsafe {
        yp_parser_init(parser.as_mut_ptr(), source, len, std::ptr::null());
        let parser = parser.assume_init_mut();

        yp_parser_free(parser);
    }
}

#[test]
fn comments_test() {
    let source = CString::new("# Meow!").unwrap();
    let mut parser = MaybeUninit::<yp_parser_t>::uninit();

    unsafe {
        yp_parser_init(
            parser.as_mut_ptr(),
            source.as_ptr().cast::<u8>(),
            source.as_bytes().len(),
            std::ptr::null(),
        );
        let parser = parser.assume_init_mut();
        let node = yp_parse(parser);

        let comment_list = &parser.comment_list;
        let comment = comment_list.head as *const yp_comment_t;
        assert_eq!((*comment).type_, yp_comment_type_t::YP_COMMENT_INLINE);

        let location = {
            let start = (*comment).start.offset_from(parser.start);
            let end = (*comment).end.offset_from(parser.start);
            start..end
        };
        assert_eq!(location, 0..7);

        yp_node_destroy(parser, node);
        yp_parser_free(parser);
    }
}

#[test]
fn diagnostics_test() {
    let source = CString::new("class Foo;").unwrap();
    let mut parser = MaybeUninit::<yp_parser_t>::uninit();

    unsafe {
        yp_parser_init(
            parser.as_mut_ptr(),
            source.as_ptr().cast::<u8>(),
            source.as_bytes().len(),
            std::ptr::null(),
        );
        let parser = parser.assume_init_mut();
        let node = yp_parse(parser);

        let error_list = &parser.error_list;
        assert!(!error_list.head.is_null());

        let error = error_list.head as *const yp_diagnostic_t;
        let message = CStr::from_ptr((*error).message);
        assert_eq!(
            message.to_string_lossy(),
            "Expected to be able to parse an expression."
        );

        let location = {
            let start = (*error).start.offset_from(parser.start);
            let end = (*error).end.offset_from(parser.start);
            start..end
        };
        assert_eq!(location, 10..10);

        yp_node_destroy(parser, node);
        yp_parser_free(parser);
    }
}
