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
use oracle_consensus::utils::{
    show_array, show_address_array
};
use oracle_consensus::contract_1d_constrained::{
    OracleConsensus1DC,
    IOracleConsensus1DCDispatcher,
    IOracleConsensus1DCDispatcherTrait
};

// ==============================================================================

fn util_felt_addr(addr_felt: felt252) -> ContractAddress {
    addr_felt.try_into().unwrap()
}

// fn add_span_to_calldata(array : Span<felt252>, ref mut calldata : Array<felt252>) {
// }

fn deploy_contract() -> IOracleConsensus1DCDispatcher {
    let mut calldata = array![
        // ADMINS
        3,
        'Akashi',
        'Ozu',
        'Higuchi',

        1, // enable_oracle_replacement
        2, // required_majority
        2, // n_failing oracles

        // ORACLES
        7,
        'oracle_00',
        'oracle_01',
        'oracle_02',
        'oracle_03',
        'oracle_04',
        'oracle_05',
        'oracle_06',
    ];
    
    let (address0, _) = deploy_syscall(
        OracleConsensus1DC::TEST_CLASS_HASH.try_into().unwrap(), 
        0, calldata.span(), false
    )
        .unwrap();
    let contract0 = IOracleConsensus1DCDispatcher { contract_address: address0 };
    
    contract0
}

// ==============================================================================

#[test]
#[available_gas(30000000)]
fn test_constructor() {
    let dispatcher = deploy_contract();

    let admins = dispatcher.get_admin_list();
    show_address_array(admins);
}