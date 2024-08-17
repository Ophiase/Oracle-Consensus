use oracle_consensus::signed_decimal::{
    I128Div, I128Display, I128SignedBasics, unsigned_to_signed, felt_to_i128, wsad_div, wsad_mul,
    wsad, half_wsad, safe_wsad_mul
};
use alexandria_math::{pow};
use alexandria_sorting::{QuickSort, MergeSort};
use oracle_consensus::utils::{wsad_to_string};

// ==============================================================================

type WsadVector = Span<i128>;
type FeltVector = Span<felt252>;

trait IWsadVectorBasics {
    fn as_felt(self: @WsadVector) -> FeltVector;
}

trait IFeltVectorBasics {
    fn as_wsad(self: @FeltVector) -> WsadVector;
}

impl WsadVectorBasics of IWsadVectorBasics {
    fn as_felt(self: @WsadVector) -> FeltVector {
        let mut result = ArrayTrait::new();
        let mut i = 0;
        loop {
            if i == (*self).len() {
                break ();
            }
            result.append((*(*self).at(i)).try_into().unwrap());
            i += 1;
        };
        result.span()
    }
}

impl FeltVectorBasics of IFeltVectorBasics {
    fn as_wsad(self: @FeltVector) -> WsadVector {
        let mut result = ArrayTrait::new();
        let mut i = 0;
        loop {
            if i == (*self).len() {
                break ();
            }
            result.append((*(*self).at(i)).try_into().unwrap());
            i += 1;
        };
        result.span()
    }
}

// ==============================================================================

// Transpose an Array of vectors
pub fn nd_array_split(array: @Array<WsadVector>) -> Array<Array<i128>> {
    let dimension = (*array.at(0)).len();
    let n_vectors = array.len();

    let mut result = ArrayTrait::new();
    let mut i = 0;
    loop {
        if i == dimension {
            break ();
        }

        let mut ith_components = ArrayTrait::new();
        let mut j = 0;
        loop {
            if j == n_vectors {
                break ();
            }

            let which_vector = *array.at(j);
            ith_components.append(*which_vector.at(i));

            j += 1;
        };

        result.append(ith_components);

        i += 1;
    };

    result
}

fn find_index(value: @i128, array: @Array<i128>) -> usize {
    let mut i = 0;
    loop {
        if i == array.len() {
            assert(false, 'value not found')
        }

        if *array.at(i) == *value {
            break (i);
        }

        i += 1;
    }
}

pub fn median_index(values: @Array<i128>) -> usize {
    let sorted = MergeSort::sort(values.span());
    let expected_median_idx = values.len() / 2;
    find_index(sorted.at(expected_median_idx), values)
}

pub fn median(values: @Array<i128>) -> i128 {
    *values.at(median_index(values))
}

// we assume at least 3 values in the array
pub fn smooth_median(values: @Array<i128>) -> i128 {
    let sorted = MergeSort::sort(values.span());
    let mid = values.len() / 2;

    let a = *sorted.at(mid - 1);
    let b = *sorted.at(mid);

    if (values.len() & 2) == 1 {
        let c = *sorted.at(mid + 1);
        (a + b + c) / 3_i128
    } else {
        (a + b) / 2_i128
    }
}

// TODO:
// pub fn super_smooth_median(values : @Array<i128>) -> i128 {
//     //
// }

// component wise implementation
// there is no natural order on R^M
pub fn nd_median(values: @Array<WsadVector>) -> WsadVector {
    let arrays = nd_array_split(values);
    let mut result = ArrayTrait::new();
    let mut i = 0;
    loop {
        if i == arrays.len() {
            break ();
        }
        result.append(median(arrays.at(i)));
        i += 1;
    };

    result.span()
}

// component wise implementation
// there is no natural order on R^M
pub fn nd_smooth_median(values: @Array<WsadVector>) -> WsadVector {
    let arrays = nd_array_split(values);
    let mut result = ArrayTrait::new();
    let mut i = 0;
    loop {
        if i == arrays.len() {
            break ();
        }
        result.append(smooth_median(arrays.at(i)));
        i += 1;
    };

    result.span()
}

// const PREVENT_OVERFLOW : bool = true;
// const OVERFLOW_REDUCTION : i128 = 10000000000000; // 1e14

pub fn quadratic_deviation(a: @i128, b: @i128) -> i128 {
    let x = (*a - *b);
    wsad_mul(x, x)
}

pub fn nd_quadratic_deviation(a: @WsadVector, b: @WsadVector) -> i128 {
    let dim = (*a).len();

    let mut result = 0;
    let mut i = 0;
    loop {
        if i == dim {
            break ();
        }
        result += quadratic_deviation((*a).at(i), (*b).at(i));
        i += 1;
    };

    result
}


// compute the quadratic_risk of each values
pub fn quadratic_risk(values: @Array<i128>, center: @i128) -> Array<i128> {
    let mut result = ArrayTrait::new();
    let mut i = 0;
    loop {
        if i == values.len() {
            break ();
        }

        result.append(quadratic_deviation(values.at(i), center));

        i += 1;
    };
    result
}

pub fn nd_component_wise_variance(values: @Array<WsadVector>, center: @WsadVector) -> WsadVector {
    let arrays = nd_array_split(values);
    let mut result = ArrayTrait::new();
    let mut i = 0;
    loop {
        if i == arrays.len() {
            break ();
        }
        let qr = quadratic_risk(arrays.at(i), (*center).at(i));
        result.append(average(@qr));
        i += 1;
    };

    result.span()
}

// compute the quadratic_risk of each values
pub fn nd_quadratic_risk(values: @Array<WsadVector>, center: @WsadVector) -> Array<i128> {
    let mut result = ArrayTrait::<i128>::new();
    let mut i = 0;
    loop {
        if i == values.len() {
            break ();
        }

        result.append(nd_quadratic_deviation(values.at(i), center));

        i += 1;
    };
    result
}

pub fn average(values: @Array<i128>) -> i128 {
    let mut result = 0_i128;
    let mut i = 0;
    loop {
        if i == values.len() {
            break ();
        }

        result += *values.at(i);

        i += 1;
    };

    result / values.len().into()
}

pub fn nd_average(values: @Array<WsadVector>) -> WsadVector {
    let arrays = nd_array_split(values);
    let mut result = ArrayTrait::new();
    let mut i = 0;
    loop {
        if i == arrays.len() {
            break ();
        }
        result.append(average(arrays.at(i)));
        i += 1;
    };

    result.span()
}

const MAX_SQRT_ITERATIONS: usize = 50;
pub fn sqrt(value: i128) -> i128 {
    if (value == 0) {
        return 0;
    }

    let mut g = value / 2;
    let mut g2 = g + wsad();

    let mut i = 0;
    loop {
        if g == g2 || i == MAX_SQRT_ITERATIONS {
            break (g);
        }

        let n = wsad_div(value, g);
        g2 = g;
        g = (g + n) / 2;

        i += 1;
    }
}

fn interval_check(value: @i128) {
    assert((0_i128 <= *value) && (*value <= wsad()), 'interval error');
}

fn nd_interval_check(value: @WsadVector) {
    let mut i = 0;
    loop {
        if i == (*value).len() {
            break ();
        }

        let v = *(*value).at(i);
        assert((0_i128 <= v) && (v <= wsad()), 'interval error');

        i += 1;
    };
}

pub fn min(a: @i128, b: @i128) -> i128 {
    if *a > *b {
        *b
    } else {
        *a
    }
}

pub fn skewness(values: @Array<i128>, mean: @i128, variance: @i128) -> i128 {
    let n = values.len().into();
    let std_dev = sqrt(*variance);

    let mut skew = 0_i128;
    let mut i = 0;
    loop {
        if i == values.len() {
            break ();
        }

        let diff = wsad_div(*values.at(i) - *mean, std_dev);
        skew += wsad_mul(wsad_mul(diff, diff), diff);

        i += 1;
    };

    (skew * n) / ((n - 1) * (n - 2))
}

pub fn kurtosis(values: @Array<i128>, mean: @i128, variance: @i128) -> i128 {
    let n = values.len().into();
    let std_dev = sqrt(*variance);

    let mut kurt = 0_i128;
    let mut i = 0;
    loop {
        if i == values.len() {
            break ();
        }

        let diff = wsad_div(*values.at(i) - *mean, std_dev);
        let diff_squared = wsad_mul(diff, diff);
        let diff_hypercube = safe_wsad_mul(diff_squared, diff_squared);
        kurt += diff_hypercube;

        i += 1;
    };

    let term1 = (kurt * n * (n + 1)) / (n - 1);
    let term2 = (3 * wsad() * (n - 1) * (n - 1));

    (term1 - term2) / ((n - 2) * (n - 3))
}

pub fn nd_skewness(
    values: @Array<WsadVector>, means: @WsadVector, variances: @WsadVector
) -> WsadVector {
    let arrays = nd_array_split(values);
    let mut result = ArrayTrait::new();
    let mut i = 0;
    loop {
        if i == arrays.len() {
            break ();
        }

        result.append(skewness(arrays.at(i), (*means).at(i), (*variances).at(i)));
        i += 1;
    };

    result.span()
}

pub fn nd_kurtosis(
    values: @Array<WsadVector>, means: @WsadVector, variances: @WsadVector
) -> WsadVector {
    let arrays = nd_array_split(values);
    let mut result = ArrayTrait::new();
    let mut i = 0;
    loop {
        if i == arrays.len() {
            break ();
        }

        result.append(kurtosis(arrays.at(i), (*means).at(i), (*variances).at(i)));
        i += 1;
    };
    result.span()
}
