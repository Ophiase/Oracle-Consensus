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