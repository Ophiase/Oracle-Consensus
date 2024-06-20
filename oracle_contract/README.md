# Oracle Consensus

- Constrained state space predictions
    - ``contract_1d_constrained.cairo`` (1DC) : Predictions over $]0;1[$
        - ``fn update_consensus``
    - ``contract_nd.cairo`` (NDC) : Predictions over $]0;1[^M$
        - ``fn update_constrained_consensus``
    - We assume a bêta probability law.
        - Essence estimator : 
            - median to identify reliables oracles
            - then : median on reliables oracles
        - Reliability estimator : variance / 2
- Unconstrained state space predictions
    - ``contract_nd.cairo`` (NDU) : Predictions over $\mathbb{R}^M$
        - ``fn update_unconstrained_consensus``
    - We assume a gaussian probability law.
        - Essence estimator :
            - median on reliability check
            - then : mean value on reliables oracles
        - Reliability estimator : a function of variance

## Installation

Requires : Scarb, Cairo

## Execution

Compilation :
```bash
scarb build
```

Tests :
```bash
scarb cairo-test
```

Sepolia execution with a configured starkli :

```bash
# TO DECLARE THE CONTRACT :
starkli declare target/dev/oracle_consensus_OracleConsensusND.contract_class.json --compiler-version=2.4.0
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