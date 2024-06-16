// On peut imaginer plusieurs instances de validations pour l'introduction d'un nouveau contract

#[starknet::interface]
trait IOracleConsensus<TContractState> {
    // fn update_prediction(ref self: TContractState, predicted_state);
    
    // fn replace_oracle
    // fn estimate_failure
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

    
    #[constructor]
    fn constructor(ref self: ContractState, 
        admins : Span<ContractAddress>,
        required_majority : u128,
        failure_percentage : u128, 
        oracles: Span<(ContractAddress, u128)>,
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
    
    // #[abi(embed_v0)]
    // impl ContractAImpl of super::IOracleConsensus<ContractState> {
    // }
}


// fn update_value(ref self: TContractState, value: u128) -> bool;
// fn get_value(self: @TContractState) -> u128;

// fn set_value(ref self: ContractState, value: u128) -> bool {
//     // TODO: check if contract_b is enabled.
//     // If it is, set the value and return true. Otherwise, return false.
// }

// fn get_value(self: @ContractState) -> u128 {
//     self.value.read()
// }



// #[cfg(test)]
// mod test {
//     use starknet::syscalls::deploy_syscall;
//     use starknet::ContractAddress;
//     use super::ContractA;
//     use super::IContractADispatcher;
//     use super::IContractADispatcherTrait;
//     use super::ContractB;
//     use super::IContractBDispatcher;
//     use super::IContractBDispatcherTrait;

//     #[test]
//     #[available_gas(30000000)]
//     fn test_interoperability() {
//         // Deploy ContractB
//         let (address_b, _) = deploy_syscall(
//             ContractB::TEST_CLASS_HASH.try_into().unwrap(), 0, ArrayTrait::new().span(), false
//         )
//             .unwrap();

//         // Deploy ContractA
//         let mut calldata = ArrayTrait::new();
//         calldata.append(address_b.into());
//         let (address_a, _) = deploy_syscall(
//             ContractA::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false
//         )
//             .unwrap();

//         // contract_a is of type IContractADispatcher. Its methods are defined in IContractADispatcherTrait.
//         let contract_a = IContractADispatcher { contract_address: address_a };
//         let contract_b = IContractBDispatcher { contract_address: address_b };

//         //TODO interact with contract_b to make the test pass.

//         // Tests
//         assert(contract_a.set_value(300) == true, 'Could not set value');
//         assert(contract_a.get_value() == 300, 'Value was not set');
//         assert(contract_b.is_enabled() == true, 'Contract b is not enabled');
//     }
// }
