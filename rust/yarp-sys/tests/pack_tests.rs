use std::{ffi::CString, mem::MaybeUninit};

use yarp_sys::{
    yp_pack_encoding, yp_pack_endian, yp_pack_length_type, yp_pack_parse, yp_pack_result,
    yp_pack_signed, yp_pack_size, yp_pack_type, yp_pack_variant, yp_size_to_native,
};

#[test]
fn pack_parse_test() {
    let variant_arg = yp_pack_variant::YP_PACK_VARIANT_PACK;
    let first_format = CString::new("C").unwrap();
    let end_format = CString::new("").unwrap();
    let mut format = vec![first_format.as_ptr(), end_format.as_ptr()];

    let mut type_out = MaybeUninit::<yp_pack_type>::uninit();
    let mut signed_type_out = MaybeUninit::<yp_pack_signed>::uninit();
    let mut endian_out = MaybeUninit::<yp_pack_endian>::uninit();
    let mut size_out = MaybeUninit::<yp_pack_size>::uninit();
    let mut length_type_out = MaybeUninit::<yp_pack_length_type>::uninit();
    let mut length_out = 0_u64;
    let mut encoding_out = MaybeUninit::<yp_pack_encoding>::uninit();

    unsafe {
        let result = yp_pack_parse(
            variant_arg,
            format.as_mut_ptr(),
            end_format.as_ptr(),
            type_out.as_mut_ptr(),
            signed_type_out.as_mut_ptr(),
            endian_out.as_mut_ptr(),
            size_out.as_mut_ptr(),
            length_type_out.as_mut_ptr(),
            &mut length_out,
            encoding_out.as_mut_ptr(),
        );

        assert_eq!(result, yp_pack_result::YP_PACK_OK);

        let type_out = type_out.assume_init();
        let signed_type_out = signed_type_out.assume_init();
        let endian_out = endian_out.assume_init();
        let size_out = size_out.assume_init();
        let length_type_out = length_type_out.assume_init();
        let encoding_out = encoding_out.assume_init();

        assert_eq!(type_out, yp_pack_type::YP_PACK_INTEGER);
        assert_eq!(signed_type_out, yp_pack_signed::YP_PACK_UNSIGNED);
        assert_eq!(endian_out, yp_pack_endian::YP_PACK_AGNOSTIC_ENDIAN);
        assert_eq!(size_out, yp_pack_size::YP_PACK_SIZE_8);
        assert_eq!(length_type_out, yp_pack_length_type::YP_PACK_LENGTH_FIXED);
        assert_eq!(length_out, 1);
        assert_eq!(encoding_out, yp_pack_encoding::YP_PACK_ENCODING_ASCII_8BIT);

        let native_size = yp_size_to_native(size_out);
        assert_eq!(native_size, 1);
    }
}
