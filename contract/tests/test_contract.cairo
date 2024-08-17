use starknet::syscalls::deploy_syscall;
use starknet::ContractAddress;

use oracle_consensus::signed_decimal::{
    I128Div, I128Display, I128SignedBasics, unsigned_to_signed, wsad_div, wsad_mul, wsad, half_wsad
};
use alexandria_math::{pow};
use alexandria_sorting::{QuickSort, MergeSort};

use oracle_consensus::math::{
    median, sqrt, interval_check, FeltVector, WsadVector, IFeltVectorBasics, IWsadVectorBasics
};
use oracle_consensus::utils::{
    show_array, show_address_array, show_replacement_propositions, show_nd_felt_oracle_array,
    felt_wsad_to_string, wsadvector_to_string,
};
use oracle_consensus::structs::{Oracle, VoteCoordinate};
use oracle_consensus::contract::{
    OracleConsensusNDS, IOracleConsensusNDSDispatcher, IOracleConsensusNDSDispatcherTrait
};

// ==============================================================================

fn util_felt_addr(addr_felt: felt252) -> ContractAddress {
    addr_felt.try_into().unwrap()
}

fn deploy_constrained_contract(dimension: felt252) -> IOracleConsensusNDSDispatcher {
    let mut calldata = array![
        // admins
        3,
        'Akashi',
        'Ozu',
        'Higuchi',
        1, // enable_oracle_replacement
        2, // required_majority
        2, // n_failing_oracles
        1, // constrained
        0, // unconstrained_max_spread
        dimension, // dimension
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
        OracleConsensusNDS::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false
    )
        .unwrap();
    let contract0 = IOracleConsensusNDSDispatcher { contract_address: address0 };

    contract0
}

fn deploy_unconstrained_contract() -> IOracleConsensusNDSDispatcher {
    let mut calldata = array![
        // admins
        3,
        'Akashi',
        'Ozu',
        'Higuchi',
        1, // enable_oracle_replacement
        2, // required_majority
        2, // n_failing_oracles
        0, // constrained
        ((wsad() * 10_i128)).as_felt(), // 
        2, // dimension
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
        OracleConsensusNDS::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false
    )
        .unwrap();
    let contract0 = IOracleConsensusNDSDispatcher { contract_address: address0 };

    contract0
}

// ==============================================================================

fn fill_oracle_predictions(
    dispatcher: IOracleConsensusNDSDispatcher, predictions: @Array<FeltVector>
) {
    let mut i = 0;

    let oracles = dispatcher.get_oracle_list();

    loop {
        if i == predictions.len() {
            break ();
        }

        starknet::testing::set_contract_address(*oracles.at(i));
        dispatcher.update_prediction(*predictions.at(i));

        i += 1;
    }
}


#[test]
#[available_gas(800000000)]
fn test_constrained_basic_execution() {
    let VERBOSE: bool = false;

    let dispatcher = deploy_constrained_contract(2);

    let _admin_0 = util_felt_addr('Akashi');
    let _admin_1 = util_felt_addr('Ozu');
    let _admin_2 = util_felt_addr('Higuchi');

    starknet::testing::set_contract_address(_admin_0);

    if VERBOSE {
        println!("----------------------");
        println!("Init");
        println!("----------------------");
        show_address_array(dispatcher.get_admin_list());
        show_address_array(dispatcher.get_oracle_list());
        show_replacement_propositions(dispatcher.get_replacement_propositions());
        show_nd_felt_oracle_array(dispatcher.get_oracle_value_list(), true, true, true, true);
        println!("----------------------");
    }

    assert!(dispatcher.consensus_active() == false, "consensus_active");
    assert!(dispatcher.get_consensus_value() == array![0, 0].span(), "consensus_value");
    assert!(dispatcher.get_first_pass_consensus_reliability() == 0, "first_pass_consensus_value");
    assert!(dispatcher.get_second_pass_consensus_reliability() == 0, "second_pass_consensus_value");

    // -------------------
    // CHECK VOTES

    // auto generated distribution (essence = [0.4, 0.2]) with high dispersity
    // in drafts/beta_kumaraswamy_algorithm_demo.ipynb
    let predictions: Array<FeltVector> = array![
        array![492954, 334814].span(),
        array![437692, 410445].span(),
        array![967794, 564219].span(),
        array![431029, 387225].span(),
        array![487609, 337990].span(),
        array![284178, 485072].span(),
        array![990059, 558600].span(),
    ];

    // println!("V : {}", wsadvector_to_string((*predictions.at(0)).as_wsad()));
    // println!("V : {}", wsadvector_to_string((*predictions.at(1)).as_wsad()));
    // println!("V : {}", wsadvector_to_string((*predictions.at(2)).as_wsad()));
    // println!("V : {}", wsadvector_to_string((*predictions.at(3)).as_wsad()));
    // println!("V : {}", wsadvector_to_string((*predictions.at(4)).as_wsad()));

    fill_oracle_predictions(dispatcher, @predictions);
    starknet::testing::set_contract_address(_admin_0);

    if VERBOSE {
        show_nd_felt_oracle_array(dispatcher.get_oracle_value_list(), true, true, true, true);
        println!("----------------------");
        println!("consensus_active : {}", dispatcher.consensus_active());
        println!(
            "get_consensus_value : {}",
            wsadvector_to_string(dispatcher.get_consensus_value().as_wsad())
        );
        println!(
            "get_first_pass_consensus_reliability : {}",
            felt_wsad_to_string(dispatcher.get_first_pass_consensus_reliability(), 3)
        );
        println!(
            "get_second_pass_consensus_reliability : {}",
            felt_wsad_to_string(dispatcher.get_second_pass_consensus_reliability(), 3)
        );
        println!("----------------------");
    }

    // notice that the second pass reliability is lower than for the 1d case : 0.798
    // its normal, the number of dimensions increase the required number of oracles
    // to fill the space

    // --------------------
    // CHECK REPLACEMENT

    let old_oracle = 6_usize;
    let old_oracle_addr = util_felt_addr('oracle_06');
    let new_oracle = util_felt_addr('oracle_XX');

    dispatcher.update_proposition(Option::Some((old_oracle, new_oracle)));
    assert!(*dispatcher.get_oracle_list().at(old_oracle) == old_oracle_addr, "error");
    dispatcher.vote_for_a_proposition(0, true);
    assert!(*dispatcher.get_oracle_list().at(old_oracle) == old_oracle_addr, "error");
    starknet::testing::set_contract_address(_admin_1);
    dispatcher.vote_for_a_proposition(0, true);

    if VERBOSE {
        println!("----------------------");
        show_replacement_propositions(dispatcher.get_replacement_propositions());
        show_nd_felt_oracle_array(dispatcher.get_oracle_value_list(), true, true, true, true);
        println!("----------------------");
    }

    assert!(*dispatcher.get_oracle_list().at(old_oracle) == new_oracle, "error");
// check for more replacements ?
}


#[test]
#[available_gas(100000000)]
fn test_unconstrained_basic_execution() {
    let VERBOSE: bool = false;

    let dispatcher = deploy_unconstrained_contract();

    let _admin_0 = util_felt_addr('Akashi');
    let _admin_1 = util_felt_addr('Ozu');
    let _admin_2 = util_felt_addr('Higuchi');

    starknet::testing::set_contract_address(_admin_0);

    if VERBOSE {
        println!("----------------------");
        println!("Init");
        println!("----------------------");
        show_address_array(dispatcher.get_admin_list());
        show_address_array(dispatcher.get_oracle_list());
        show_replacement_propositions(dispatcher.get_replacement_propositions());
        show_nd_felt_oracle_array(dispatcher.get_oracle_value_list(), true, true, true, true);
        println!("----------------------");
    }

    assert!(dispatcher.consensus_active() == false, "consensus_active");
    assert!(dispatcher.get_consensus_value() == array![0, 0].span(), "consensus_value");
    assert!(dispatcher.get_first_pass_consensus_reliability() == 0, "first_pass_consensus_value");
    assert!(dispatcher.get_second_pass_consensus_reliability() == 0, "second_pass_consensus_value");

    // -------------------
    // CHECK VOTES

    // auto generated distribution with high dispersity
    // mu = [20, 12] | sigma = [3, 2]
    // in drafts/gaussian_distribution_for_tests.ipynb
    let predictions: Array<FeltVector> = array![
        array![20202804, 16401132].span(),
        array![25630344, 13501687].span(),
        array![22210028, 7472938].span(),
        array![18138928, 16619949].span(),
        array![19527275, 10116085].span(),
        array![22084988, 7901585].span(),
        array![19549281, 10104796].span(),
    ];

    fill_oracle_predictions(dispatcher, @predictions);
    starknet::testing::set_contract_address(_admin_0);

    if VERBOSE {
        show_nd_felt_oracle_array(dispatcher.get_oracle_value_list(), true, true, true, true);
        println!("----------------------");
        println!("consensus_active : {}", dispatcher.consensus_active());
        println!(
            "get_consensus_value : {}",
            wsadvector_to_string(dispatcher.get_consensus_value().as_wsad())
        );
        println!(
            "get_first_pass_consensus_reliability : {}",
            felt_wsad_to_string(dispatcher.get_first_pass_consensus_reliability(), 3)
        );
        println!(
            "get_second_pass_consensus_reliability : {}",
            felt_wsad_to_string(dispatcher.get_second_pass_consensus_reliability(), 3)
        );
        println!("----------------------");
    }

    // results :
    // mu = (20.714, 10.4)
    // first pass std : 0.533
    // second pass std : 0.647

    // --------------------
    // CHECK REPLACEMENT

    let old_oracle = 6_usize;
    let old_oracle_addr = util_felt_addr('oracle_06');
    let new_oracle = util_felt_addr('oracle_XX');

    dispatcher.update_proposition(Option::Some((old_oracle, new_oracle)));
    assert!(*dispatcher.get_oracle_list().at(old_oracle) == old_oracle_addr, "error");
    dispatcher.vote_for_a_proposition(0, true);
    assert!(*dispatcher.get_oracle_list().at(old_oracle) == old_oracle_addr, "error");
    starknet::testing::set_contract_address(_admin_1);
    dispatcher.vote_for_a_proposition(0, true);

    if VERBOSE {
        println!("----------------------");
        show_replacement_propositions(dispatcher.get_replacement_propositions());
        show_nd_felt_oracle_array(dispatcher.get_oracle_value_list(), true, true, true, true);
        println!("----------------------");
    }

    assert!(*dispatcher.get_oracle_list().at(old_oracle) == new_oracle, "error");
// check for more replacements ?
}

#[test]
#[available_gas(180000000)]
fn test_constrained_high_dimension_execution() {
    let VERBOSE: bool = false;

    let dispatcher = deploy_constrained_contract(6);

    let _admin_0 = util_felt_addr('Akashi');
    let _admin_1 = util_felt_addr('Ozu');
    let _admin_2 = util_felt_addr('Higuchi');

    starknet::testing::set_contract_address(_admin_0);

    if VERBOSE {
        println!("----------------------");
        println!("Init");
        println!("----------------------");
        show_address_array(dispatcher.get_admin_list());
        show_address_array(dispatcher.get_oracle_list());
        show_replacement_propositions(dispatcher.get_replacement_propositions());
        show_nd_felt_oracle_array(dispatcher.get_oracle_value_list(), true, true, true, true);
        println!("----------------------");
    }

    assert!(dispatcher.consensus_active() == false, "consensus_active");
    assert!(dispatcher.get_consensus_value() == array![0, 0, 0, 0, 0, 0].span(), "consensus_value");
    assert!(dispatcher.get_skewness() == array![0, 0, 0, 0, 0, 0].span(), "skewness");
    assert!(dispatcher.get_kurtosis() == array![0, 0, 0, 0, 0, 0].span(), "kurtosis");
    assert!(dispatcher.get_first_pass_consensus_reliability() == 0, "first_pass_consensus_value");
    assert!(dispatcher.get_second_pass_consensus_reliability() == 0, "second_pass_consensus_value");

    if VERBOSE {
        println!("check ok..");
    }

    // -------------------
    // CHECK VOTES

    // auto generated distribution (essence = [0.4, 0.2]) with high dispersity
    // in drafts/beta_kumaraswamy_algorithm_demo.ipynb
    let predictions: Array<FeltVector> = array![
        array![444545, 54331, 321181, 93574, 58452, 27915].span(),
        array![650669, 423808, 458776, 619552, 867737, 117888].span(),
        array![360849, 61583, 445841, 66219, 44810, 20695].span(),
        array![442049, 38888, 420748, 44428, 30533, 23350].span(),
        array![260736, 619146, 110294, 505377, 699358, 584216].span(),
        array![267262, 48987, 551858, 74674, 26617, 30598].span(),
        array![268500, 45379, 495298, 145887, 22256, 22678].span()
    ];

    // println!("V : {}", wsadvector_to_string((*predictions.at(0)).as_wsad()));
    // println!("V : {}", wsadvector_to_string((*predictions.at(1)).as_wsad()));
    // println!("V : {}", wsadvector_to_string((*predictions.at(2)).as_wsad()));
    // println!("V : {}", wsadvector_to_string((*predictions.at(3)).as_wsad()));
    // println!("V : {}", wsadvector_to_string((*predictions.at(4)).as_wsad()));

    fill_oracle_predictions(dispatcher, @predictions);
    starknet::testing::set_contract_address(_admin_0);

    if VERBOSE {
        show_nd_felt_oracle_array(dispatcher.get_oracle_value_list(), true, true, true, true);
        println!("----------------------");
        println!("consensus_active : {}", dispatcher.consensus_active());
        println!(
            "get_consensus_value : {}",
            wsadvector_to_string(dispatcher.get_consensus_value().as_wsad())
        );
        println!(
            "get_first_pass_consensus_reliability : {}",
            felt_wsad_to_string(dispatcher.get_first_pass_consensus_reliability(), 3)
        );
        println!(
            "get_second_pass_consensus_reliability : {}",
            felt_wsad_to_string(dispatcher.get_second_pass_consensus_reliability(), 3)
        );

        println!("get_skewness : {}", wsadvector_to_string(dispatcher.get_skewness().as_wsad()));
        println!("get_kurtosis : {}", wsadvector_to_string(dispatcher.get_kurtosis().as_wsad()));

        println!("----------------------");
    }
}
