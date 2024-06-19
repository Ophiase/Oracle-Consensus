use alexandria_math::pow;
use starknet::ContractAddress;

pub fn show_array<T, +Copy<T>, +Drop<T>, +core::fmt::Display<T>>(
    array: Array<T>) {
    
    let mut i = 0;
    print!("[");
    loop {
        if i == array.len() {
            println!("]");
            break();
        }

        print!("{}, ", *array.at(i));

        i += 1;
    };
}

pub fn show_wad_array(array: Array<u256>) {
    let mut i = 0;
    print!("[");
    loop {
        if i == array.len() {
            println!("]");
            break();
        }

        print!("{}, ", wad_to_string(*array.at(i), 3));

        i += 1;
    };
}

pub fn show_address_array(array: Array<ContractAddress>) {
    let mut i = 0;
    print!("[");
    loop {
        if i == array.len() {
            println!("]");
            break();
        }

        let address : felt252 = ( *array.at(i) ).try_into().unwrap();
        print!("{}, ", address);

        i += 1;
    };
}

pub fn show_tuple_array<T, +Copy<T>, +Drop<T>, +core::fmt::Display<T>>(
    array: Array<(usize, T)>) {
    
    let mut i = 0;
    print!("[");
    loop {
        if i == array.len() {
            println!("]");
            break();
        }

        let (index, value) = *array.at(i);
        print!("({}, {}), ", index, value);

        i += 1;
    };
}

pub fn fst<U, +Copy<U>, +Drop<U>, V, +Copy<V>, +Drop<V>>(x : (U, V)) -> U {
    let (u, _v) = x;
    u
}

pub fn snd<U, +Copy<U>, +Drop<U>, V, +Copy<V>, +Drop<V>>(x : (U, V)) -> V {
    let (_u, v) = x;
    v
}

// TODO
pub fn wad_to_string(value: u256, n_digits: usize) -> ByteArray {
    let integer_part = value / pow(10, 18);
    let decimal_part = value - (integer_part * pow(10, 18));
    let decimal_part_reduced = decimal_part / pow(10, 18 - n_digits.into());

    format!("{}.{}", integer_part, decimal_part_reduced)
}