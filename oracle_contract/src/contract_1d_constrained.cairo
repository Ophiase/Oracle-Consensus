#[starknet::interface]
trait IOracleConsensus<TContractState> {
    fn update_prediction(ref self: TContractState, prediction : u256);
    
    fn consensus_active(self: @TContractState) -> bool;
    fn get_consensus_value(self: @TContractState) -> u256;
    fn get_first_pass_consensus_reliability(self: @TContractState) -> u256;
    fn get_second_pass_consensus_reliability(self: @TContractState) -> u256;

    
    // fn update_proposition();
    // fn vote_for_a_proposition();
    //
    // fn get_propositions();
    // fn get_a_specific_proposition
}

#[starknet::contract]
mod oracle_consensus {
    // use core::option::Option::{None, Some};
    use core::option::OptionTrait;
    use starknet::ContractAddress;
    use starknet::syscalls::storage_read_syscall;
    use starknet::syscalls::storage_write_syscall;
    use starknet::get_caller_address;

    use oracle_consensus::math::data_science::{median, spread, average};
    use oracle_consensus::sort::IndexedMergeSort;

    use alexandria_math::wad_ray_math::{
        ray_div, ray_mul, wad_div, wad_mul, ray_to_wad, wad_to_ray, ray, wad, half_ray, half_wad
    };
    use alexandria_math::{pow};


    #[derive(Drop, Serde, starknet::Store)]
    struct Oracle {
        address : ContractAddress,
        value: u256, // wad convention
        enabled: bool, // have a value ?
        reliable: bool // pass the consensus ?
    }
    
    #[storage]
    struct Storage {
        n_admins : usize,
        admins : LegacyMap<usize, ContractAddress>,
        
        enable_oracle_replacement : bool,
        required_majority : usize,
        
        n_failing_oracles : usize,
        n_oracles : usize,
        oracles: LegacyMap<usize, Oracle>,
 
        n_active_oracles : usize,
        consensus_active : bool,

        consensus_value: u256, // wad convention
        consensus_reliability_second_pass : u256, // wad convention
        consensus_reliability_first_pass : u256 // wad convention
    }

    // ==============================================================================

    fn fill_admins(ref self: ContractState, array : Span<ContractAddress>) {
        let mut i = 0;
        loop {
            if i == array.len() {
                break();
            }
            
            let value = *array.at(i);
            self.admins.write(i, value);

            i += 1;
        };

        self.n_admins.write(array.len());
    }

    fn fill_oracles(ref self: ContractState, array : Span<ContractAddress>) {
        let mut i = 0;
        loop {
            if i == array.len() {
                break();
            }
            
            let oracle = Oracle {
                address : *array.at(i),
                value : 0_u256,
                enabled : false,
                reliable : true
            };

            self.oracles.write(i, oracle);

            i += 1;
        };

        self.n_active_oracles.write(0_usize);
        self.n_oracles.write(array.len());
    }
    
    #[constructor]
    fn constructor(ref self: ContractState, 
        admins : Span<ContractAddress>,

        enable_oracle_replacement : bool,
        required_majority : usize,
        n_failing_oracles : usize, 
        
        oracles: Span<ContractAddress>,
    ) {

        fill_admins(ref self, admins);
        fill_oracles(ref self, oracles);
        
        self.enable_oracle_replacement.write(enable_oracle_replacement);
        self.required_majority.write(required_majority);
        self.n_failing_oracles.write(n_failing_oracles);
        
        self.consensus_value.write(0_u256);
        self.consensus_reliability_first_pass.write(0_u256);
        self.consensus_reliability_second_pass.write(0_u256);
    }

    // ------------------------------------------------------------------------------
    // ORALCE CONSENSUS
    // ------------------------------------------------------------------------------

    // require that all oracle have already commited once
    fn oracles_optional_values(self: @ContractState) -> Array<Option<u256>> {
        let mut result = ArrayTrait::new();
     
        let mut i = 0;
        loop {
            if i == self.n_oracles.read() {
                break();
            }

            let oracle = self.oracles.read(i);
            if oracle.reliable {
                result.append(Option::Some(oracle.value));
            } else {
                result.append(Option::None);
            }
            
            i += 1;
        };

        result
    }

    // require that all oracle have already commited once
    fn oracles_reliable_values(self: @ContractState) -> Array<u256> {
        let mut result = ArrayTrait::new();
     
        let mut i = 0;
        loop {
            if i == self.n_oracles.read() {
                break();
            }

            let oracle = self.oracles.read(i);
            if oracle.reliable {
                result.append(oracle.value);
            }
            
            i += 1;
        };

        result
    }

    fn update_a_single_oracle(ref self: ContractState, oracle_index : @usize, prediction : @u256) {
        let mut oracle = self.oracles.read(*oracle_index);
        
        if !oracle.enabled {
            self.n_active_oracles.write(self.n_active_oracles.read() + 1);
        }

        oracle.value = *prediction;
        oracle.enabled = true;
        
        self.oracles.write(*oracle_index, oracle);
    }

    fn update_oracles_reliability(ref self: ContractState, scores : @Array<(usize, u256)>) {
        let treshold = self.n_oracles.read() - self.n_failing_oracles.read();

        let mut i = 0;
        loop {
            if i == self.n_oracles.read() {
                break();
            }
            
            let (which_oracle, _foo) = *scores.at(i);
            
            let mut oracle = self.oracles.read(which_oracle);
            oracle.reliable = (i < treshold);

            self.oracles.write(which_oracle, oracle);
            
            i += 1;
        };
    }


    fn update_consensus(ref self: ContractState, oracle_index : @usize, prediction : @u256) {
        update_a_single_oracle(ref self, oracle_index, prediction);

        if self.n_oracles.read() != self.n_active_oracles.read() {
            return();
        }


        // ----------------------------
        // FIRST PASS
        // ----------------------------

        let oracles_values = oracles_reliable_values(@self);

        // ESSENCE

        let essence_first_pass = median(@oracles_values);
        
        // SPREAD

        let spread_values = spread(@oracles_values, @essence_first_pass);
        let reliability_first_pass = 1 - (average(@spread_values) * 2);
        interval_check(@reliability_first_pass);
        self.consensus_reliability_first_pass.write(reliability_first_pass);

        let ordered_oracles = IndexedMergeSort::sort(@spread_values);
        update_oracles_reliability(ref self, @ordered_oracles);

        // ----------------------------
        // SECOND PASS
        // ----------------------------

        let reliable_values = oracles_reliable_values(@self);
        
        // ESSENCE

        let essence = median(@reliable_values);
        self.consensus_value.write(essence);

        // SPREAD

        let spread_second_pass = average(@spread(@reliable_values, @essence));
        self.consensus_reliability_second_pass.write(spread_second_pass);

        self.consensus_active.write(true);
    }


    fn find_oracle_index (self: @ContractState, oracle : @ContractAddress) -> Option<usize> {
        let mut i = 0;
        loop {
            if i == self.n_admins.read() {
                break(Option::None);
            }

            if self.oracles.read(i).address == *oracle {
                break(Option::Some(i));
            }
            
            i += 1;
        }
    }

    // ------------------------------------------------------------------------------
    // ORALCE CONSENSUS
    // ------------------------------------------------------------------------------



    // ------------------------------------------------------------------------------
    // OTHER
    // ------------------------------------------------------------------------------

    fn is_admin(self: @ContractState, user : @ContractAddress) -> bool {
        let mut i = 0;
        loop {
            if i == self.n_admins.read() {
                break(false);
            }

            if self.admins.read(i) == *user {
                break(true);
            } 
            
            i += 1;
        }
    }

    fn interval_check(value : @u256) {
        assert((0_u256 <= *value) && (*value <= 1_u256), 'interval error');
    }


    // ==============================================================================
    // PUBLIC
    // ==============================================================================



    #[abi(embed_v0)]
    impl OracleConsensusImpl of super::IOracleConsensus<ContractState> {
        fn update_prediction(ref self: ContractState, prediction : u256) {
            interval_check(@prediction);

            match find_oracle_index(@self, @get_caller_address()) {
                Option::None => assert(false, 'not an oracle'),
                Option::Some(oracle_index) => update_consensus(ref self, @oracle_index, @prediction)
            }

        }

        fn consensus_active(self: @ContractState) -> bool {
            self.consensus_active.read()
        }
        
        fn get_consensus_value(self: @ContractState) -> u256 {
            self.consensus_value.read()
        }

        // return 0 until all the oracles have voted once
        fn get_first_pass_consensus_reliability(self: @ContractState) -> u256 {
            self.consensus_reliability_first_pass.read()
        }

        // return 0 until all the oracles have voted once
        fn get_second_pass_consensus_reliability(self: @ContractState) -> u256 {
            self.consensus_reliability_second_pass.read()
        }
        
    }
}