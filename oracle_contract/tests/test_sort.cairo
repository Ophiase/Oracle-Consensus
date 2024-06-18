use oracle_consensus::utils::show_tuple_array;
use oracle_consensus::sort::IndexedMergeSort;

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
    assert(prediction == expected, 'error');
}