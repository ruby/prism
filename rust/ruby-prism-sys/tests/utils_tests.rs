use std::ffi::CStr;

#[test]
fn version_test() {
    use ruby_prism_sys::pm_version;

    let cstring = unsafe {
        let version = pm_version();
        CStr::from_ptr(version)
    };

    assert_eq!(&cstring.to_string_lossy(), "1.9.0");
}
