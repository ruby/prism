//! Diagnostic handling for parse errors and warnings.

use std::ffi::{c_char, CStr};
use std::marker::PhantomData;
use std::ptr::NonNull;

use ruby_prism_sys::{pm_diagnostic_t, pm_parser_t};

use super::Location;

/// A diagnostic message that came back from the parser.
#[derive(Debug)]
pub struct Diagnostic<'pr> {
    diag: NonNull<pm_diagnostic_t>,
    parser: NonNull<pm_parser_t>,
    marker: PhantomData<&'pr pm_diagnostic_t>,
}

impl<'pr> Diagnostic<'pr> {
    /// Returns the message associated with the diagnostic.
    ///
    /// # Panics
    ///
    /// Panics if the message is not able to be converted into a `CStr`.
    ///
    #[must_use]
    pub fn message(&self) -> &str {
        unsafe {
            let message: *mut c_char = self.diag.as_ref().message.cast_mut();
            CStr::from_ptr(message).to_str().expect("prism allows only UTF-8 for diagnostics.")
        }
    }

    /// The location of the diagnostic in the source.
    #[must_use]
    pub const fn location(&self) -> Location<'pr> {
        Location::new(self.parser, unsafe { &self.diag.as_ref().location })
    }
}

/// A struct created by the `errors` or `warnings` methods on `ParseResult`. It
/// can be used to iterate over the diagnostics in the parse result.
pub struct Diagnostics<'pr> {
    diagnostic: *mut pm_diagnostic_t,
    parser: NonNull<pm_parser_t>,
    marker: PhantomData<&'pr pm_diagnostic_t>,
}

impl Diagnostics<'_> {
    pub(crate) const fn new(diagnostic: *mut pm_diagnostic_t, parser: NonNull<pm_parser_t>) -> Self {
        Diagnostics { diagnostic, parser, marker: PhantomData }
    }
}

impl<'pr> Iterator for Diagnostics<'pr> {
    type Item = Diagnostic<'pr>;

    fn next(&mut self) -> Option<Self::Item> {
        if let Some(diagnostic) = NonNull::new(self.diagnostic) {
            let current = Diagnostic {
                diag: diagnostic,
                parser: self.parser,
                marker: PhantomData,
            };
            self.diagnostic = unsafe { diagnostic.as_ref().node.next.cast::<pm_diagnostic_t>() };
            Some(current)
        } else {
            None
        }
    }
}
