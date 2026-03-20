use std::ffi::{CStr, CString};
use std::path::Path;

use ruby_prism_sys::{
    pm_arena_free, pm_arena_new, pm_comment_location, pm_comment_type, pm_comment_type_t, pm_diagnostic_location,
    pm_diagnostic_message, pm_parse, pm_parser_comments_each, pm_parser_errors_each, pm_parser_free, pm_parser_new,
};

unsafe extern "C" fn collect_comment(comment: *const ruby_prism_sys::pm_comment_t, data: *mut std::ffi::c_void) {
    let vec = &mut *(data.cast::<Vec<*const ruby_prism_sys::pm_comment_t>>());
    vec.push(comment);
}

unsafe extern "C" fn collect_diagnostic(
    diagnostic: *const ruby_prism_sys::pm_diagnostic_t,
    data: *mut std::ffi::c_void,
) {
    let vec = &mut *(data.cast::<Vec<*const ruby_prism_sys::pm_diagnostic_t>>());
    vec.push(diagnostic);
}

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

        let mut comments: Vec<*const ruby_prism_sys::pm_comment_t> = Vec::new();
        pm_parser_comments_each(parser, Some(collect_comment), (&raw mut comments).cast());

        assert_eq!(comments.len(), 1);
        let comment = comments[0];
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

        let mut errors: Vec<*const ruby_prism_sys::pm_diagnostic_t> = Vec::new();
        pm_parser_errors_each(parser, Some(collect_diagnostic), (&raw mut errors).cast());

        assert!(!errors.is_empty());
        let error = errors[0];

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
