use alexandria_math::pow;
use starknet::ContractAddress;
use oracle_consensus::contract_1d_constrained;
use oracle_consensus::structs::Oracle;
use oracle_consensus::signed_wad_ray::{
    I128Div, I128Display, I128SignedBasics, unsigned_to_signed,
    ray_div, ray_mul, wad_div, wad_mul, ray_to_wad, wad_to_ray, ray, wad, half_ray, half_wad
};

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

pub fn show_oracle_array(
    array: Array<Oracle>, show_address : bool, show_enabled : bool, show_reliable : bool, jump_line : bool
    ) {
    
    let mut i = 0;
    // print!("[");
    loop {
        if i == array.len() {
            // println!("]");
            println!("");
            break();
        }

        let oracle = *array.at(i);

        let mut result = wad_to_string(oracle.value, 2);
        if show_address { result = contractaddress_to_bytearray(oracle.address) + " : " + result; }
        if show_enabled { result = format!("{}, e:{}", result, oracle.enabled); }
        if show_reliable { result = format!("{}, r:{}", result, oracle.reliable); }

        result = "(" + result + ")";

        if jump_line && (i % 2 == 1) {
            println!("{}", result);
        } else {
            print!("{}", result);
        }

        i += 1;
    };
}

pub fn show_wad_array(array: Array<i128>) {
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

const BYTE : u256 = 256;

fn n_bytes(value : felt252) -> u32 {
    let mut power = 0;
    let mut x : u256 = value.into();
    loop {
        if x == 0 { break(power); }
        x = x / BYTE; // is there a bitshift in cairo?
        power += 1;
    }
}

// https://www.stark-utils.xyz/converter
fn felt252_to_bytearray(value : felt252) -> ByteArray {
    let mut x: ByteArray = "";
    x.append_word(value, n_bytes(value));
    x
}

fn contractaddress_to_bytearray(value : ContractAddress) -> ByteArray {
    felt252_to_bytearray(value.try_into().unwrap())
}

pub fn show_address_array(array: Array<ContractAddress>) {
    let mut i = 0;
    print!("[");
    loop {
        if i == array.len() {
            println!("]");
            break();
        }

        print!("{}, ", contractaddress_to_bytearray(*array.at(i)));

        i += 1;
    };
}

pub fn show_replacement_propositions(array : Array<Option::<(usize, ContractAddress)>>) {
    let mut i = 0;
    print!("[");
    loop {
        if i == array.len() {
            println!("]");
            break();
        }

        match *array.at(i) {
            Option::None => print!("{} = [None], ", i),
            Option::Some((old_oracle, new_oracle)) => {
                print!(
                    "{} = [{} -> {}], ", 
                    i, old_oracle, 
                    contractaddress_to_bytearray(new_oracle)
                )
            }
        };

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

pub fn wad_to_string(value: i128, n_digits: usize) -> ByteArray {
    let uvalue = value.as_unsigned();
    let sign : ByteArray = if value.is_positive() { "" } else { "-" };

    let integer_part = uvalue / pow(10, 18);
    let decimal_part = uvalue - (integer_part * pow(10, 18));
    let decimal_part_reduced = decimal_part / pow(10, 18 - n_digits.into());

    format!("{}{}.{}", sign, integer_part, decimal_part_reduced)
}