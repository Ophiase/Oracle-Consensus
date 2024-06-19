use starknet::syscalls::deploy_syscall;
use starknet::ContractAddress;

use alexandria_math::wad_ray_math::{
    ray_div, ray_mul, wad_div, wad_mul, 
    ray_to_wad, wad_to_ray, ray, wad, 
    half_ray, half_wad
};
use alexandria_math::{pow};
use alexandria_sorting::{QuickSort, MergeSort};
    
use oracle_consensus::math::{
    median, sqrt, interval_check
};
use oracle_consensus::utils::{
    show_array, show_address_array,
    show_replacement_propositions,
    show_oracle_array
};
use oracle_consensus::structs::{
    Oracle, VoteCoordinate
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

fn deploy_contract() -> IOracleConsensus1DCDispatcher {
    // let calldata = Calldata.compile("constructor", {
    //     admins: array!['Akashi', 'Ozu', 'Higuchi'].span(),
    //     enable_oracle_replacement: true,
    //     required_majority: 2,
    //     n_failing_oracles: 2,
    //     oracles: array![
    //         'oracle_00', 'oracle_01', 'oracle_02', 
    //         'oracle_03', 'oracle_04', 'oracle_05', 
    //         'oracle_06'].span()
    // });

    let mut calldata = array![
        // admins
        3,
        'Akashi','Ozu', 'Higuchi',

        1, // enable_oracle_replacement
        2, // required_majority
        2, // n_failing_oracles

        // ORACLES
        7,
        'oracle_00', 'oracle_01', 'oracle_02', 'oracle_03',
        'oracle_04', 'oracle_05', 'oracle_06',
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

fn fill_oracle_predictions(dispatcher : IOracleConsensus1DCDispatcher, predictions : @Array<u256>) {
    let mut i = 0;

    let oracles = dispatcher.get_oracle_list();

    loop {
        if i == predictions.len() { break(); }

        starknet::testing::set_contract_address(*oracles.at(i));
        dispatcher.update_prediction( *predictions.at(i));

        i += 1;
    }
}

#[test]
#[available_gas(30000000)]
fn test_basic_execution() {
    let dispatcher = deploy_contract();

    let _admin_0 = util_felt_addr('Akashi');
    let _admin_1 = util_felt_addr('Ozu');
    let _admin_2 = util_felt_addr('Higuchi');

    starknet::testing::set_contract_address(_admin_0);

    println!("Init");
    println!("----------------------");
    show_address_array(dispatcher.get_admin_list());
    show_address_array(dispatcher.get_oracle_list());
    show_replacement_propositions(dispatcher.get_replacement_propositions());
    show_oracle_array(dispatcher.get_oracle_value_list(), true, true, true, true);
    println!("----------------------");

    assert!(dispatcher.consensus_active() == false, "error");
    assert!(dispatcher.get_consensus_value() == 0, "error");
    assert!(dispatcher.get_first_pass_consensus_reliability() == 0, "error");
    assert!(dispatcher.get_second_pass_consensus_reliability() == 0, "error");

    // -------------------
    // CHECK VOTES

    // auto generated distribution 
    // in drafts/beta_kumaraswamy_algorithm_demo.ipynb
    let predictions : Array<u256> = array![
        283665728520555872, 444978808172189056, 
        456312246206240704, 577063812648590720, 
        353406129181719872, 439786381700248704, 
        422154759299759040, 613738354100202112, 
        457460183532055616, 999874248921110656, 
        563834305654715072, 625593778275535872, 
        606902168251554432, 301967755140784896, 
        995508477591357056, 406049235292915200, 
        462012580658951104, 465891674064305792, 
        670021933609384064, 595183478581031296
    ];

    fill_oracle_predictions(dispatcher, @predictions);
    starknet::testing::set_contract_address(_admin_0);

    // show_oracle_array(dispatcher.get_oracle_value_list(), true, true, true, true);

    // println!(dispatcher.get)

    // --------------------
    // CHECK REPLACEMENT


}