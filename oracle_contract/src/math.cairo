mod data_science {
    use alexandria_math::wad_ray_math::{
        ray_div, ray_mul, wad_div, wad_mul, ray_to_wad, wad_to_ray, ray, wad, half_ray, half_wad
    };
    use alexandria_math::{pow};    
    use alexandria_sorting::{QuickSort, MergeSort};

    fn find_index(value : @u256, array : @Array<u256>) -> usize {
        let mut i = 0;
        loop {
            if i == array.len() {
                assert(false, 'value not found')
            }

            if *array.at(i) == *value {
                break(i);
            }

            i += 1;
        }
    }

    pub fn median(values : @Array<u256>) -> usize {
        let sorted = MergeSort::sort(values.span());
        let expected_median_idx = values.len() / 2;
        find_index(sorted.at(expected_median_idx), values)
    }

    pub fn deviation(a : @u256, b : @u256) -> u256 {
        (*a - *b) * (*a - *b)
    }

    // compute the spread of each values
    pub fn spread(values : @Array<u256>, center : @u256) -> Array<u256> {
        let mut result = ArrayTrait::<u256>::new();
        let mut i = 0;
        loop {
            if i == values.len() {
                break();
            }

            result.append(deviation(values.at(i), center));

            i += 1;
        };
        result
    }

    // pub fn highest_filtering(values : @Array<u256>) -> Array<u256> {

    // }
}

