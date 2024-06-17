#[starknet::interface]
trait IOracleConsensus<TContractState> {
    fn update_prediction(ref self: TContractState, prediction : u128);
    
    fn consensus_active(self: @TContractState) -> bool;
    fn get_consensus_value(self: @TContractState) -> u128;
    fn get_consensus_credibility(self: @TContractState) -> u128;

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


    use alexandria_math::wad_ray_math::{
        ray_div, ray_mul, wad_div, wad_mul, ray_to_wad, wad_to_ray, ray, wad, half_ray, half_wad
    };
    use alexandria_math::{pow};


    #[derive(Drop, Serde, starknet::Store)]
    struct Oracle {
        address : ContractAddress,
        value: u128,
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
        n_active_oracles : usize,
        oracles: LegacyMap<usize, Oracle>,
 
        consensus_value: u128,
        consensus_credibility : u128
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
                value : 0_u128,
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
        
        self.consensus_value.write(0_u128);
        self.consensus_credibility.write(0_u128);
    }

    fn oracles_values(ref self: ContractState) -> Array<Option<u128>> {
        assert(self.consensus_active(), 'consensus not active');

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
    

    fn update_consensus(ref self: ContractState, user : ContractAddress, prediction : u128) {
        // TODO
    }

    fn is_admin(self: @ContractState, user : ContractAddress) -> bool {
        let mut i = 0;
        loop {
            if i == self.n_admins.read() {
                break(false);
            }

            if self.admins.read(i) == user {
                break(true);
            } 
            
            i += 1;
        }
    }

    #[abi(embed_v0)]
    impl OracleConsensusImpl of super::IOracleConsensus<ContractState> {
        fn update_prediction(ref self: ContractState, prediction : u128) {
            let user = get_caller_address();
            assert(is_admin(@self, user), 'not admin');
            update_consensus(ref self, user, prediction);
        }

        fn consensus_active(self: @ContractState) -> bool {
            self.n_active_oracles.read() == self.n_oracles.read()
        }
        
        fn get_consensus_value(self: @ContractState) -> u128 {
            self.consensus_value.read()
        }

        // return 0 until all the oracles have voted once
        fn get_consensus_credibility(self: @ContractState) -> u128 {
            self.consensus_value.read()
        }
    }
}