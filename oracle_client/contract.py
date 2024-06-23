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

from typing import List, Optional, Tuple
from common import globalState, N_ORACLES

# import aioconsole
import asyncio

import numpy as np

# ----------------------------------------------------------------------

ACCOUNTS_PATH = os.path.join("data", "sepolia.json")

RESOURCE_BOUND_UPDATE_PREDICTION = ResourceBounds(700000, 70932837875699)
RESOURCE_BOUND_UPDATE_PROPOSITION = ResourceBounds(700000, 70932837875699)
RESOURCE_BOUND_VOTE_FOR_A_PREDICTION = ResourceBounds(600000, 70932837875699)

UPPER_BOUND_FELT252 = 3618502788666131213697322783095070105623107215331596699973092056135872020481
UPPER_BOUND__I128 = (2**127) - 1 # included

3618502788666131213697322783095070105623107215331596699973092056135872020480
# ----------------------------------------------------------------------

# fwsad for wsad as felt252
def fwsad_to_float(x) :
    return float(
        (x - UPPER_BOUND_FELT252) if x > UPPER_BOUND__I128 \
        else x
    ) * 1e-6

# fwsad for wsad as felt252
def float_to_fwsad(x) :
    as_wsad = int(x*1e6)
    return (
        as_wsad + UPPER_BOUND_FELT252 if as_wsad < 0 \
        else as_wsad
    )

def to_hex(x: int) -> str:
    return f"0x{x:0x}"

def from_hex(x : str) -> int:
    return int(x, 16)

def retrieve_account_data():
    with open(ACCOUNTS_PATH, 'r') as file:
        data = json.load(file)

    globalState.admin_accounts = dict()
    globalState.oracle_accounts = dict()
    
    admins_addresses = data["admins_addresses"]
    admins_private_keys = data["admins_private_keys"]
    oracles_addresses = data["oracles_addresses"]
    oracles_private_keys = data["oracles_private_keys"]

    for address, key in zip(admins_addresses, admins_private_keys) :
        globalState.admin_accounts[int(address, 16)] = Account(
                client=globalState.client,
                address=address,
                key_pair=KeyPair.from_private_key(key),
                chain=StarknetChainId.SEPOLIA)
    for address, key in zip (oracles_addresses, oracles_private_keys) :
        globalState.oracle_accounts[int(address, 16)] = Account(
                client=globalState.client,
                address=address,
                key_pair=KeyPair.from_private_key(key),
                chain=StarknetChainId.SEPOLIA)

    globalState.default_contract = asyncio.run(
        Contract.from_address(
                provider=globalState.admin_accounts[int(admins_addresses[0], 16)], 
                address=globalState.DEPLOYED_ADDRESS
        ))


# ----------------------------------------------------------------------

def address_to_oracle_index(address : int) -> int:
    '''
    Converts an address to the corresponding index
    '''
    oracle_list = call_oracle_list()
    for index, oracle in enumerate(oracle_list) :
        if oracle == address : return index
    raise IndexError()

def oracle_index_to_address(index : int) -> int:
    '''
    Converts an index to the corresponding address
    '''
    return int(call_oracle_list()[index], 16)

def address_to_admin_index(address : int) -> int:
    '''
    Converts an address to the corresponding index
    '''
    admin_list = call_admin_list()
    for index, admin in enumerate(admin_list) :
        if admin == address : return index
    raise IndexError()

def admin_index_to_address(index : int) -> int:
    '''
    Converts an index to the corresponding address
    '''
    return int(call_admin_list()[index], 16)



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
    globalState.remote_consensus = [fwsad_to_float(x) for x in value]
    return globalState.remote_consensus

def call_skewness() -> np.array :
    value = call_generic('get_skewness')
    globalState.remote_skewness = [fwsad_to_float(x) for x in value]
    return globalState.remote_skewness

def call_kurtosis() -> np.array :
    value = call_generic('get_kurtosis')
    globalState.remote_kurtosis = [fwsad_to_float(x) for x in value]
    return globalState.remote_kurtosis

def call_first_pass_consensus_reliability() -> float :
    value = call_generic("get_first_pass_consensus_reliability")
    globalState.remote_first_pass_consensus_reliability = fwsad_to_float(value)
    return globalState.remote_first_pass_consensus_reliability

def call_second_pass_consensus_reliability() -> float :
    value = call_generic('get_second_pass_consensus_reliability')
    globalState.remote_second_pass_consensus_reliability = fwsad_to_float(value)
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

def call_oracle_value_list() -> List :
    value = call_generic('get_oracle_value_list')
    globalState.remote_oracle_value_list = value
    return globalState.remote_oracle_value_list


#  'get_a_specific_proposition': <starknet_py.contract.ContractFunction at 0x7672b8868410>}

# ----------------------------------------------------------------------
# INVOKE
# ----------------------------------------------------------------------

# requires globalState.remote_dimension
def update_all_the_predictions(predictions: List[np.array]):
    print("link addresses")
    oracles = call_oracle_list()
    print("update propositions : [ ", end="")
    for i, (oracle, prediction) in enumerate(zip(oracles, predictions)) :
        account = globalState.oracle_accounts[int(oracle, 16)]
        invoke_update_prediction(account, prediction, True, i)
        print(f"done {i}, ", end="", flush=True)
    print("]")

# requires globalState.remote_dimension
def invoke_update_prediction(account, prediction: np.array, debug=False, which_index = None) :
    contract = asyncio.run(
        Contract.from_address(
                provider=account, 
                address=globalState.DEPLOYED_ADDRESS
    ))

    prediction_as_felt = [ float_to_fwsad(x) for x in prediction ]

    asyncio.run(
        contract.functions["update_prediction"].invoke_v3(
            prediction=prediction_as_felt, l1_resource_bounds=RESOURCE_BOUND_UPDATE_PREDICTION
        )
    )

    eel.writeToConsole(f"Updated [{which_index+1}/{N_ORACLES}] with : \n{prediction_as_felt}")

def invoke_update_proposition(acccount : Account, 
            old_oracle_index : Optional[int] = None,  
            new_oracle_address : Optional[int] = None
    ) :
    
    if (old_oracle_index is None) != (new_oracle_address is None) :
        raise ValueError()

    contract = asyncio.run(
        Contract.from_address(provider=acccount, address=globalState.DEPLOYED_ADDRESS)
    )

    proposition = None if old_oracle_index is None else (old_oracle_index, new_oracle_address)

    asyncio.run(
        contract.functions["update_proposition"].invoke_v3(
            proposition=proposition, l1_resource_bounds=RESOURCE_BOUND_UPDATE_PROPOSITION
        )
    )

    eel.writeToConsole("Done")
    print("Done.")

def invoke_vote_for_a_proposition(acccount : Account, which_admin_proposition : int, support_his_proposition : bool) :
    contract = asyncio.run(
        Contract.from_address(provider=acccount, address=globalState.DEPLOYED_ADDRESS)
    )

    asyncio.run(
        contract.functions["vote_for_a_proposition"].invoke_v3(
            which_admin=which_admin_proposition, support_his_proposition=support_his_proposition,
            l1_resource_bounds=RESOURCE_BOUND_VOTE_FOR_A_PREDICTION
        )
    )

    eel.writeToConsole("Done")
    print("Done.")


