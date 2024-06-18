#[starknet::interface]
trait IOracleConsensus<TContractState> {
    fn update_prediction(ref self: TContractState, prediction : u256);
    
    fn consensus_active(self: @TContractState) -> bool;
    fn get_consensus_value(self: @TContractState) -> u256;
    fn get_consensus_credibility(self: @TContractState) -> u256;

    // fn replace_oracle
}

#[starknet::contract]
mod oracle_consensus {
    use core::option::OptionTrait;
    // use core::option::Option::{None, Some};
    use starknet::ContractAddress;
    use starknet::syscalls::storage_read_syscall;
    use starknet::syscalls::storage_write_syscall;
    use starknet::get_caller_address;

    use oracle_consensus::math::data_science::{median, spread};

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
        consensus_credibility : u256 // wad convention
    }

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
        self.consensus_credibility.write(0_u256);
    }

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

    fn update_consensus(ref self: ContractState, oracle_index : @usize, prediction : @u256) {
        update_a_single_oracle(ref self, oracle_index, prediction);

        if self.n_oracles.read() != self.n_active_oracles.read() {
            return();
        }

        let oracles_values = oracles_reliable_values(@self);

        // First estimatation
        let median_idx = median(@oracles_values);
        let median_value = *oracles_values.at(median_idx);
        
        // Compute first spread
        let spread_values = spread(@oracles_values, @median_value);

        // filter the highest spread
        
        // let filtered_oracles= 

        // Second estimation

        // Compute total spread

        // update oracles_values

        self.consensus_active.write(true);
    }

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

    #[abi(embed_v0)]
    impl OracleConsensusImpl of super::IOracleConsensus<ContractState> {
        fn update_prediction(ref self: ContractState, prediction : u256) {
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
        fn get_consensus_credibility(self: @ContractState) -> u256 {
            self.consensus_value.read()
        }
    }
}