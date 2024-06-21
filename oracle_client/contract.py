import json
import os

from starknet_py.net.full_node_client import FullNodeClient
from starknet_py.net.account.account import Account
from starknet_py.net.full_node_client import FullNodeClient
from starknet_py.net.models.chains import StarknetChainId
from starknet_py.net.signer.stark_curve_signer import KeyPair
from starknet_py.contract import Contract
from starknet_py.cairo.felt import encode_shortstring
from starknet_py.common import create_sierra_compiled_contract
from starknet_py.common import create_casm_class
from starknet_py.hash.casm_class_hash import compute_casm_class_hash
from starknet_py.net.client_models import ResourceBounds, EstimatedFee, PriceUnit
from pprint import pprint

from common import globalState

# import aioconsole
import asyncio

import numpy as np

# ----------------------------------------------------------------------

ACCOUNTS_PATH = os.path.join("data", "sepolia.json")

# ----------------------------------------------------------------------

# TODO: manage negative values
def wad_to_float(x) :
    return float(x) * 1e-18

# TODO: manage negative values
def float_to_wad(x) :
    return int(x * 1e18)

def to_hex(x: int) -> str:
    return f"0x{x:0x}"

def retrieve_account_data():
    with open(ACCOUNTS_PATH, 'r') as file:
        data = json.load(file)
    
    addresses = data['addresses']
    private_keys = data['private_keys']

    accounts = [
        Account(
            client=globalState.client,
            address=address,
            key_pair=KeyPair.from_private_key(key),
            chain=StarknetChainId.SEPOLIA
        ) for address, key in zip(addresses, private_keys)
    ]

    globalState.addresses = addresses
    globalState.private_keys = private_keys
    globalState.accounts = accounts



    globalState.default_contract = asyncio.run(
        Contract.from_address(
                provider=globalState.accounts[0], 
                address=globalState.DEPLOYED_ADDRESS
        ))

# ----------------------------------------------------------------------

def call_consensus() -> np.array :
    contract = globalState.default_contract
    consensus = asyncio.run(
        contract.functions['get_consensus_value'].call()
    )
    
    globalState.remote_consensus = [wad_to_float(x) for x in consensus[0]]
    return globalState.remote_consensus

def call_first_pass_consensus_reliability() -> float :
    contract = globalState.default_contract
    first_pass_consensus_reliability = asyncio.run(
        contract.functions['get_first_pass_consensus_reliability'].call()
    )[0]
    
    globalState.remote_first_pass_consensus_reliability = wad_to_float(first_pass_consensus_reliability)
    return globalState.remote_first_pass_consensus_reliability

def call_second_pass_consensus_reliability() -> float :
    contract = globalState.default_contract
    second_pass_consensus_reliability = asyncio.run(
        contract.functions['get_second_pass_consensus_reliability'].call()
    )[0]
    
    globalState.remote_second_pass_consensus_reliability = wad_to_float(second_pass_consensus_reliability)
    return globalState.remote_second_pass_consensus_reliability
