use oracle_consensus::structs::Oracle;
use alexandria_math::pow;
use starknet::ContractAddress;
use oracle_consensus::signed_wad_ray::{
    I128Div, I128Display, I128SignedBasics, unsigned_to_signed, felt_to_i128,
    ray_div, ray_mul, wad_div, wad_mul, ray_to_wad, wad_to_ray, ray, wad, half_ray, half_wad
};

use oracle_consensus::math::{
    WadVector, FeltVector,
    IWadVectorBasics, IFeltVectorBasics
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

pub fn wadvector_to_string(vector: WadVector) -> ByteArray {
    let mut i = 0;
    let mut result : ByteArray = "(";
    loop {
        if i == vector.len() {
            break(result.clone() + ")");
        }

        result = result.clone() + format!("{}, ", wad_to_string(*vector.at(i), 3));

        i += 1;
    }
}

pub fn show_nd_oracle_array(
    array: Array<(ContractAddress, WadVector, bool, bool)>, 
    show_address : bool, show_enabled : bool, show_reliable : bool, jump_line : bool
    ) {
    
    let mut i = 0;
    // print!("[");
    loop {
        if i == array.len() {
            // println!("]");
            println!("");
            break();
        }

        let (address, value, enabled, reliable) = *array.at(i);

        let mut result = wadvector_to_string(value);
        if show_address { result = contractaddress_to_bytearray(address) + " : " + result; }
        if show_enabled { result = format!("{}, e:{}", result, enabled); }
        if show_reliable { result = format!("{}, r:{}", result, reliable); }

        result = "(" + result + ")";

        if jump_line {
            println!("{}", result);
        } else {
            print!("{}", result);
        }

        i += 1;
    };
}


pub fn show_nd_felt_oracle_array(
    array: Array<(ContractAddress, FeltVector, bool, bool)>, 
    show_address : bool, show_enabled : bool, show_reliable : bool, jump_line : bool
    ) {
    
    let mut i = 0;
    // print!("[");
    loop {
        if i == array.len() {
            // println!("]");
            println!("");
            break();
        }

        let (address, value, enabled, reliable) = *array.at(i);

        let mut result = wadvector_to_string(value.as_wad());
        if show_address { result = contractaddress_to_bytearray(address) + " : " + result; }
        if show_enabled { result = format!("{}, e:{}", result, enabled); }
        if show_reliable { result = format!("{}, r:{}", result, reliable); }

        result = "(" + result + ")";

        if jump_line {
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


// not optimized, for debug purpose
fn lfill(string : ByteArray, n_digits: usize, character: ByteArray) -> ByteArray {
    if string.len() >= n_digits {
        string
    } else {
        lfill(character.clone() + string, n_digits, character)
    }
}

pub fn felt_wad_to_string(value: felt252, n_digits: usize) -> ByteArray {
    wad_to_string(felt_to_i128(@value), n_digits)
}

// not optimized, for debug purpose
pub fn wad_to_string(value: i128, n_digits: usize) -> ByteArray {
    let uvalue = value.as_unsigned();
    let sign : ByteArray = if value.is_positive() { "" } else { "-" };

    let integer_part = uvalue / pow(10, 18);
    let decimal_part = uvalue - (integer_part * pow(10, 18));
    let decimal_part_reduced = decimal_part / pow(10, 18 - n_digits.into());
    let decimal_part_as_string = format!("{}", decimal_part_reduced);

    format!("{}{}.{}", sign, integer_part, lfill(decimal_part_as_string, n_digits, "0"))
}