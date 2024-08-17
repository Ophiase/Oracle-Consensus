use oracle_consensus::utils::{show_tuple_array, show_array, wsad_to_string, show_wsad_array};
use oracle_consensus::sort::IndexedMergeSort;
use oracle_consensus::math::{sqrt};
use oracle_consensus::signed_decimal::{
    I128Div, I128Display, I128SignedBasics, unsigned_to_signed, wsad_div, wsad_mul, wsad, half_wsad
};

// ==============================================================================

#[test]
fn test_indexed_merge_sort() {
    let input = array![20_i128, 30, 29, 1, 300, 100];

    let prediction = IndexedMergeSort::sort(@input);
    let expected = array![(3_usize, 1_i128), (0, 20), (2, 29), (1, 30), (5, 100), (4, 300)];

    // show_tuple_array(res);
    assert!(prediction == expected, "indexed merge sort doesn't work");
}

#[test]
fn test_sqrt() {
    {// it works

    // let values = array![
    //     sqrt(0_i128), 
    //     sqrt(9_i128 * wsad()), 
    //     sqrt(16_i128 * wsad()), 
    //     sqrt(305_i128 * wsad())
    // ];

    // show_wsad_array(values);
    // wanted : [0, 3, 4, 17.4928]
    }

    assert!((sqrt(9 * wsad())) == (3 * wsad()), "sqrt error");
}

#[ignore]
#[test]
fn test_i128() {
    let x : i128 = -90;
    let y : i128 = -9;
    let z : i128 = x / y;

    assert!(z == 10_i128, "error");
    // println!("{}", z);
}

#[ignore]
#[test]
fn test_wsad() {
    let x : i128 = -90 * wsad();
    let y : i128 = -9 * wsad();
    let z : i128 = wsad_mul(wsad_div(x, y) + wsad(), 2*wsad());

    assert!(z == 22000000000000000000_i128, "error");
    // println!("{}", z);
}

#[ignore]
#[test]
fn test_signed_conversions() {
    // let x : i128 = 15_i128 * wsad();

    // println!("{}", wsad_to_string(x, 3));

    // let y : u128 = x.as_unsigned_unsafe();
    // println!("{}", y);

    // let z : i128 = unsigned_to_signed(y);
    // println!("{}", wsad_to_string(z, 3));

    let felt : felt252 = (-1_i128).into();
    println!("{}", felt);

    let a : i128 = felt.try_into().unwrap();
    println!("{}", a);
}

#[ignore]
#[test]
fn test_signed_conversions_in_python() {
    println!("-------------------");
    let mut i = 5_i128; 
    loop {
        if i == -11_i128 { break(); }

        let felt : felt252 = (i).into();
        println!("{}", felt);

        i -= 1_i128;
    };

    let minus : felt252 = 3618502788666131213697322783095070105623107215331596699973092056135872020480;
    let k : i128 = minus.try_into().unwrap();
    println!("{}", k);

    println!("");
}

