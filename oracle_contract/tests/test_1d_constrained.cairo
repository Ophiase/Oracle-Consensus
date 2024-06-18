use starknet::syscalls::deploy_syscall;
use starknet::ContractAddress;

use alexandria_math::wad_ray_math::{
    ray_div, ray_mul, wad_div, wad_mul, 
    ray_to_wad, wad_to_ray, ray, wad, 
    half_ray, half_wad
};
use alexandria_math::{pow};
use alexandria_sorting::{QuickSort, MergeSort};
    
use oracle_consensus::math::data_science::{median};

// #[test]
// #[available_gas(30000000)]
// fn test_import() {
//     let x = 3 * wad();
//     let y = 10 * wad();
    
//     let result = x+y;
//     assert(result == 13 * wad(), 'error add');
//     assert(wad_mul(x, y) == 30 * wad(), 'error mult');
// }

// #[test]
// #[available_gas(30000000)]
// fn test_median() {
//     // reminder pow(10,18) = 1 wad

//     let data = array![10_u256, 100, 35, 30, 70, 50, 20].span();

//     let expected_median_idx = data.len() / 2;
//     let expected_median_value = 35_u256;

//     let sorted = MergeSort::sort(data);

//     println!("{}", *sorted.at(expected_median_idx));

//     assert(
//         *sorted.at(expected_median_idx) == expected_median_value, 
//         'error');

//     // show_array(data);
//     // show_array(sorted);
// }

// #[test]
// #[available_gas(30000000)]
// fn test_index_sort() {
//     // reminder pow(10,18) = 1 wad

//     // let data = array![10_u256, 100, 35, 30, 70, 50, 20].span();

//     // // let sorted = oracle_consensus::sort::MergeSort::sort(data);

//     // println!("{}", *sorted.at(expected_median_idx));

//     // assert(
//     //     *sorted.at(expected_median_idx) == expected_median_value, 
//     //     'error');

//     // show_array(data);
//     // show_array(sorted);
// }

// #[test]
// #[available_gas(30000000)]
// fn test_constructor() {
// //         // Deploy ContractA
// //         let mut calldata = ArrayTrait::new();
// //         calldata.append(address_b.into());
// //         let (address_a, _) = deploy_syscall(
// //             ContractA::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false
// //         )
// //             .unwrap();

// //         // contract_a is of type IContractADispatcher. Its methods are defined in IContractADispatcherTrait.
// //         let contract_a = IContractADispatcher { contract_address: address_a };
// }