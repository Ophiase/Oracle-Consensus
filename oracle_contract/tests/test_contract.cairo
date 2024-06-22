use starknet::syscalls::deploy_syscall;
use starknet::ContractAddress;

use oracle_consensus::signed_wad_ray::{
    I128Div, I128Display, I128SignedBasics, unsigned_to_signed,
    ray_div, ray_mul, wad_div, wad_mul, ray_to_wad, wad_to_ray, ray, wad, half_ray, half_wad
};
use alexandria_math::{pow};
use alexandria_sorting::{QuickSort, MergeSort};
    
use oracle_consensus::math::{
    median, sqrt, interval_check, FeltVector, WadVector, IFeltVectorBasics, IWadVectorBasics
};
use oracle_consensus::utils::{
    show_array, show_address_array,
    show_replacement_propositions,
    show_nd_felt_oracle_array, felt_wad_to_string,
    wadvector_to_string,
};
use oracle_consensus::structs::{
    Oracle, VoteCoordinate
};
use oracle_consensus::contract::{
    OracleConsensusNDS,
    IOracleConsensusNDSDispatcher,
    IOracleConsensusNDSDispatcherTrait
};

// ==============================================================================

fn util_felt_addr(addr_felt: felt252) -> ContractAddress {
    addr_felt.try_into().unwrap()
}

fn deploy_constrained_contract(dimension : felt252) -> IOracleConsensusNDSDispatcher {
    let mut calldata = array![
        // admins
        3,
        'Akashi','Ozu', 'Higuchi',

        1, // enable_oracle_replacement
        2, // required_majority
        2, // n_failing_oracles
        1, // constrained
        0, // unconstrained_max_spread
        dimension, // dimension

        // ORACLES
        7,
        'oracle_00', 'oracle_01', 'oracle_02', 'oracle_03',
        'oracle_04', 'oracle_05', 'oracle_06',
    ];
    
    let (address0, _) = deploy_syscall(
        OracleConsensusNDS::TEST_CLASS_HASH.try_into().unwrap(), 
        0, calldata.span(), false
    )
        .unwrap();
    let contract0 = IOracleConsensusNDSDispatcher { contract_address: address0 };
    
    contract0
}

fn deploy_unconstrained_contract() -> IOracleConsensusNDSDispatcher {
    let mut calldata = array![
        // admins
        3,
        'Akashi','Ozu', 'Higuchi',

        1, // enable_oracle_replacement
        2, // required_majority
        2, // n_failing_oracles
        0, // constrained
        
        (
            (wad() * 10_i128)
        ).as_felt(), // 
        
        2, // dimension

        // ORACLES
        7,
        'oracle_00', 'oracle_01', 'oracle_02', 'oracle_03',
        'oracle_04', 'oracle_05', 'oracle_06',
    ];
    
    let (address0, _) = deploy_syscall(
        OracleConsensusNDS::TEST_CLASS_HASH.try_into().unwrap(), 
        0, calldata.span(), false
    )
        .unwrap();
    let contract0 = IOracleConsensusNDSDispatcher { contract_address: address0 };
    
    contract0
}

// ==============================================================================

fn fill_oracle_predictions(dispatcher : IOracleConsensusNDSDispatcher, predictions : @Array<FeltVector>) {
    let mut i = 0;

    let oracles = dispatcher.get_oracle_list();

    loop {
        if i == predictions.len() { break(); }

        starknet::testing::set_contract_address(*oracles.at(i));
        dispatcher.update_prediction( *predictions.at(i) );

        i += 1;
    }
}


#[test]
#[available_gas(80000000)]
fn test_constrained_basic_execution() {
    let VERBOSE : bool = false;

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
    let predictions : Array<FeltVector> = array![
        array![492954726014948928, 334814622544049920].span(), 
        array![437692571090454848, 410445303499263744].span(), 
        array![967794129545080320, 564219801545577856].span(), 
        array![431029386438835904, 387225378439864320].span(), 
        array![487609527760088832, 337990045876390976].span(), 
        array![284178293988284864, 485072442019714880].span(), 
        array![990059578132686080, 558600821433541504].span(),
        // array![41771899326704440, 2753696149738971].span(),
        // array![906700648391441792, 107009062792520656].span(),
        // array![12893986527342350, 3883828797552269].span(),
        // array![43323881679680192, 3157344275678042].span(),
        // array![16353277035523206, 3597251237079035].span(),
        // array![345874654443167424, 77803999719279424].span(),
        // array![10893020476214588, 3568622465536464].span(),
    ]; 

    // println!("V : {}", wadvector_to_string((*predictions.at(0)).as_wad()));
    // println!("V : {}", wadvector_to_string((*predictions.at(1)).as_wad()));
    // println!("V : {}", wadvector_to_string((*predictions.at(2)).as_wad()));
    // println!("V : {}", wadvector_to_string((*predictions.at(3)).as_wad()));
    // println!("V : {}", wadvector_to_string((*predictions.at(4)).as_wad()));

    //     array![437936475867688192, 349587800435125504].span(), 
    //     array![473744510163695040, 548875132636806080].span(), 
    //     array![509627983637117376, 498029458536038720].span(), 
    //     array![224466696155920480, 444511153973982912].span(), 
    //     array![400820300193803712, 339168887123537536].span(), 
    //     array![434396024059996352, 447884357777344576].span(), 
    //     array![509726631189617792, 420684924642709760].span(), 
    //     array![467164599889406912, 466111010479481472].span(), 
    //     array![639279334823607168, 970818959481954432].span(), 
    //     array![370413093299700928, 342592017577027840].span(), 
    //     array![389977605682022656, 505351074177922112].span(), 
    //     array![284526985745200640, 416047121521614464].span(), 
    //     array![747220228495325312, 212304990280389088].span()
    // ];

    fill_oracle_predictions(dispatcher, @predictions);
    starknet::testing::set_contract_address(_admin_0);

    if VERBOSE {
        show_nd_felt_oracle_array(dispatcher.get_oracle_value_list(), true, true, true, true);
        println!("----------------------");
        println!("consensus_active : {}", dispatcher.consensus_active());
        println!("get_consensus_value : {}", wadvector_to_string(dispatcher.get_consensus_value().as_wad()));
        println!("get_first_pass_consensus_reliability : {}", felt_wad_to_string(dispatcher.get_first_pass_consensus_reliability(), 3));
        println!("get_second_pass_consensus_reliability : {}", felt_wad_to_string(dispatcher.get_second_pass_consensus_reliability(), 3));
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
    let VERBOSE : bool = false;

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
    let predictions : Array<FeltVector> = array![
        array![20202804800890433536, 16401132114237284352].span(), 
        array![25630344446076841984, 13501687730243987456].span(), 
        array![22210028458728640512, 7472938283472651264].span(), 
        array![18138928443303946240, 16619949381570797568].span(), 
        array![19527275933443088384, 10116085583420502016].span(), 
        array![22084988846100205568, 7901585917976843264].span(), 
        array![19549281315874115584, 10104796416691441664].span(), 
    ]; 
        // array![17042861560438452224, 10343103521787559936].span(), 
        // array![20715973600052207616, 13098087743307982848].span(), 
        // array![22885973508821749760, 10415377474596722688].span(), 
        // array![18717628981156040704, 10909335620244258816].span(), 
        // array![16614914621277229056, 13016784356205508608].span(), 
        // array![22461185162366541824, 12790695160662409216].span(), 
        // array![19837245782601994240, 10175692692883621888].span(), 
        // array![18138521782884300800, 10192686820753297408].span(), 
        // array![22018233073020952576, 13257341164889929728].span(), 
        // array![18250960239560206336, 11914937744510298112].span(), 
        // array![15441065766566420480, 9676035838544226304].span(), 
        // array![23984360514276814848, 14442951399485399040].span(), 
        // array![18264478796466845696, 12973173357007304704].span(), 
    // ];
    fill_oracle_predictions(dispatcher, @predictions);
    starknet::testing::set_contract_address(_admin_0);

    if VERBOSE {
        show_nd_felt_oracle_array(dispatcher.get_oracle_value_list(), true, true, true, true);
        println!("----------------------");
        println!("consensus_active : {}", dispatcher.consensus_active());
        println!("get_consensus_value : {}", wadvector_to_string(dispatcher.get_consensus_value().as_wad()));
        println!("get_first_pass_consensus_reliability : {}", felt_wad_to_string(dispatcher.get_first_pass_consensus_reliability(), 3));
        println!("get_second_pass_consensus_reliability : {}", felt_wad_to_string(dispatcher.get_second_pass_consensus_reliability(), 3));
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
    let VERBOSE : bool = false;

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
    assert!(dispatcher.get_first_pass_consensus_reliability() == 0, "first_pass_consensus_value");
    assert!(dispatcher.get_second_pass_consensus_reliability() == 0, "second_pass_consensus_value");

    // -------------------
    // CHECK VOTES

    // auto generated distribution (essence = [0.4, 0.2]) with high dispersity
    // in drafts/beta_kumaraswamy_algorithm_demo.ipynb
    let predictions : Array<FeltVector> = array![
        array![444545450094968000, 54331720669767392, 321181078572394112, 93574367249953184, 58452039497953944, 27915343914963376].span(),
        array![650669127808916224, 423808048148146112, 458776506491212608, 619552493748596608, 867737597105629696, 117888125945635584].span(),
        array![360849081405407488, 61583929809227872, 445841315446630848, 66219794988070208, 44810161025411928, 20695717325251576].span(),
        array![442049577864458944, 38888720223952632, 420748899304341504, 44428919781444840, 30533379497426468, 23350503328375608].span(),
        array![260736445564093152, 619146099575272576, 110294980129303280, 505377314776397440, 699358821457823104, 584216095123548800].span(),
        array![267262952031874432, 48987557540192640, 551858409493303232, 74674503261155552, 26617771556882452, 30598806116591560].span(),
        array![268500121655803936, 45379019562329192, 495298026521257472, 145887867344075584, 22256102607492420, 22678862309041344].span()
    ]; 

    // println!("V : {}", wadvector_to_string((*predictions.at(0)).as_wad()));
    // println!("V : {}", wadvector_to_string((*predictions.at(1)).as_wad()));
    // println!("V : {}", wadvector_to_string((*predictions.at(2)).as_wad()));
    // println!("V : {}", wadvector_to_string((*predictions.at(3)).as_wad()));
    // println!("V : {}", wadvector_to_string((*predictions.at(4)).as_wad()));


    fill_oracle_predictions(dispatcher, @predictions);
    starknet::testing::set_contract_address(_admin_0);

    if VERBOSE {
        show_nd_felt_oracle_array(dispatcher.get_oracle_value_list(), true, true, true, true);
        println!("----------------------");
        println!("consensus_active : {}", dispatcher.consensus_active());
        println!("get_consensus_value : {}", wadvector_to_string(dispatcher.get_consensus_value().as_wad()));
        println!("get_first_pass_consensus_reliability : {}", felt_wad_to_string(dispatcher.get_first_pass_consensus_reliability(), 3));
        println!("get_second_pass_consensus_reliability : {}", felt_wad_to_string(dispatcher.get_second_pass_consensus_reliability(), 3));
        println!("----------------------");
    }
}
