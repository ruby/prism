#[cfg(feature = "vendored")]
mod vendored;

use std::path::{Path, PathBuf};

fn main() {
    #[cfg(feature = "vendored")]
    vendored::build().expect("failed to build Prism from source");

    let ruby_build_path = prism_lib_path();
    let ruby_include_path = prism_include_path();

    // Tell cargo/rustc that we want to link against `librubyparser.a`.
    println!("cargo:rustc-link-lib=static=rubyparser");

    // Add `[root]/build/` to the search paths, so it can find `librubyparser.a`.
    println!("cargo:rustc-link-search=native={}", ruby_build_path.to_str().unwrap());

    // This is where the magic happens.
    let bindings = generate_bindings(&ruby_include_path);

    // Write the bindings to file.
    write_bindings(&bindings);
}

/// Gets the path to project files (`librubyparser*`) at `[root]/build/`.
///
fn prism_lib_path() -> PathBuf {
    if let Ok(lib_dir) = std::env::var("PRISM_LIB_DIR") {
        return PathBuf::from(lib_dir);
    }

    cargo_manifest_path().join("../../build/").canonicalize().unwrap()
}

/// Gets the path to the header files that `bindgen` needs for doing code
/// generation.
///
fn prism_include_path() -> PathBuf {
    if let Ok(include_dir) = std::env::var("PRISM_INCLUDE_DIR") {
        return PathBuf::from(include_dir);
    }

    cargo_manifest_path().join("../../include/").canonicalize().unwrap()
}

fn cargo_manifest_path() -> PathBuf {
    PathBuf::from(std::env::var_os("CARGO_MANIFEST_DIR").unwrap())
}

/// Uses `bindgen` to generate bindings to the C API. Update this to allow new
/// types/functions/etc to be generated (it's allowlisted to only expose
/// functions that'd make sense for public consumption).
///
/// This method only generates code in memory here--it doesn't write it to file.
///
fn generate_bindings(ruby_include_path: &Path) -> bindgen::Bindings {
    bindgen::Builder::default()
        .derive_default(true)
        .generate_block(true)
        .generate_comments(true)
        .header(ruby_include_path.join("prism/defines.h").to_str().unwrap())
        .header(ruby_include_path.join("prism.h").to_str().unwrap())
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
        .allowlist_type("pm_comment_t")
        .allowlist_type("pm_diagnostic_t")
        .allowlist_type("pm_list_t")
        .allowlist_type("pm_node_t")
        .allowlist_type("pm_node_type")
        .allowlist_type("pm_pack_size")
        .allowlist_type("pm_parser_t")
        .allowlist_type("pm_string_t")
        .allowlist_type(r"^pm_\w+_node_t")
        .allowlist_type(r"^pm_\w+_flags")
        // Enums
        .rustified_non_exhaustive_enum("pm_comment_type_t")
        .rustified_non_exhaustive_enum(r"pm_\w+_flags")
        .rustified_non_exhaustive_enum("pm_node_type")
        .rustified_non_exhaustive_enum("pm_pack_encoding")
        .rustified_non_exhaustive_enum("pm_pack_endian")
        .rustified_non_exhaustive_enum("pm_pack_length_type")
        .rustified_non_exhaustive_enum("pm_pack_result")
        .rustified_non_exhaustive_enum("pm_pack_signed")
        .rustified_non_exhaustive_enum("pm_pack_size")
        .rustified_non_exhaustive_enum("pm_pack_type")
        .rustified_non_exhaustive_enum("pm_pack_variant")
        // Functions
        .allowlist_function("pm_list_empty_p")
        .allowlist_function("pm_list_free")
        .allowlist_function("pm_node_destroy")
        .allowlist_function("pm_pack_parse")
        .allowlist_function("pm_parse")
        .allowlist_function("pm_parser_free")
        .allowlist_function("pm_parser_init")
        .allowlist_function("pm_size_to_native")
        .allowlist_function("pm_string_free")
        .allowlist_function("pm_string_length")
        .allowlist_function("pm_string_source")
        .allowlist_function("pm_version")
        // Vars
        .allowlist_var(r"^pm_encoding\S+")
        .generate()
        .expect("Unable to generate prism bindings")
}

/// Write the bindings to the `$OUT_DIR/bindings.rs` file. We'll pull these into
/// the actual library in `src/lib.rs`.
fn write_bindings(bindings: &bindgen::Bindings) {
    let out_path = PathBuf::from(std::env::var_os("OUT_DIR").unwrap());

    bindings
        .write_to_file(out_path.join("bindings.rs"))
        .expect("Couldn't write bindings!");
}
