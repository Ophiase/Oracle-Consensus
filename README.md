# Stochastic Vector Oracle Consensus

Establish a consensus over oracles predictions that can evoluate through time.

## Global Modelization

### Statistic model

Let $M$ be the number of attributes. \
Let $N$ be the number of oracles.

Let $\Omega = C = [0, 1]^M \subset \Bbb R^M$ the state space. \
Let assume $c \in \Omega$ is the phenomenon essence. \
Let $\mu : \Omega \to [0, 1]$ the probabilty law of an oracle.

An oracle prediction is a realization of a law $\mu$ over $C$.

In this project we considers $N$ oracles predictions of a same phenomenon: $(C^N, Bor(C)^{\otimes N}, \mu^{\otimes N)}$

We want to approximate the value of $c$ and estimate the credence of this estimation.

### Example

Let say we want to do smart contracts based on the psychology of investors on Bitcoin.
We can base our analysis on the following criterions :
- We modelize the psychology of an individual as a vector of basis : \
(stress, anger, joy) with values between $0$ and $1$.
- We consider the 

## Gaussian Modelization

## Binary Gaussian Modelization

