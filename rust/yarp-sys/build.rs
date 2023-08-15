use std::path::{Path, PathBuf};

fn main() {
    let ruby_build_path = ruby_build_path();
    let ruby_include_path = ruby_include_path();

    // Tell cargo/rustc that we want to link against `librubyparser.a`.
    println!("cargo:rustc-link-lib=static=rubyparser");

    // Add `[root]/build/` to the search paths, so it can find `librubyparser.a`.
    println!(
        "cargo:rustc-link-search=native={}",
        ruby_build_path.to_str().unwrap()
    );

    // This is where the magic happens.
    let bindings = generate_bindings(&ruby_include_path);

    // Write the bindings to file.
    write_bindngs(&bindings);
}

/// Gets the path to project files (`librubyparser*`) at `[root]/build/`.
///
fn ruby_build_path() -> PathBuf {
    cargo_manifest_path()
        .join("../../build/")
        .canonicalize()
        .unwrap()
}

/// Gets the path to the header files that `bindgen` needs for doing code generation.
///
fn ruby_include_path() -> PathBuf {
    cargo_manifest_path()
        .join("../../include/")
        .canonicalize()
        .unwrap()
}

fn cargo_manifest_path() -> PathBuf {
    PathBuf::from(std::env::var_os("CARGO_MANIFEST_DIR").unwrap())
}

/// Uses `bindgen` to generate bindings to the C API. Update this to allow new types/functions/etc
/// to be generated (it's allowlisted to only expose functions that'd make sense for public
/// consumption).
///
/// This method only generates code in memory here--it doesn't write it to file.
///
fn generate_bindings(ruby_include_path: &Path) -> bindgen::Bindings {
    bindgen::Builder::default()
        .derive_default(true)
        .generate_block(true)
        .generate_comments(true)
        .header(ruby_include_path.join("yarp/defines.h").to_str().unwrap())
        .header(ruby_include_path.join("yarp.h").to_str().unwrap())
        .clang_arg(format!("-I{}", ruby_include_path.to_str().unwrap()))
        .clang_arg("-fparse-all-comments")
        .impl_debug(true)
        .layout_tests(true)
        .merge_extern_blocks(true)
        .parse_callbacks(Box::new(bindgen::CargoCallbacks))
        .prepend_enum_name(false)
        .size_t_is_usize(true)
        .sort_semantically(true)
        // Structs
        .allowlist_type(r#"^yp_\w+_node_t"#)
        .allowlist_type("yp_buffer_t")
        .allowlist_type("yp_comment_t")
        .allowlist_type("yp_diagnostic_t")
        .allowlist_type("yp_encoding_changed_callback_t")
        .allowlist_type("yp_encoding_decode_callback_t")
        .allowlist_type("yp_memsize_t")
        .allowlist_type("yp_list_t")
        .allowlist_type("yp_node_t")
        .allowlist_type("yp_node_type")
        .allowlist_type("yp_parser_t")
        .allowlist_type("yp_pack_size")
        // TODO: Commenting this because I can't figure out how to get bindgen to generate the
        // inner-unions nicely. Hand-rolling this in src/lib.rs for now.
        // .allowlist_type("yp_string_t")
        .blocklist_type(r#"^yp_string_t\S*"#)
        .allowlist_type("yp_string_list_t")
        .allowlist_type("yp_token_type_t")
        // Enums
        .rustified_non_exhaustive_enum("yp_comment_type_t")
        .rustified_non_exhaustive_enum("yp_context_t")
        .rustified_non_exhaustive_enum("yp_heredoc_indent_t")
        .rustified_non_exhaustive_enum("yp_heredoc_quote_t")
        .rustified_non_exhaustive_enum("yp_lex_mode_t")
        .rustified_non_exhaustive_enum("yp_lex_state_t")
        .rustified_non_exhaustive_enum("yp_node_type")
        .rustified_non_exhaustive_enum("yp_pack_encoding")
        .rustified_non_exhaustive_enum("yp_pack_endian")
        .rustified_non_exhaustive_enum("yp_pack_length_type")
        .rustified_non_exhaustive_enum("yp_pack_result")
        .rustified_non_exhaustive_enum("yp_pack_signed")
        .rustified_non_exhaustive_enum("yp_pack_size")
        .rustified_non_exhaustive_enum("yp_pack_type")
        .rustified_non_exhaustive_enum("yp_pack_variant")
        .rustified_non_exhaustive_enum("yp_token_type")
        .rustified_non_exhaustive_enum("yp_unescape_type_t")
        // Functions
        .allowlist_function("yp_buffer_init")
        .allowlist_function("yp_buffer_free")
        .allowlist_function("yp_node_destroy")
        .allowlist_function("yp_list_empty_p")
        .allowlist_function("yp_list_free")
        .allowlist_function("yp_list_init")
        .allowlist_function("yp_node_memsize")
        .allowlist_function("yp_pack_parse")
        .allowlist_function("yp_parse")
        .allowlist_function("yp_parse_serialize")
        .allowlist_function("yp_parser_free")
        .allowlist_function("yp_parser_init")
        .allowlist_function("yp_parser_register_encoding_changed_callback")
        .allowlist_function("yp_parser_register_encoding_decode_callback")
        .allowlist_function("yp_prettyprint")
        .allowlist_function("yp_regexp_named_capture_group_names")
        .allowlist_function("yp_serialize")
        .allowlist_function("yp_size_to_native")
        .allowlist_function("yp_string_free")
        .allowlist_function("yp_string_length")
        .allowlist_function("yp_string_source")
        .allowlist_function("yp_string_list_init")
        .allowlist_function("yp_string_list_free")
        .allowlist_function("yp_token_type_to_str")
        .allowlist_function("yp_unescape_calculate_difference")
        .allowlist_function("yp_unescape_manipulate_string")
        .allowlist_function("yp_version")
        // Vars
        .allowlist_var(r#"^yp_encoding\S+"#)
        .generate()
        .expect("Unable to generate yarp bindings")
}

/// Write the bindings to the `$OUT_DIR/bindings.rs` file. We'll pull these into the actual library
/// in `src/lib.rs`.
fn write_bindngs(bindings: &bindgen::Bindings) {
    let out_path = PathBuf::from(std::env::var_os("OUT_DIR").unwrap());

    bindings
        .write_to_file(out_path.join("bindings.rs"))
        .expect("Couldn't write bindings!");
}
