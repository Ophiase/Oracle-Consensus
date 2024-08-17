use starknet::ContractAddress;
use core::fmt::{Display, Formatter, Error};
use oracle_consensus::utils::{contractaddress_to_bytearray, wsad_to_string};

#[derive(Drop, Serde, starknet::Store, Copy)]
pub struct Oracle {
    address: ContractAddress,
    value: i128, // wsad convention
    enabled: bool, // have a value ?
    reliable: bool // pass the consensus ?
}

#[derive(Drop, Serde, starknet::Store, Hash)]
pub struct VoteCoordinate {
    vote_emitter: usize,
    vote_receiver: usize
}

impl OracleDisplay of Display<Oracle> {
    fn fmt(self: @Oracle, ref f: Formatter) -> Result<(), Error> {
        let address = contractaddress_to_bytearray(*self.address);
        let value = wsad_to_string(*self.value, 2);
        let enabled = self.enabled;
        let reliable = self.reliable;

        write!(f, "[{} | e:{}, r:{} | {}]", address, enabled, reliable, value)
    }
}
