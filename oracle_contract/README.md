# Oracle Consensus

- ### Constrained state space predictions
    - Predictions over $]0;1[^M$
        - ``fn update_constrained_consensus``
    - We assume a bêta probability law.
        - Essence estimator : 
            - median to identify reliables oracles
            - then : median on reliables oracles
        - Reliability estimator : ``1 - 2*std_dev``
- ### Unconstrained state space predictions
    - Predictions over $\mathbb{R}^M$
        - ``fn update_unconstrained_consensus``
    - We assume a gaussian probability law.
        - Essence estimator :
            - median on reliability check
            - then : mean value on reliables oracles
        - Reliability estimator : 
            - ``min(max_spread, std_dev) / max_spread``
            - then : ``min(max_spread, avg) / max_spread``

## Installation

Requires : Scarb, Cairo

## Execution

Compilation :
```bash
scarb build
```

Tests :
```bash
scarb test
```

We recommand you to declare/deploy using Argent :

```bash
# EXAMPLE CALL DATA :

3, 
<admin_address_00>, 
<admin_address_01>, 
<admin_address_02>, 
1, # enable_oracle_replacement
2, # required_majority
2, # n_failing_oracles
1, # constrained (over ]0,1[^M)
0, # unconstrained_max_spread (required to compute relibaility over R^M)
6, # dimension ie. M

7, 
<oracle_address_00>, 
<oracle_address_01>,
<oracle_address_02>,
<oracle_address_03>,
<oracle_address_04>,
<oracle_address_05>,
<oracle_address_06

# two oracle cannot have the same address
# two admins cannot have the same address
# an admin can also be an oracle
```

Sepolia execution with a configured starkli :

```bash
# TO DECLARE THE CONTRACT :
starkli declare target/dev/oracle_consensus_OracleConsensusNDS.contract_class.json --compiler-version=2.4.0
# or
starkli declare target/dev/<WANTED_CONTRACT>.json --compiler-version=2.4.0

# TO DEPLOY THE CONTRACT (ie. generate an instance) :
starkli deploy <CONTRACT_ADDRESS> <constructor as felt252>
```

```bash
# METHODS WITHOUT SIDE EFFECTS (READ ONLY) :
starkli call <CONTRACT_ADDRESS> <method> <arguments as felt252> 
# METHODS WITH SIDE EFFECTS :
starkli invoke <CONTRACT_ADDRESS> <method> <arguments as felt252> 
```

## Code details

To manage floats, we use the wad convention on ``i128``. 
- details in : ``signed_wad_ray.cairo``
- The signed wad implementation is based on the code from alexandria.

Currently, the implementations are uncrypted and can be called by anyone.
A payment system will be added in the future.