//! Queries for whether a string is a valid name of a given kind in Ruby.

use std::ffi::{c_char, CString};
use std::fmt;

use ruby_prism_sys::{pm_string_query_constant, pm_string_query_keyword, pm_string_query_local, pm_string_query_method_name, pm_string_query_t, PM_STRING_QUERY_FALSE, PM_STRING_QUERY_TRUE};

/// The error returned when a string query is given an encoding that prism
/// does not know or that is not ASCII-compatible.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct InvalidEncodingError;

impl fmt::Display for InvalidEncodingError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "Invalid or non ascii-compatible encoding")
    }
}

impl std::error::Error for InvalidEncodingError {}

/// Queries whether a string is a valid name of a given kind in Ruby.
///
/// The string is interpreted as UTF-8 unless another encoding is given with
/// [`StringQuery::encoding`].
///
/// ```
/// use ruby_prism::StringQuery;
///
/// assert_eq!(Ok(true), StringQuery::new(b"foo").is_local());
/// assert_eq!(Ok(true), StringQuery::new(b"Foo").is_constant());
/// assert_eq!(Ok(true), StringQuery::new(b"foo?").is_method_name());
/// assert_eq!(Ok(true), StringQuery::new(b"defined?").is_keyword());
/// ```
#[derive(Debug, Clone, Copy)]
pub struct StringQuery<'a> {
    source: &'a [u8],
    encoding: &'a str,
}

impl<'a> StringQuery<'a> {
    /// Creates a query for the given UTF-8 string.
    #[must_use]
    pub const fn new(source: &'a [u8]) -> Self {
        Self { source, encoding: "UTF-8" }
    }

    /// Sets the name of the encoding that the string is in, such as
    /// `"Windows-31J"` or `"US-ASCII"`.
    #[must_use]
    pub const fn encoding(mut self, encoding: &'a str) -> Self {
        self.encoding = encoding;
        self
    }

    /// Returns whether the string is a valid local variable name.
    ///
    /// # Errors
    ///
    /// Returns [`InvalidEncodingError`] if the encoding is unknown or not
    /// ASCII-compatible.
    pub fn is_local(&self) -> Result<bool, InvalidEncodingError> {
        self.query(pm_string_query_local)
    }

    /// Returns whether the string is a valid constant name.
    ///
    /// # Errors
    ///
    /// Returns [`InvalidEncodingError`] if the encoding is unknown or not
    /// ASCII-compatible.
    pub fn is_constant(&self) -> Result<bool, InvalidEncodingError> {
        self.query(pm_string_query_constant)
    }

    /// Returns whether the string is a valid method name.
    ///
    /// # Errors
    ///
    /// Returns [`InvalidEncodingError`] if the encoding is unknown or not
    /// ASCII-compatible.
    pub fn is_method_name(&self) -> Result<bool, InvalidEncodingError> {
        self.query(pm_string_query_method_name)
    }

    /// Returns whether the string is a keyword (reserved word), such as `if`,
    /// `defined?`, or `__FILE__`.
    ///
    /// # Errors
    ///
    /// Returns [`InvalidEncodingError`] if the encoding is unknown or not
    /// ASCII-compatible.
    pub fn is_keyword(&self) -> Result<bool, InvalidEncodingError> {
        self.query(pm_string_query_keyword)
    }

    fn query(&self, function: unsafe extern "C" fn(*const u8, usize, *const c_char) -> pm_string_query_t) -> Result<bool, InvalidEncodingError> {
        // An encoding name with an interior null byte cannot name a known encoding.
        let encoding = CString::new(self.encoding).map_err(|_| InvalidEncodingError)?;

        match unsafe { function(self.source.as_ptr(), self.source.len(), encoding.as_ptr()) } {
            PM_STRING_QUERY_TRUE => Ok(true),
            PM_STRING_QUERY_FALSE => Ok(false),
            _ => Err(InvalidEncodingError),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::{InvalidEncodingError, StringQuery};

    fn query(source: &str) -> StringQuery<'_> {
        StringQuery::new(source.as_bytes())
    }

    #[test]
    fn local_test() {
        assert_eq!(Ok(true), query("a").is_local());
        assert_eq!(Ok(true), query("a1").is_local());
        assert_eq!(Ok(true), query("self").is_local());

        assert_eq!(Ok(true), query("_a").is_local());
        assert_eq!(Ok(true), query("_1").is_local());

        assert_eq!(Ok(true), query("😀").is_local());
        assert_eq!(Ok(true), StringQuery::new(b"\x83\x41").encoding("Windows-31J").is_local());

        assert_eq!(Ok(false), query("1").is_local());
        assert_eq!(Ok(false), query("A").is_local());
    }

    #[test]
    fn constant_test() {
        assert_eq!(Ok(true), query("A").is_constant());
        assert_eq!(Ok(true), query("A1").is_constant());
        assert_eq!(Ok(true), query("A_B").is_constant());
        assert_eq!(Ok(true), query("BEGIN").is_constant());

        assert_eq!(Ok(true), query("À").is_constant());
        assert_eq!(Ok(true), query("A").encoding("US-ASCII").is_constant());

        assert_eq!(Ok(false), query("a").is_constant());
        assert_eq!(Ok(false), query("1").is_constant());
    }

    #[test]
    fn method_name_test() {
        assert_eq!(Ok(true), query("a").is_method_name());
        assert_eq!(Ok(true), query("A").is_method_name());
        assert_eq!(Ok(true), query("__FILE__").is_method_name());

        assert_eq!(Ok(true), query("a?").is_method_name());
        assert_eq!(Ok(true), query("a!").is_method_name());
        assert_eq!(Ok(true), query("a=").is_method_name());

        assert_eq!(Ok(true), query("+").is_method_name());
        assert_eq!(Ok(true), query("<<").is_method_name());
        assert_eq!(Ok(true), query("===").is_method_name());

        assert_eq!(Ok(true), query("_0").is_method_name());

        assert_eq!(Ok(false), query("1").is_method_name());
        assert_eq!(Ok(false), query("_1").is_method_name());
    }

    #[test]
    fn keyword_test() {
        assert_eq!(Ok(true), query("end").is_keyword());
        assert_eq!(Ok(true), query("defined?").is_keyword());
        assert_eq!(Ok(true), query("__FILE__").is_keyword());
        assert_eq!(Ok(true), query("end").encoding("US-ASCII").is_keyword());

        assert_eq!(Ok(false), query("").is_keyword());
        assert_eq!(Ok(false), query("foo").is_keyword());
        assert_eq!(Ok(false), query("defined").is_keyword());
        assert_eq!(Ok(false), query("End").is_keyword());
    }

    #[test]
    fn subslice_test() {
        // The byte after the slice is outside it and must not affect the result.
        assert_eq!(Ok(true), StringQuery::new(&b"a!"[..1]).is_local());
        assert_eq!(Ok(true), StringQuery::new(&b"Foo="[..3]).is_constant());
        assert_eq!(Ok(true), StringQuery::new(&b"foo?"[..3]).is_method_name());
    }

    #[test]
    fn invalid_encoding_test() {
        assert_eq!(Err(InvalidEncodingError), query("A").encoding("UTF-16LE").is_local());
        assert_eq!(Err(InvalidEncodingError), query("end").encoding("UTF-16LE").is_keyword());
        assert_eq!(Err(InvalidEncodingError), query("end").encoding("UTF-\08").is_keyword());
        assert_eq!(Err(InvalidEncodingError), query("end").encoding("not-an-encoding").is_keyword());
    }
}
