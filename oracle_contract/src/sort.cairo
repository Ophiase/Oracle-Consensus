// Indexed Merge Sort based on alexandria implementation : https://github.com/keep-starknet-strange/alexandria/tree/main/packages/sorting

// Merge Sort
// # Arguments
// * `arr` - Array to sort
// # Returns
// * `Array<T>` - Sorted array

pub trait IndexedSortable {
    fn sort<T, +Copy<T>, +Drop<T>, +PartialOrd<T>>(array: @Array<T>) -> Array<(usize, T)>;
}

pub impl IndexedMergeSort of IndexedSortable {
    fn sort<T, +Copy<T>, +Drop<T>, +PartialOrd<T>>(array: @Array<T>) -> Array<(usize, T)> {
        sort_aux(add_index_to_array(array).span())
    }
}

fn add_index_to_array<T, +Copy<T>, +Drop<T>, +PartialOrd<T>>(values: @Array<T>) -> Array<(usize, T)> {
    let mut result = ArrayTrait::<(usize, T)>::new();

    let mut i = 0;
    loop {
        if values.len() == i {
            break();
        }
        result.append((i, *values.at(i)));
        i += 1;
    };

    result
}


fn sort_aux<T, +Copy<T>, +Drop<T>, +PartialOrd<T>>(mut array: Span<(usize, T)>) -> Array<(usize, T)> {
    let len = array.len();
    if len == 0 {
        return array![];
    }
    if len == 1 {
        return array![*array.at(0)];
    }

    // Create left and right arrays
    let middle = len / 2;
    let left_arr = array.slice(0, middle);
    let right_arr = array.slice(middle, len - middle);

    // Recursively sort the left and right arrays
    let sorted_left = sort_aux(left_arr);
    let sorted_right = sort_aux(right_arr);

    let mut result_arr = array![];
    merge_recursive(sorted_left, sorted_right, ref result_arr, 0, 0);
    
    result_arr
}

// Merge two sorted arrays
// # Arguments
// * `left_arr` - Left array
// * `right_arr` - Right array
// * `result_arr` - Result array
// * `left_arr_ix` - Left array index
// * `right_arr_ix` - Right array index
// # Returns
// * `Array<usize>` - Sorted array
fn merge_recursive<T, +Copy<T>, +Drop<T>, +PartialOrd<T>>(
    mut left_arr: Array<(usize, T)>,
    mut right_arr: Array<(usize, T)>,
    ref result_arr: Array<(usize, T)>,
    left_arr_ix: usize,
    right_arr_ix: usize
) {
    if result_arr.len() == left_arr.len() + right_arr.len() {
        return;
    }

    if left_arr_ix == left_arr.len() {
        result_arr.append(*right_arr[right_arr_ix]);
        return merge_recursive(left_arr, right_arr, ref result_arr, left_arr_ix, right_arr_ix + 1);
    }

    if right_arr_ix == right_arr.len() {
        result_arr.append(*left_arr[left_arr_ix]);
        return merge_recursive(left_arr, right_arr, ref result_arr, left_arr_ix + 1, right_arr_ix);
    }

    let (_tmp, left_value) = *left_arr.at(left_arr_ix);
    let (_tmp, right_value) = *right_arr.at(right_arr_ix);

    if left_value < right_value{
        result_arr.append(*left_arr[left_arr_ix]);
        merge_recursive(left_arr, right_arr, ref result_arr, left_arr_ix + 1, right_arr_ix)
    } else {
        result_arr.append(*right_arr[right_arr_ix]);
        merge_recursive(left_arr, right_arr, ref result_arr, left_arr_ix, right_arr_ix + 1)
    }
}
