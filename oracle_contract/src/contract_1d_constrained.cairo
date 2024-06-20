use starknet::ContractAddress;

#[starknet::interface]
trait IOracleConsensus1DC<TContractState> {
    fn update_prediction(ref self: TContractState, prediction : i128);
    
    fn consensus_active(self: @TContractState) -> bool;
    fn get_consensus_value(self: @TContractState) -> i128;
    fn get_first_pass_consensus_reliability(self: @TContractState) -> i128;
    fn get_second_pass_consensus_reliability(self: @TContractState) -> i128;

    fn get_admin_list(self: @TContractState) -> Array<ContractAddress>;
    fn get_oracle_list(self: @TContractState) -> Array<ContractAddress>;
    
    // only admins can get call this one
    fn get_oracle_value_list(self: @TContractState) -> Array<OracleConsensus1DC::Oracle>;

    fn update_proposition(ref self: TContractState, proposition : Option<(usize, ContractAddress)>);
    fn vote_for_a_proposition(ref self: TContractState, which_admin : usize, support_his_proposition : bool);
    
    fn get_replacement_propositions(self: @TContractState) -> Array<Option<(usize, ContractAddress)>>;
    fn get_a_specific_proposition(self: @TContractState, which_admin : usize) -> Option<(usize, ContractAddress)>;
}


#[starknet::contract]
mod OracleConsensus1DC {
    use starknet::ContractAddress;
    // use core::option::Option::{None, Some};
    use core::option::OptionTrait;
    use core::fmt::{Display, Formatter, Error};
    use starknet::syscalls::storage_read_syscall;
    use starknet::syscalls::storage_write_syscall;
    use starknet::get_caller_address;

    use oracle_consensus::structs::{
        Oracle, VoteCoordinate
    };

    use starknet::contract_address::{Felt252TryIntoContractAddress, ContractAddressIntoFelt252};

    use oracle_consensus::math::{median, smooth_median, quadratic_risk, average, interval_check, sqrt};
    use oracle_consensus::sort::IndexedMergeSort;
    use oracle_consensus::utils::{fst, snd, contractaddress_to_bytearray, wad_to_string};
    use oracle_consensus::signed_wad_ray::{
        I128Div, I128Display, I128SignedBasics, unsigned_to_signed,
        ray_div, ray_mul, wad_div, wad_mul, ray_to_wad, wad_to_ray, ray, wad, half_ray, half_wad
    };
    use alexandria_math::{pow};
    
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

        vote_matrix : LegacyMap<VoteCoordinate, bool>,
        replacement_propositions : LegacyMap<usize, Option<(usize, ContractAddress)>>,

        consensus_value: i128, // wad convention
        consensus_reliability_second_pass : i128, // wad convention
        consensus_reliability_first_pass : i128 // wad convention
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
                value : 0_i128,
                enabled : false,
                reliable : true
            };

            self.oracles.write(i, oracle);

            i += 1;
        };

        self.n_active_oracles.write(0_usize);
        self.n_oracles.write(array.len());
    }

    fn reinitialize_vote_matrix(ref self: ContractState, n_admins : @usize) {
        let mut i = 0;
        loop {
            if i == *n_admins { break(); }
            let mut j = 0;
            loop {
                if j == *n_admins { break(); }

                self.vote_matrix.write(VoteCoordinate{
                    vote_emitter: i,
                    vote_receiver: j
                }, false);

                j += 1;
            };
            i += 1;
        };

    }

    fn reinitialize_replacement_propositions(ref self: ContractState, n_admins : @usize) {
        let mut i = 0;
        loop {
            if i == *n_admins { break(); }
            self.replacement_propositions.write(i, Option::None);
            i += 1;
        };
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

        reinitialize_vote_matrix(ref self, @admins.len());
        reinitialize_replacement_propositions(ref self, @admins.len());
        
        self.enable_oracle_replacement.write(enable_oracle_replacement);
        self.required_majority.write(required_majority);
        self.n_failing_oracles.write(n_failing_oracles);
        
        self.consensus_value.write(0_i128);
        self.consensus_reliability_first_pass.write(0_i128);
        self.consensus_reliability_second_pass.write(0_i128);
    }

    // ------------------------------------------------------------------------------
    // ORALCE CONSENSUS
    // ------------------------------------------------------------------------------

    // require that all oracle have already commited once
    fn oracles_optional_values(self: @ContractState) -> Array<Option<i128>> {
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
    fn compute_oracle_values(self: @ContractState, only_reliable : bool) -> Array<i128> {
        let mut result = ArrayTrait::new();
     
        let mut i = 0;
        loop {
            if i == self.n_oracles.read() {
                break();
            }

            let oracle = self.oracles.read(i);
            if oracle.reliable || !only_reliable {
                result.append(oracle.value);
            }
            
            i += 1;
        };

        result
    }

    fn update_a_single_oracle(ref self: ContractState, oracle_index : @usize, prediction : @i128) {
        let mut oracle = self.oracles.read(*oracle_index);
        
        if !oracle.enabled {
            self.n_active_oracles.write(self.n_active_oracles.read() + 1);
        }

        oracle.value = *prediction;
        oracle.enabled = true;
        
        self.oracles.write(*oracle_index, oracle);
    }

    fn update_oracles_reliability(ref self: ContractState, scores : @Array<(usize, i128)>) {
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


    fn update_consensus(ref self: ContractState, oracle_index : @usize, prediction : @i128) {
        update_a_single_oracle(ref self, oracle_index, prediction);

        if self.n_oracles.read() != self.n_active_oracles.read() {
            return();
        }
        
        // ----------------------------
        // FIRST PASS
        // ----------------------------

        let oracles_values = compute_oracle_values(@self, false);

        // ESSENCE

        let essence_first_pass = smooth_median(@oracles_values);

        // quadratic_risk
     
        let quadratic_risk_values = quadratic_risk(@oracles_values, @essence_first_pass);
        let reliability_first_pass = wad() - (sqrt(average(@quadratic_risk_values)) * 2);
        interval_check(@reliability_first_pass);
        self.consensus_reliability_first_pass.write(reliability_first_pass);
        let ordered_oracles = IndexedMergeSort::sort(@quadratic_risk_values);
        update_oracles_reliability(ref self, @ordered_oracles);

        // ----------------------------
        // SECOND PASS
        // ----------------------------
        
        let reliable_values = compute_oracle_values(@self, true);
        
        // ESSENCE

        let essence = smooth_median(@reliable_values);
        self.consensus_value.write(essence);
        
        // quadratic_risk

        let quadratic_risk_values = quadratic_risk(@reliable_values, @essence_first_pass);
        let reliability_second_pass = wad() - (sqrt(average(@quadratic_risk_values)) * 2);
        interval_check(@reliability_second_pass);
        self.consensus_reliability_second_pass.write(reliability_second_pass);
        
        self.consensus_active.write(true);        
    }

    fn find_oracle_index (self: @ContractState, oracle : @ContractAddress) -> Option<usize> {
        let mut i = 0;
        loop {
            if i == self.n_oracles.read() {
                break(Option::None);
            }

            if self.oracles.read(i).address == *oracle {
                break(Option::Some(i));
            }
            
            i += 1;
        }
    }

    fn find_admin_index (self: @ContractState, admin : @ContractAddress) -> Option<usize> {
        let mut i = 0;
        loop {
            if i == self.n_admins.read() {
                break(Option::None);
            }

            if self.admins.read(i) == *admin {
                break(Option::Some(i));
            }
            
            i += 1;
        }
    }

    // ------------------------------------------------------------------------------
    // ADMIN VOTES
    // ------------------------------------------------------------------------------

    fn check_for_replacement(ref self: ContractState, which_proposition : usize) {
        // COUNT THE NUMBER OF VOTES
        let n_admins = self.n_admins.read();
        let mut n_votes = 0;
        let mut i = 0;
        loop {
            if i == n_admins { break(); }
            
            if self.vote_matrix.read(VoteCoordinate{
                vote_emitter: i, vote_receiver: which_proposition
            }) {
                n_votes += 1;
            }

            i += 1;
        };

        // CHECK :
        if self.required_majority.read() > n_votes { return; }

        // APPLY
        let proposition = self.replacement_propositions.read(which_proposition).unwrap();
        let which_oracle = fst(proposition);
        let mut oracle = self.oracles.read(fst(proposition));
        oracle.address = snd(proposition);
        self.oracles.write(which_oracle, oracle);

        reinitialize_replacement_propositions(ref self, @n_admins);
        reinitialize_vote_matrix(ref self, @n_admins);
    }

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

    // ==============================================================================
    // PUBLIC
    // ==============================================================================



    #[abi(embed_v0)]
    impl OracleConsensusImpl of super::IOracleConsensus1DC<ContractState> {
        fn update_prediction(ref self: ContractState, prediction : i128) {
            interval_check(@prediction);

            match find_oracle_index(@self, @get_caller_address()) {
                Option::None => assert(false, 'not an oracle'),
                Option::Some(oracle_index) => update_consensus(ref self, @oracle_index, @prediction)
            }

        }

        fn consensus_active(self: @ContractState) -> bool {
            self.consensus_active.read()
        }
        
        fn get_consensus_value(self: @ContractState) -> i128 {
            self.consensus_value.read()
        }

        // return 0 until all the oracles have voted once
        fn get_first_pass_consensus_reliability(self: @ContractState) -> i128 {
            self.consensus_reliability_first_pass.read()
        }

        // return 0 until all the oracles have voted once
        fn get_second_pass_consensus_reliability(self: @ContractState) -> i128 {
            self.consensus_reliability_second_pass.read()
        }
        
        fn update_proposition(ref self: ContractState, proposition : Option<(usize, ContractAddress)>) {
            assert!(self.enable_oracle_replacement.read(), "replacement disabled");

            let admin_index = find_admin_index(@self, @get_caller_address());
            assert(!admin_index.is_none(), 'not an admin');
            let admin_index = admin_index.unwrap();

            match proposition {
                Option::None => self.replacement_propositions.write(admin_index, proposition),
                Option::Some((old_oracle_index, _new_oracle_address)) => {
                    assert(
                        (0 <= old_oracle_index) && (old_oracle_index < self.n_oracles.read()), 
                        'wrong old oracle index');

                    // TODO : check new_oracle_address exists

                    // reset the votes
                    let mut i = 0;
                    loop {
                        if i == self.n_admins.read() {
                            break();
                        }

                        self.vote_matrix.write(VoteCoordinate{
                            vote_emitter: i,
                            vote_receiver: admin_index
                        }, false);

                        i += 1;
                    };

                    // vote for itself
                    self.vote_matrix.write(VoteCoordinate{
                        vote_emitter: admin_index, vote_receiver: admin_index
                    }, true);
                    
                    self.replacement_propositions.write(admin_index, proposition);
                }
            };
            
        }

        // if a proposition get enough vote, but the oracle is not replaceable yet
        // it will be necessary to vote again for the proposition when the oracle will be replaceable
        fn vote_for_a_proposition(ref self: ContractState, which_admin : usize, support_his_proposition : bool) {
            assert!(self.enable_oracle_replacement.read(), "replacement disabled");

            let voter_index = find_admin_index(@self, @get_caller_address());
            assert(!voter_index.is_none(), 'not an admin');
            let voter_index = voter_index.unwrap();

            self.vote_matrix.write(VoteCoordinate{
                vote_emitter: voter_index,
                vote_receiver: which_admin
            }, support_his_proposition);

            check_for_replacement(ref self, which_admin);
        }

        fn get_admin_list(self: @ContractState) -> Array<ContractAddress> {
            let mut result = ArrayTrait::new();
            let n_admins = self.n_admins.read();

            let mut i = 0;
            loop {
                if i == n_admins { break(); }
                result.append(self.admins.read(i));
                i += 1;
            };
            
            result
        }

        fn get_oracle_list(self: @ContractState) -> Array<ContractAddress> {
            let mut result = ArrayTrait::new();
            let n_oracles = self.n_oracles.read();

            let mut i = 0;
            loop {
                if i == n_oracles { break(); }
                result.append(self.oracles.read(i).address);
                i += 1;
            };
            
            result
        }

        fn get_oracle_value_list(self: @ContractState) -> Array<Oracle> {
            assert(is_admin(self, @get_caller_address()), 'not admin');

            let mut result = ArrayTrait::new();
            let n_oracles = self.n_oracles.read();

            let mut i = 0;
            loop {
                if i == n_oracles { break(); }
                result.append(self.oracles.read(i));
                i += 1;
            };
            
            result
        }


        fn get_replacement_propositions(self: @ContractState) -> Array<Option<(usize, ContractAddress)>> {
            assert!(self.enable_oracle_replacement.read(), "replacement disabled");

            let mut result = ArrayTrait::new();
            let n_admins = self.n_admins.read();

            let mut i = 0;
            loop {
                if i == n_admins { break(); }
                result.append(self.replacement_propositions.read(i));
                i += 1;
            };
            
            result
        }
        
        fn get_a_specific_proposition(self: @ContractState, which_admin : usize) -> Option<(usize, ContractAddress)> {
            assert!(self.enable_oracle_replacement.read(), "replacement disabled");
            self.replacement_propositions.read(which_admin)
        }

    }
}