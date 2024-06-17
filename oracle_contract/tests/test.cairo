// use starknet::syscalls::deploy_syscall;
// use starknet::ContractAddress;
// use super::ContractA;
// use super::IContractADispatcher;
// use super::IContractADispatcherTrait;
// use super::ContractB;
// use super::IContractBDispatcher;
// use super::IContractBDispatcherTrait;

use alexandria_math::wad_ray_math::{
    ray_div, ray_mul, wad_div, wad_mul, 
    ray_to_wad, wad_to_ray, ray, wad, 
    half_ray, half_wad
};
use alexandria_math::{pow};
use alexandria_sorting::{QuickSort, MergeSort};
    
use oracle_consensus::math::data_science::{addition};

#[test]
#[available_gas(30000000)]
fn test_import() {
    let x = 3 * wad();
    let y = 10 * wad();
    
    let result = addition(x, y);
    assert(result == 13 * wad(), 'error add');
    assert(wad_mul(x, y) == 30 * wad(), 'error mult');
}

// fn show_array(array: Span<u256>) {
//     let i = 0;
//     let mut res = String::from("");
//     loop {
//         if i == array.len() {
//             println!("{}", res);
//         }

//         res = res + String::from(array.at(i));

//         i += 1;
//     }
// }

#[test]
#[available_gas(30000000)]
fn test_median() {
    // reminder pow(10,18) = 1 wad

    // let mut array : Array<Option<u256>> = ArrayTrait::new();
    // array.append(Option::Some(1 * pow(10, 17)));
    // array.append(Option::Some(10 * pow(10, 17)));
    // array.append(Option::Some(35 * pow(10, 16)));
    // array.append(Option::Some(3 * pow(10, 17)));
    // array.append(Option::Some(7 * pow(10, 17)));
    // array.append(Option::Some(5 * pow(10, 17)));
    // array.append(Option::Some(2 * pow(10, 17)));
    

    // let sorted = QuickSort::sort(array);
    // println!(sorted);

    let data = array![10_u32, 20, 30, 30, 35, 50, 70, 10].span();

    let expected_median_idx = 4;
    let expected_median_value = 35_u32;

    let sorted = MergeSort::sort(data);

    assert(
        *sorted.at(expected_median_idx) == expected_median_value, 
        'error');

    // println!("{}", data);
    // println!("{}", sorted);
}

#[test]
#[available_gas(30000000)]
fn test_constructor() {
//         // Deploy ContractA
//         let mut calldata = ArrayTrait::new();
//         calldata.append(address_b.into());
//         let (address_a, _) = deploy_syscall(
//             ContractA::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false
//         )
//             .unwrap();

//         // contract_a is of type IContractADispatcher. Its methods are defined in IContractADispatcherTrait.
//         let contract_a = IContractADispatcher { contract_address: address_a };
}