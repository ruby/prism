//! # yarp-sys
//!
//! FFI-bindings for `yarp`.
//!
#![deny(unused_extern_crates)]
#![warn(
    box_pointers,
    clippy::all,
    clippy::nursery,
    clippy::pedantic,
    future_incompatible,
    missing_copy_implementations,
    missing_docs,
    nonstandard_style,
    rust_2018_idioms,
    trivial_casts,
    trivial_numeric_casts,
    unreachable_pub,
    unused_qualifications
)]

// Allowing because we're not manually defining anything that would cause this, and
// the bindgen-generated `bindgen_test_layout_yp_parser()` triggers this.
#[allow(clippy::cognitive_complexity)]
// Allowing because we're not manually defining anything that would cause this, and
// the following bindgen-generated functions triggers this:
// - `bindgen_test_layout_yp_call_node()`
// - `bindgen_test_layout_yp_def_node()`
// - `bindgen_test_layout_yp_parser()`
#[allow(clippy::too_many_lines)]
#[allow(missing_copy_implementations)]
#[allow(non_upper_case_globals)]
#[allow(non_camel_case_types)]
#[allow(non_snake_case)]
#[allow(missing_docs)]
mod bindings {
    // In `build.rs`, we use `bindgen` to generate bindings based on C headers
    // and `librubyparser`. Here is where we pull in those bindings and make
    // them part of our library.
    include!(concat!(env!("OUT_DIR"), "/bindings.rs"));
}

pub use self::bindings::*;
