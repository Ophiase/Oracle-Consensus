import json
import os

import eel
from starknet_py.net.full_node_client import FullNodeClient
from starknet_py.net.account.account import Account
from starknet_py.net.models.chains import StarknetChainId
from starknet_py.net.signer.stark_curve_signer import KeyPair
from starknet_py.contract import Contract
from starknet_py.cairo.felt import encode_shortstring
from starknet_py.common import create_sierra_compiled_contract
from starknet_py.common import create_casm_class
from starknet_py.hash.casm_class_hash import compute_casm_class_hash
from starknet_py.net.client_models import ResourceBounds, EstimatedFee, PriceUnit
from pprint import pprint

from typing import List, Tuple
from common import globalState, N_ORACLES

# import aioconsole
import asyncio

import numpy as np

# ----------------------------------------------------------------------

ACCOUNTS_PATH = os.path.join("data", "sepolia.json")

RESSOURCE_BOUND_UPDATE_PREDICTION = ResourceBounds(400000, 40932837875699)
RESSOURCE_BOUND_UPDATE_PROPOSITION = ResourceBounds(400000, 40932837875699)
RESSOURCE_BOUND_VOTE_FOR_A_PREDICTION = ResourceBounds(400000, 40932837875699)

UPPER_BOUND_FELT252 = 3618502788666131213697322783095070105623107215331596699973092056135872020481
UPPER_BOUND__I128 = (2**127) - 1 # included

3618502788666131213697322783095070105623107215331596699973092056135872020480
# ----------------------------------------------------------------------

# fwad for wad as felt252
def fwad_to_float(x) :
    return float(
        (x - UPPER_BOUND_FELT252) if x > UPPER_BOUND__I128 \
        else x
    ) * 1e-18

# fwad for wad as felt252
def float_to_fwad(x) :
    as_wad = int(x*1e18)
    return (
        as_wad + UPPER_BOUND_FELT252 if as_wad < 0 \
        else as_wad
    )

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
    globalState.oracles_accounts = globalState.accounts[:N_ORACLES]

    globalState.default_contract = asyncio.run(
        Contract.from_address(
                provider=globalState.accounts[0], 
                address=globalState.DEPLOYED_ADDRESS
        ))

# ----------------------------------------------------------------------
# CALL
# ----------------------------------------------------------------------

def call_generic(function_name : str) :
    contract = globalState.default_contract
    return asyncio.run(
        contract.functions[function_name].call()
    )[0]

def call_consensus() -> np.array :
    value = call_generic('get_consensus_value')
    globalState.remote_consensus = [fwad_to_float(x) for x in value]
    return globalState.remote_consensus

def call_first_pass_consensus_reliability() -> float :
    value = call_generic("get_first_pass_consensus_reliability")
    globalState.remote_first_pass_consensus_reliability = fwad_to_float(value)
    return globalState.remote_first_pass_consensus_reliability

def call_second_pass_consensus_reliability() -> float :
    value = call_generic('get_second_pass_consensus_reliability')
    globalState.remote_second_pass_consensus_reliability = fwad_to_float(value)
    return globalState.remote_second_pass_consensus_reliability

def call_consensus_active() -> bool :
    value = call_generic('consensus_active')
    globalState.remote_consensus_active = value
    return globalState.remote_consensus_active

def call_admin_list() -> List[str] :
    value = call_generic('get_admin_list')
    globalState.remote_admin_list = [to_hex(x) for x in value]
    return globalState.remote_admin_list

def call_oracle_list() -> List[str] :
    value = call_generic('get_oracle_list')
    globalState.remote_oracle_list = [to_hex(x) for x in value]
    return globalState.remote_oracle_list

def call_dimension() -> int:
    value = call_generic('get_predictions_dimension')
    globalState.remote_dimension = value
    return globalState.remote_dimension

def call_replacement_propositions() -> List :
    value = call_generic('get_replacement_propositions')
    globalState.remote_replacement_propositions = value
    return globalState.remote_replacement_propositions

#  'get_a_specific_proposition': <starknet_py.contract.ContractFunction at 0x7672b8868410>}
#  'get_oracle_value_list': <starknet_py.contract.ContractFunction at 0x7672b880de90>,

# ----------------------------------------------------------------------
# INVOKE
# ----------------------------------------------------------------------

# requires globalState.remote_dimension
def update_all_the_predictions(predictions: List[np.array]):
    print("update propositions : [ ", end="")
    for i, (account, prediction) in enumerate(zip(globalState.oracles_accounts, predictions)) :
        invoke_update_prediction(account, prediction, True, i)
        print(f"done {i}, ", end="")
    print("]")

# requires globalState.remote_dimension
def invoke_update_prediction(account, prediction: np.array, debug=False, which_index = None) :
    contract = asyncio.run(
        Contract.from_address(
                provider=account, 
                address=globalState.DEPLOYED_ADDRESS
    ))

    # comp_start = globalState.active_component * globalState.remote_dimension 
    # comp_end = comp_start + globalState.remote_dimension

    prediction_as_felt = [
       float_to_fwad(x) for x in prediction #[comp_start, comp_end]
    ]

    asyncio.run(
        contract.functions["update_prediction"].invoke_v3(
            prediction=prediction_as_felt, l1_resource_bounds=RESSOURCE_BOUND_UPDATE_PREDICTION
        )
    )

    eel.writeToConsole(f"Updated [{which_index+1}/{N_ORACLES}] with : \n{prediction_as_felt}")

def invoke_update_proposition(acccount, prediction: List) :
    # RESSOURCE_BOUND_UPDATE_PROPOSITION
    raise NotImplementedError()

def invoke_vote_for_a_proposition(acccount, which_one) :
    contract = asyncio.run(
        Contract.from_address(provider=acccount, address=globalState.DECLARED_ADDRESS)
    )

    asyncio.run(
        contract.functions["vote_for_a_proposition"].invoke_v3(
            which_one=which_one, l1_resource_bounds=RESSOURCE_BOUND_VOTE_FOR_A_PREDICTION
        )
    )


