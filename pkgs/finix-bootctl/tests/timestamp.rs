use crate::testtoolkit::finix_timestamp;

#[test]
fn timestamp_simple_positive() {
    assert_eq!(finix_timestamp("Finix123"), Some(123));
}

#[test]
fn timestamp_negative() {
    assert_eq!(finix_timestamp("Finix-42"), Some(-42));
}

#[test]
fn timestamp_zero() {
    assert_eq!(finix_timestamp("Finix0"), Some(0));
}

#[test]
fn timestamp_with_leading_trim() {
    assert_eq!(finix_timestamp("Finix  999"), Some(999));
    assert_eq!(finix_timestamp("Finix\t100"), Some(100));
    assert_eq!(finix_timestamp("Finix  0  "), Some(0));
}

#[test]
fn timestamp_trailing_spaces() {
    assert_eq!(finix_timestamp("Finix123   "), Some(123));
}

#[test]
fn timestamp_large_i64_max() {
    let max = i64::MAX.to_string();
    assert_eq!(finix_timestamp(&format!("Finix{max}")), Some(i64::MAX));
}

#[test]
fn timestamp_large_i64_min() {
    let min = i64::MIN.to_string();
    assert_eq!(finix_timestamp(&format!("Finix{min}")), Some(i64::MIN));
}

#[test]
fn timestamp_overflow_returns_none() {
    // i64 overflow - parse fails -> warning + None
    assert_eq!(finix_timestamp("Finix9999999999999999999999"), None);
}

#[test]
fn timestamp_not_prefixed() {
    assert_eq!(finix_timestamp("Finixx123"), None);
    assert_eq!(finix_timestamp("finix123"), None);
    assert_eq!(finix_timestamp(" Finix123"), None);
    assert_eq!(finix_timestamp(""), None);
    assert_eq!(finix_timestamp("Other123"), None);
    assert_eq!(finix_timestamp("Boot123"), None);
}

#[test]
fn timestamp_only_prefix_no_number() {
    assert_eq!(finix_timestamp("Finix"), None);
    assert_eq!(finix_timestamp("Finix   "), None);
    assert_eq!(finix_timestamp("Finix\t"), None);
}

#[test]
fn timestamp_unparsable_suffix() {
    assert_eq!(finix_timestamp("Finixabc"), None);
    assert_eq!(finix_timestamp("Finix12abc"), None);
    assert_eq!(finix_timestamp("Finix12.34"), None);
    assert_eq!(finix_timestamp("Finix--5"), None);
    assert_eq!(finix_timestamp("Finix++5"), None);
}

#[test]
fn timestamp_float_string_is_none() {
    assert_eq!(finix_timestamp("Finix3.14"), None);
}

#[test]
fn timestamp_hex_not_parsed_as_decimal() {
    assert_eq!(finix_timestamp("Finix0x10"), None);
}

#[test]
fn timestamp_unicode_trim() {
    // only ASCII trim is relevant; but test that unicode prefix fails
    assert_eq!(finix_timestamp("Finix１２３"), None);
}

#[test]
fn timestamp_embedded_newline() {
    assert_eq!(finix_timestamp("Finix123\n"), Some(123)); // trim removes newline
    assert_eq!(
        finix_timestamp("Finix123\n".trim_end_matches('\n')),
        Some(123)
    );
}

#[test]
fn timestamp_preserves_sign() {
    assert_eq!(finix_timestamp("Finix+5"), Some(5));
    assert_eq!(finix_timestamp("Finix-0"), Some(0));
}

#[test]
fn timestamp_empty_after_trim() {
    assert_eq!(finix_timestamp("Finix "), None);
}

#[test]
fn timestamp_with_internal_spaces() {
    assert_eq!(finix_timestamp("Finix1 2"), None);
    assert_eq!(finix_timestamp("Finix 1 2"), None);
}
