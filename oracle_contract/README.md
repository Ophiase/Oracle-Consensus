# Oracle Consensus

- Constrained state space predictions
    - ``contract_1d_constrained.cairo`` : Predictions over $]0;1[$
    - ``contract_nd_constrained.cairo`` : Predictions over $]0;1[^M$
    - We assume a bêta probability law.
        - Essence estimator : 
            - median to identify reliables oracles
            - then : median on reliables oracles
        - Reliability estimator : variance / 2
- Unconstrained state space predictions
    - ``contract_nd_unconstrained.cairo`` : Predictions over 
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

Execution :
```bash
starkli ...
```

## Misc

To manage floats, we use the wad convention on ``u256``.