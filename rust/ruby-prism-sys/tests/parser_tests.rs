use std::ffi::{CStr, CString};
use std::path::Path;

use ruby_prism_sys::{
    pm_arena_free, pm_arena_new, pm_comment_location, pm_comment_next, pm_comment_type, pm_comment_type_t,
    pm_diagnostic_location, pm_diagnostic_message, pm_diagnostic_next, pm_parse, pm_parser_comments_first,
    pm_parser_errors_first, pm_parser_errors_size, pm_parser_free, pm_parser_new,
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

    unsafe {
        let arena = pm_arena_new();
        let parser = pm_parser_new(arena, source, len, std::ptr::null());

        pm_parser_free(parser);
        pm_arena_free(arena);
    }
}

#[test]
fn comments_test() {
    let source = CString::new("# Meow!").unwrap();

    unsafe {
        let arena = pm_arena_new();
        let parser = pm_parser_new(
            arena,
            source.as_ptr().cast::<u8>(),
            source.as_bytes().len(),
            std::ptr::null(),
        );
        let _node = pm_parse(parser);

        let comment = pm_parser_comments_first(parser);
        assert!(!comment.is_null());
        assert!(pm_comment_next(comment).is_null());
        assert_eq!(pm_comment_type(comment), pm_comment_type_t::PM_COMMENT_INLINE);

        let location = pm_comment_location(comment);
        assert_eq!(location.start..location.start + location.length, 0..7);

        pm_parser_free(parser);
        pm_arena_free(arena);
    }
}

#[test]
fn diagnostics_test() {
    let source = CString::new("class Foo;").unwrap();

    unsafe {
        let arena = pm_arena_new();
        let parser = pm_parser_new(
            arena,
            source.as_ptr().cast::<u8>(),
            source.as_bytes().len(),
            std::ptr::null(),
        );
        let _node = pm_parse(parser);

        let error = pm_parser_errors_first(parser);
        assert!(!error.is_null());

        let mut count = 0;
        let mut current = error;
        while !current.is_null() {
            count += 1;
            current = pm_diagnostic_next(current);
        }
        assert_eq!(count, pm_parser_errors_size(parser));

        let message = CStr::from_ptr(pm_diagnostic_message(error));
        assert_eq!(
            message.to_string_lossy(),
            "unexpected end-of-input, assuming it is closing the parent top level context"
        );

        let location = pm_diagnostic_location(error);
        assert_eq!(location.start..location.start + location.length, 10..10);

        pm_parser_free(parser);
        pm_arena_free(arena);
    }
}
