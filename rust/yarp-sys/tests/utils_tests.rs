use std::{
    ffi::{CStr, CString},
    mem::MaybeUninit,
};

#[test]
fn version_test() {
    use yarp_sys::yp_version;

    let cstring = unsafe {
        let version = yp_version();
        CStr::from_ptr(version)
    };

    assert_eq!(&cstring.to_string_lossy(), "0.9.0");
}

#[test]
fn list_test() {
    use yarp_sys::{yp_list_empty_p, yp_list_free, yp_list_t};

    let mut list = MaybeUninit::<yp_list_t>::zeroed();

    unsafe {
        let list = list.assume_init_mut();

        assert!(yp_list_empty_p(list));

        yp_list_free(list);
    }
}

mod string {
    use yarp_sys::{
        yp_string_free, yp_string_length, yp_string_source, yp_string_t,
        yp_string_t__bindgen_ty_1, YP_STRING_SHARED, YP_STRING_OWNED,
        YP_STRING_CONSTANT, YP_STRING_MAPPED
    };

    use super::*;

    struct S {
        c_string: CString,
        yp_string: yp_string_t,
    }

    impl S {
        fn start_ptr(&self) -> *const u8 {
            self.c_string.as_ptr().cast::<u8>()
        }
    }

    fn make_string(string_type: yp_string_t__bindgen_ty_1) -> S {
        let c_string = CString::new("0123456789012345").unwrap();

        let yp_string = yp_string_t {
            type_: string_type,
            source: c_string.as_ptr().cast::<u8>(),
            length: c_string.as_bytes().len(),
        };

        S {
            c_string,
            yp_string,
        }
    }

    #[test]
    fn shared_string_test() {
        let mut s = make_string(YP_STRING_SHARED);

        unsafe {
            let len = yp_string_length(&s.yp_string);
            assert_eq!(len, 16);

            let result_start = yp_string_source(&s.yp_string);
            assert_eq!(s.start_ptr(), result_start);

            yp_string_free(&mut s.yp_string);
        }
    }

    #[test]
    fn owned_string_test() {
        let s = make_string(YP_STRING_OWNED);

        unsafe {
            let result_len = yp_string_length(&s.yp_string);
            assert_eq!(result_len, 16);

            let result_start = yp_string_source(&s.yp_string);
            assert_eq!(s.yp_string.source, result_start);

            // Don't drop the yp_string--we don't own it anymore!
        }
    }

    #[test]
    fn constant_string_test() {
        let mut s = make_string(YP_STRING_CONSTANT);

        unsafe {
            let result_len = yp_string_length(&s.yp_string);
            assert_eq!(result_len, 16);

            let result_start = yp_string_source(&s.yp_string);
            assert_eq!(s.yp_string.source, result_start);

            yp_string_free(&mut s.yp_string);
        }
    }

    #[test]
    fn mapped_string_test() {
        let s = make_string(YP_STRING_MAPPED);

        unsafe {
            let result_len = yp_string_length(&s.yp_string);
            assert_eq!(result_len, 16);

            let result_start = yp_string_source(&s.yp_string);
            assert_eq!(s.yp_string.source, result_start);
        }
    }
}
