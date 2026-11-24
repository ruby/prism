use std::ffi::CStr;

#[test]
fn version_test() {
    use ruby_prism_sys::pm_version;

    let cstring = unsafe {
        let version = pm_version();
        CStr::from_ptr(version)
    };

    assert_eq!(&cstring.to_string_lossy(), "2.1.0");
}

#[test]
fn string_query_version_slice_test() {
    use ruby_prism_sys::{pm_string_query_keyword, PM_STRING_QUERY_ERROR_VERSION, PM_STRING_QUERY_TRUE};

    let query = |version: Option<&[u8]>| {
        let (ptr, len) = version.map_or((std::ptr::null(), 0), |bytes| (bytes.as_ptr().cast(), bytes.len()));
        unsafe { pm_string_query_keyword(b"end".as_ptr(), 3, b"US-ASCII".as_ptr().cast(), 8, ptr, len) }
    };

    let version = b"3.4!";
    assert_eq!(query(Some(&version[..3])), PM_STRING_QUERY_TRUE);
    assert_eq!(query(Some(version)), PM_STRING_QUERY_ERROR_VERSION);
    assert_eq!(query(None), PM_STRING_QUERY_TRUE);
    assert_eq!(query(Some(&[])), PM_STRING_QUERY_ERROR_VERSION);
}
