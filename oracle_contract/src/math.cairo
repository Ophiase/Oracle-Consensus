
use oracle_consensus::signed_wad_ray::{
    I128Div, I128Display, I128SignedBasics, unsigned_to_signed,
    ray_div, ray_mul, wad_div, wad_mul, ray_to_wad, wad_to_ray, ray, wad, half_ray, half_wad
};
use alexandria_math::{pow};    
use alexandria_sorting::{QuickSort, MergeSort};

// ==============================================================================

type WadVector = Span<i128>;

// Transpose an Array of vectors
pub fn nd_array_split(array : @Array<WadVector>) -> Array<Array<i128>> {
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

fn find_index(value : @i128, array : @Array<i128>) -> usize {
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

pub fn median_index(values : @Array<i128>) -> usize {
    let sorted = MergeSort::sort(values.span());
    let expected_median_idx = values.len() / 2;
    find_index(sorted.at(expected_median_idx), values)
}

pub fn median(values : @Array<i128>) -> i128 {
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

const PREVENT_OVERFLOW : bool = true;
const OVERFLOW_REDUCTION : i128 = 10000000000000; // 1e14

pub fn quadratic_deviation(a : @i128, b : @i128) -> i128 {
    // if PREVENT_OVERFLOW {
    //     let c = (*a - *b);// / OVERFLOW_REDUCTION;
    //     (c * c) //* OVERFLOW_REDUCTION * OVERFLOW_REDUCTION
    // } else {
    // }
    
    (*a - *b) * (*a - *b)
}

pub fn nd_quadratic_deviation(a : @WadVector, b : @WadVector) -> i128 {
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
pub fn quadratic_risk(values : @Array<i128>, center : @i128) -> Array<i128> {
    let mut result = ArrayTrait::new();
    let mut i = 0;
    loop {
        if i == values.len() {
            break();
        }

        println!("{}", i);
        println!("{}", *values.at(i));
        result.append(quadratic_deviation(values.at(i), center));

        i += 1;
    };
    result
}

// compute the quadratic_risk of each values
pub fn nd_quadratic_risk(values : @Array<WadVector>, center : @WadVector) -> Array<i128> {
    let mut result = ArrayTrait::<i128>::new();
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

pub fn average(values : @Array<i128>) -> i128 {
    let mut result = 0_i128;
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
pub fn sqrt(value : i128) -> i128 {
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

fn interval_check(value : @i128) {
    assert((0_i128 <= *value) && (*value <= wad()), 'interval error');
}

fn nd_interval_check(value : @WadVector) {
    let mut i = 0;
    loop {
        if i == (*value).len() { break(); }

        let v = *(*value).at(i);
        assert(
            ( 0_i128 <= v ) && ( v <= wad() ), 
            'interval error');

        i += 1;
    };
}

