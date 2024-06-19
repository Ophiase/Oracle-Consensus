mod data_science {
    use alexandria_math::wad_ray_math::{
        ray_div, ray_mul, wad_div, wad_mul, ray_to_wad, wad_to_ray, ray, wad, half_ray, half_wad
    };
    use alexandria_math::{pow};    
    use alexandria_sorting::{QuickSort, MergeSort};

    // ==============================================================================

    type WadVector = Span<u256>;

   // Transpose an Array of vectors
    pub fn nd_array_split(array : @Array<WadVector>) -> Array<Array<u256>> {
        let dimension = (*array.at(0)).len();
        let n_vectors = array.len();

        let mut result = ArrayTrait::new();
        let mut i = 0;
        loop {
            if i == dimension { break(); }
            
            let mut ith_components = ArrayTrait::new();
            let mut j = 0; 
            loop {
                if j == n_vectors { break(); }
                
                let which_vector = *array.at(j);
                ith_components.append(*which_vector.at(i));

                j += 1;
            };

            result.append(ith_components);

            i += 1;
        };

        result
    }

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

    pub fn median_index(values : @Array<u256>) -> usize {
        let sorted = MergeSort::sort(values.span());
        let expected_median_idx = values.len() / 2;
        find_index(sorted.at(expected_median_idx), values)
    }

    pub fn median(values : @Array<u256>) -> u256 {
        *values.at(median_index(values))
    }

    // component wise implementation
    // there is no natural order on R^M
    pub fn nd_median(values : @Array<WadVector>) -> WadVector {
        let arrays = nd_array_split(values);
        let mut result = ArrayTrait::new();
        let mut i = 0;
        loop { if i == arrays.len() { break(); }
            result.append( median(arrays.at(i)) );
            i += 1; 
        };

        result.span()
    }

    pub fn quadratic_deviation(a : @u256, b : @u256) -> u256 {
        (*a - *b) * (*a - *b)
    }

    pub fn nd_quadratic_deviation(a : @WadVector, b : @WadVector) -> u256 {
        let dim = (*a).len();

        let mut result = 0;
        let mut i = 0;
        loop { if i == dim { break(); }
            result += quadratic_deviation((*a).at(i), (*b).at(i));
            i += 1;
        };

        result
    }

    // compute the quadratic_risk of each values
    pub fn quadratic_risk(values : @Array<u256>, center : @u256) -> Array<u256> {
        let mut result = ArrayTrait::<u256>::new();
        let mut i = 0;
        loop {
            if i == values.len() {
                break();
            }

            result.append(quadratic_deviation(values.at(i), center));

            i += 1;
        };
        result
    }

    // compute the quadratic_risk of each values
    pub fn nd_quadratic_risk(values : @Array<WadVector>, center : @WadVector) -> Array<u256> {
        let mut result = ArrayTrait::<u256>::new();
        let mut i = 0;
        loop {
            if i == values.len() {
                break();
            }

            result.append(nd_quadratic_deviation(values.at(i), center));

            i += 1;
        };
        result
    }

    pub fn average(values : @Array<u256>) -> u256 {
        let mut result = 0_u256;
        let mut i = 0;
        loop {
            if i == values.len() {
                break();
            }

            result += *values.at(i);

            i += 1;
        };

        result / values.len().into()
    }

    pub fn nd_average(values : @Array<WadVector>) -> WadVector {
        let arrays = nd_array_split(values);
        let mut result = ArrayTrait::new();
        let mut i = 0;
        loop { if i == arrays.len() { break(); }
            result.append( average(arrays.at(i)) );
            i += 1; 
        };

        result.span()
    }

    const MAX_SQRT_ITERATIONS : usize = 50;
    pub fn sqrt(value : u256) -> u256 {
        if (value == 0) {
            return 0;
        }

        let mut g = value / 2;
        let mut g2 = g + wad();

        let mut i = 0;
        loop {
            if g == g2 || i == MAX_SQRT_ITERATIONS {
                break(g);
            }

            let n = wad_div(value, g);
            g2 = g;
            g = (g + n) / 2;

            i += 1;
        }
    }
}

