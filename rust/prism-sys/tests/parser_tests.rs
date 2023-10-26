use std::{
    ffi::{CStr, CString},
    mem::MaybeUninit,
    path::Path,
};

use prism_sys::{
    pm_comment_t, pm_comment_type_t, pm_diagnostic_t, pm_node_destroy, pm_parse, pm_parser_free, pm_parser_init,
    pm_parser_t,
};

fn ruby_file_contents() -> (CString, usize) {
    let rust_path = Path::new(env!("CARGO_MANIFEST_DIR"));
    let ruby_file_path = rust_path.join("../../lib/prism.rb").canonicalize().unwrap();
    let file_contents = std::fs::read_to_string(ruby_file_path).unwrap();
    let len = file_contents.len();

    (CString::new(file_contents).unwrap(), len)
}

#[test]
fn init_test() {
    let (ruby_file_contents, len) = ruby_file_contents();
    let source = ruby_file_contents.as_ptr().cast::<u8>();
    let mut parser = MaybeUninit::<pm_parser_t>::uninit();

    unsafe {
        pm_parser_init(parser.as_mut_ptr(), source, len, std::ptr::null());
        let parser = parser.assume_init_mut();

        pm_parser_free(parser);
    }
}

#[test]
fn comments_test() {
    let source = CString::new("# Meow!").unwrap();
    let mut parser = MaybeUninit::<pm_parser_t>::uninit();

    unsafe {
        pm_parser_init(
            parser.as_mut_ptr(),
            source.as_ptr().cast::<u8>(),
            source.as_bytes().len(),
            std::ptr::null(),
        );
        let parser = parser.assume_init_mut();
        let node = pm_parse(parser);

        let comment_list = &parser.comment_list;
        let comment = comment_list.head as *const pm_comment_t;
        assert_eq!((*comment).type_, pm_comment_type_t::PM_COMMENT_INLINE);

        let location = {
            let start = (*comment).start.offset_from(parser.start);
            let end = (*comment).end.offset_from(parser.start);
            start..end
        };
        assert_eq!(location, 0..7);

        pm_node_destroy(parser, node);
        pm_parser_free(parser);
    }
}

#[test]
fn diagnostics_test() {
    let source = CString::new("class Foo;").unwrap();
    let mut parser = MaybeUninit::<pm_parser_t>::uninit();

    unsafe {
        pm_parser_init(
            parser.as_mut_ptr(),
            source.as_ptr().cast::<u8>(),
            source.as_bytes().len(),
            std::ptr::null(),
        );
        let parser = parser.assume_init_mut();
        let node = pm_parse(parser);

        let error_list = &parser.error_list;
        assert!(!error_list.head.is_null());

        let error = error_list.head as *const pm_diagnostic_t;
        let message = CStr::from_ptr((*error).message);
        assert_eq!(message.to_string_lossy(), "Cannot parse the expression");

        let location = {
            let start = (*error).start.offset_from(parser.start);
            let end = (*error).end.offset_from(parser.start);
            start..end
        };
        assert_eq!(location, 10..10);

        pm_node_destroy(parser, node);
        pm_parser_free(parser);
    }
}
