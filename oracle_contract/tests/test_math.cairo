use oracle_consensus::utils::{
    show_tuple_array, show_array, wad_to_string,
    show_wad_array
    };
use oracle_consensus::sort::IndexedMergeSort;
use oracle_consensus::math::{sqrt};
use alexandria_math::wad_ray_math::{
    ray_div, ray_mul, wad_div, wad_mul, ray_to_wad, wad_to_ray, ray, wad, half_ray, half_wad
};

// ==============================================================================


#[test]
fn test_indexed_merge_sort() {
    let input = array![20_u256, 30, 29, 1, 300, 100];

    let prediction = IndexedMergeSort::sort(@input);
    let expected = array![
        (3_usize, 1_u256), 
        (0, 20), 
        (2, 29), 
        (1, 30), 
        (5, 100), 
        (4, 300)
    ];

    // show_tuple_array(res);
    assert!(prediction == expected, "indexed merge sort doesn't work");
}

#[test]
fn test_sqrt() {
    {
        // it works

        // let values = array![
        //     sqrt(0_u256), 
        //     sqrt(9_u256 * wad()), 
        //     sqrt(16_u256 * wad()), 
        //     sqrt(305_u256 * wad())
        // ];

        // show_wad_array(values);
        // wanted : [0, 3, 4, 17.4928]
    }

    assert!(
    (sqrt(9 * wad())) == (3 * wad()),
    "sqrt error"
    );
}