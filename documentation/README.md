# Mathematical Documentation

## Summary

- [Global Modeling](#global-modeling)
    - [Statistical Model](#statistical-model)
    - [Example](#example)
- [Unimodal Modeling](#unimodal-modeling)
- [Multimodal Modeling](#multimodal-modeling)
- [Algorithms](#algorithms)
    - [Consensus](#consensus)
    - [Replacement Vote Implementation](#replacement-vote-implementation)


## Global Modeling

### Statistical Model

Let $M$ be the number of attributes. \
Let $N$ be the number of oracles.

Let $\Omega = C = ]0, 1[^M \subset \mathbb{R}^M$ be the state space. \
Let's assume $e \in \Omega$ is the true essence of the phenomenon. \
Let $\mu : \Omega \to ]0, 1[$ be the probability law of an oracle.

An oracle's prediction is a realization of the law $\mu$ over $C$.

In this project, we consider $N$ oracles' predictions of the same phenomenon: $(C^N, \mathcal{B}(C)^{\otimes N}, \mu^{\otimes N})$

We want to approximate the value of $e$ and estimate the credibility of this estimation. \
For basic law distributions, the visual intution is to characterize the $e$ value as the mode / center of the spike. 

The kind of models that fit in our modelization can be simplified into fuzzy logic : \
A `stress level` valued in $]0;1[$ would make as much sense in `{low, mid-low, moderate, mid-high, high}` \
Therefore, the accuracy of the consensus matters more than the precision of its value.

### Example

Let's say we want to create smart contracts based on the psychology of investors in Bitcoin.
We can base our analysis on the following criteria:
- We model the psychology of an individual as a vector of bases:
(stress, anger, euphoria) with values between $0$ and $1$.
- We consider the following two groups: (crowd, famous investors)

An oracle will predict a vector with the following labeled coordinates: \
(crowd stress, crowd anger, crowd euphoria, famous investors stress, famous investors anger, famous investors euphoria)

We consider 3 societies (A, B, C) and 10 oracles with 5 from A, 3 from B, and 2 from C.

It is assumed that oracles from different societies can use different algorithms.

## Unimodal Modeling

### Constrained over $]0, 1[^M$

A first assumption we can make to simplify the problem is to consider that not matter the society and the algorithm, \
the denormalized prediction $f(X)$ is a gaussian law centered in $e$ :
- $f$ is the denormalized function : $]0, 1[ \to \mathbb{R}$
    - $f : X \to \tan((X - 0.5) \pi)$ $\qquad$
- $f^{-1}$ the normalize function.
    - $f^{-1} : Y \to {arctan(Y) \over \pi} + 0.5$
- $f(X) \sim \mathcal N(e, \sigma Id_M)^N \sim \mathcal N(E, \sigma Id_{MN})$

The samples in ``oracle_contract/drafts/gaussian_algorithm_demo.ipynb`` suggests that the use of the normalizing function is hardly workable. \
Hence, the gaussian assumption cannot hold on $]0, 1[$.

Instead, we will now consider the [Bêta](https://fr.wikipedia.org/wiki/Loi_b%C3%AAta) law and [Kumaraswamy](https://fr.wikipedia.org/wiki/Loi_de_Kumaraswamy) law. \
Experiments are done in ``oracle_contract/drafts/beta_kumaraswamy_algorithm_demo``.

Those laws seem more to fit the basic intution we have on the distribution of predictions. \
The essence will now be modelized by the mode of the distribution.

### Unconstrained, over $R^M$

For regular oracles that predicts values over $R^M$ (eg: price of a barrel of oil, BTC/USD, $\dots$) the gaussian noise modelisation works better.

Essence is then the $\mu$ parameter of the distribution, and reliability a function of $\sigma$.

Thus, the estimator is :

## Multimodal Modeling

In a second time we might even consider a case with $K$ instances of $e$ with $\mu_k$ centered in $e$. \
Each oracle will have a probability of $p_k$ to follow $\mu_k$. Mathematicaly :
- $w \sim Mult(1, p)$ ie. $w$ is a discrete random variable of law $p$
- $f(x) \sim \sum^K_k \mathcal{N}(e_k, \sigma_k) \times \mathbb{1}_w$ if $\mu_k$ are gaussians

## Failing Oracle

Now, we will consider that when an oracle makes a prediction, it has a probability of $\alpha$ to fail. \
A failing oracle can be modelized as a uniform distribution over $]0, 1[$.
In our estimators, we will consider that there is always exactly $\alpha$ percent of failing oracles.

- Security issues: An oracle can get hacked
- Bug

Consequence : we want to be able to replace only the worst oracle relatively to the consensus.

## Algorithms

### Consensus

In the following, we'll consider a smart contract that establish a consensus on $e$ value and the accuracy of this consensus. \

The smooth median is defined as the average between the two most centered values. \

- Safe check : all the oracles have commited once
- First Pass
    - compute the essence estimator on all the oracles
        - smooth_median | constrained case
        - smooth_median | uconstrained case
    - compute the individual oracles_scores
        - squared distance to the smooth_median | constrained case
        - squared distance to the smooth_median | unconstrained case
    - compute the reliability estimator on all the oracles
        - average squared distance to the smooth_median | constrained case
        - average squared distance to the smooth_median | unconstrained case
- Second Pass
    - compute the essence estimator on the $(1-\alpha)$ percent of the best oracles
        - smooth_median | constrained case
        - mean | uconstrained case
    - compute the reliability estimator on the $(1-\alpha)$ percent of the best oracles
        - average squared distance to the smooth_median | constrained case
        - average squared distance to the mean | unconstrained case

Remark: There is no natural order over $\mathbb{R}^M$, therefore, we consider on higher dimension the component wise version of the median/smoth_median.

Idea/Todo: Can we efficiently remplace the smooth median with what i would call the super smooth median? A weighted sum based on the order, where the weights reproduce a bell shape.

### Replacement Vote Implementation

Let $(a_1, \dots, a_A)$ be the admins. \
Let $(o_1, \dots, o_N)$ be the oracles.

Let $(r_1, \dots, r_A)$ be the replacement proposition where the $r_i$ are ``Option<(usize, ContractAddress)>``.

At each time the smart contract keep a boolean valued vote matrix of dimension $A \times A$.

By default :
- Vote matrix is equal to : $(false)_{i,j \in A \times A}$
- Every replacement propositions are nulles.

Admins can vote and discard their vote for an admin proposition.

When :
- Admin $x$ get enough votes
- His replacement proposition is valid
    - ``usize`` oracle index corresponds to a failing oracle
    - ``ContractAddress`` is a valid address
The oracle is replaced.

When an admin change its proposition, he loose all its votes. \
When an oracle is replaced, the vote matrix is reinitialized to its default value$


