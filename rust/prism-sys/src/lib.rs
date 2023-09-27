//! # prism-sys
//!
//! FFI-bindings for `prism`.
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

#[allow(clippy::all, clippy::pedantic, clippy::cognitive_complexity)]
#[allow(missing_copy_implementations)]
#[allow(missing_docs)]
#[allow(non_camel_case_types)]
#[allow(non_snake_case)]
#[allow(non_upper_case_globals)]
mod bindings {
    // In `build.rs`, we use `bindgen` to generate bindings based on C headers
    // and `librubyparser`. Here is where we pull in those bindings and make
    // them part of our library.
    include!(concat!(env!("OUT_DIR"), "/bindings.rs"));
}

pub use self::bindings::*;
