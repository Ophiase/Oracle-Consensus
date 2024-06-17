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
        n_admins : usize,
        admins : LegacyMap<usize, ContractAddress>,
        
        enable_oracle_replacement : bool,
        required_majority : usize,
        
        n_failing_oracles : usize,
        n_oracles : usize,
        oracles: LegacyMap<usize, (ContractAddress, Option<u128>)>,
 
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
            
            let value = *array.at(i);
            self.oracles.write(i, (value, Option::None));

            i += 1;
        };

        self.n_oracles.write(array.len());
    }

    fn oracles_values(ref self: ContractState) -> Array<Option<u128>> {
        let mut result = ArrayTrait::new();
     
        let mut i = 0;
        loop {
            if i == self.n_oracles.read() {
                break();
            }
            
            result.append(self.oracles.read(i));
            i += 1;
        };

        result
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