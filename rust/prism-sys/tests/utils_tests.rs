use std::{
    ffi::{CStr, CString},
    mem::MaybeUninit,
};

#[test]
fn version_test() {
    use prism_sys::pm_version;

    let cstring = unsafe {
        let version = pm_version();
        CStr::from_ptr(version)
    };

    assert_eq!(&cstring.to_string_lossy(), "0.17.0");
}

#[test]
fn list_test() {
    use prism_sys::{pm_list_empty_p, pm_list_free, pm_list_t};

    let mut list = MaybeUninit::<pm_list_t>::zeroed();

    unsafe {
        let list = list.assume_init_mut();

        assert!(pm_list_empty_p(list));

        pm_list_free(list);
    }
}

mod string {
    use prism_sys::{
        pm_string_free, pm_string_length, pm_string_source, pm_string_t, pm_string_t__bindgen_ty_1, PM_STRING_CONSTANT,
        PM_STRING_MAPPED, PM_STRING_OWNED, PM_STRING_SHARED,
    };

    use super::*;

    struct S {
        c_string: CString,
        pm_string: pm_string_t,
    }

    impl S {
        fn start_ptr(&self) -> *const u8 {
            self.c_string.as_ptr().cast::<u8>()
        }
    }

    fn make_string(string_type: pm_string_t__bindgen_ty_1) -> S {
        let c_string = CString::new("0123456789012345").unwrap();

        let pm_string = pm_string_t {
            type_: string_type,
            source: c_string.as_ptr().cast::<u8>(),
            length: c_string.as_bytes().len(),
        };

        S { c_string, pm_string }
    }

    #[test]
    fn shared_string_test() {
        let mut s = make_string(PM_STRING_SHARED);

        unsafe {
            let len = pm_string_length(&s.pm_string);
            assert_eq!(len, 16);

            let result_start = pm_string_source(&s.pm_string);
            assert_eq!(s.start_ptr(), result_start);

            pm_string_free(&mut s.pm_string);
        }
    }

    #[test]
    fn owned_string_test() {
        let s = make_string(PM_STRING_OWNED);

        unsafe {
            let result_len = pm_string_length(&s.pm_string);
            assert_eq!(result_len, 16);

            let result_start = pm_string_source(&s.pm_string);
            assert_eq!(s.pm_string.source, result_start);

            // Don't drop the pm_string--we don't own it anymore!
        }
    }

    #[test]
    fn constant_string_test() {
        let mut s = make_string(PM_STRING_CONSTANT);

        unsafe {
            let result_len = pm_string_length(&s.pm_string);
            assert_eq!(result_len, 16);

            let result_start = pm_string_source(&s.pm_string);
            assert_eq!(s.pm_string.source, result_start);

            pm_string_free(&mut s.pm_string);
        }
    }

    #[test]
    fn mapped_string_test() {
        let s = make_string(PM_STRING_MAPPED);

        unsafe {
            let result_len = pm_string_length(&s.pm_string);
            assert_eq!(result_len, 16);

            let result_start = pm_string_source(&s.pm_string);
            assert_eq!(s.pm_string.source, result_start);
        }
    }
}
