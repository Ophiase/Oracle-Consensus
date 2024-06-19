use starknet::syscalls::deploy_syscall;
use starknet::ContractAddress;

use alexandria_math::wad_ray_math::{
    ray_div, ray_mul, wad_div, wad_mul, 
    ray_to_wad, wad_to_ray, ray, wad, 
    half_ray, half_wad
};
use alexandria_math::{pow};
use alexandria_sorting::{QuickSort, MergeSort};
    
use oracle_consensus::math::data_science::{median, sqrt};
use oracle_consensus::contract_1d_constrained::IOracleConsensus;

#[test]
#[available_gas(30000000)]
fn test_constructor() {
    // Constructor

    // let admins : Span<ContractAddress> = array![
    //     // 0.try_into().unwrap()
    // ].span();
    // let enable_oracle_replacement = true;
    // let required_majority = 2;
    // let n_failing_oracles = 3;
    // let oracles : Span<ContractAddress> = array![

    // ].span();

    // Deploy Contract
    // let mut calldata = ArrayTrait::new();
    // calldata.append();


    
    // let (address, _) = deploy_syscall(
    //     OracleConsensusImpl::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false
    // )
    //     .unwrap();

    // // contract_a is of type IContractADispatcher. Its methods are defined in IContractADispatcherTrait.
    // let contract = IOracleConsensusDispatcher {
    //      contract_address: address 
    // };
}