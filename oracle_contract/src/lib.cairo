// On peut imaginer plusieurs instances de validations pour l'introduction d'un nouveau contract

#[starknet::interface]
trait IOracleConsensus<TContractState> {
    fn update_prediction(ref self: TContractState, predicted_state : u128);
    fn get_consensus_value(self: @TContractState) -> u128;
    fn get_consensus_credibility(self: @TContractState) -> u128;
    
    // fn replace_oracle
}

#[starknet::contract]
mod OracleConsensus {
    use core::option::OptionTrait;
    use starknet::ContractAddress;
    use starknet::syscalls::storage_read_syscall;
    use starknet::syscalls::storage_write_syscall;

    use alexandria_math::wad_ray_math::{
        ray_div, ray_mul, wad_div, wad_mul, ray_to_wad, wad_to_ray, ray, wad, half_ray, half_wad
    };
    use alexandria_math::{pow};
    
    #[storage]
    struct Storage {
        admins : LegacyMap<usize, ContractAddress>, // ContractAddress list
        required_majority : u128, // by default 100%
        
        failure_percentage : u128, // 
        oracles: LegacyMap<usize, (ContractAddress, u128)>, // ContractAddress list with a credibility score

        consensus_value: u128,
        consensus_credibility : u128
    }

    // fn estimate_centroid
    // fn estimate_failure

    fn fill_admins(ref self: ContractState, array : Span<ContractAddress>) {
        let mut i = 0;
        loop {
            if i == array.len() {
                break();
            }
            
            let value = *array.at(i);
            self.admins.write(i, value);

            i += 1;
        }
    }

    fn fill_oracles(ref self: ContractState, array : Span<ContractAddress>) {
        let mut i = 0;
        loop {
            if i == array.len() {
                break();
            }
            
            let value = *array.at(i);
            self.oracles.write(i, (value, 0));

            i += 1;
        }
    }

    
    #[constructor]
    fn constructor(ref self: ContractState, 
        admins : Span<ContractAddress>,
        required_majority : u128,
        failure_percentage : u128, 
        oracles: Span<ContractAddress>,
        consensus_value: u128,
        consensus_credibility: u128
    ) {

        fill_admins(ref self, admins);
        // fill_oracles(ref self, oracles);
        
        self.required_majority.write(required_majority);
        self.failure_percentage.write(failure_percentage);
        self.consensus_value.write(consensus_value);
        self.consensus_credibility.write(consensus_credibility);
    }
    
    #[abi(embed_v0)]
    impl OracleConsensusImpl of super::IOracleConsensus<ContractState> {
        fn update_prediction(ref self: ContractState, predicted_state : u128) {
            // TODO
            
            // check if the caller address is registered

            // update the value
        }
        
        fn get_consensus_value(self: @ContractState) -> u128 {
            self.consensus_value.read()
        }

        fn get_consensus_credibility(self: @ContractState) -> u128 {
            self.consensus_value.read()
        }
    }
}