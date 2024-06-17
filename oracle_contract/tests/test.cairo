// use starknet::syscalls::deploy_syscall;
// use starknet::ContractAddress;
// use super::ContractA;
// use super::IContractADispatcher;
// use super::IContractADispatcherTrait;
// use super::ContractB;
// use super::IContractBDispatcher;
// use super::IContractBDispatcherTrait;

use oracle_consensus::math::data_science::{addition};

#[test]
#[available_gas(30000000)]
fn test_module() {
    println!("timide");

    let x = 3_u128;
    let y = 10_u128;

    let result = addition(x, y);

    assert(result == 13_u128, 'nooo');
    // assert(false, 'naa');
}

#[test]
#[available_gas(30000000)]
fn test_something() {
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