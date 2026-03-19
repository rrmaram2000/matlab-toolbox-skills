# Bayesian Methods

Bayesian methods provide a principled framework for incorporating prior knowledge, quantifying uncertainty, and making probabilistic predictions. MATLAB supports Bayesian approaches through optimization, sampling, and built-in classifiers.

## Bayesian Framework Overview

### Bayes' Theorem
```
P(θ|D) = P(D|θ) × P(θ) / P(D)
```
- **P(θ|D)**: Posterior - Updated belief about parameters given data
- **P(D|θ)**: Likelihood - Probability of data given parameters
- **P(θ)**: Prior - Initial belief about parameters
- **P(D)**: Evidence - Normalizing constant

## Bayesian Optimization

Bayesian optimization efficiently searches for the optimum of expensive-to-evaluate functions using a probabilistic surrogate model.

### Basic Bayesian Optimization

```matlab
% Define objective function (expensive to evaluate)
fun = @(x) (x.a - 1)^2 + (x.b - 2)^2 + randn*0.1;  % Simple quadratic with noise

% Define search space
vars = [
    optimizableVariable('a', [-5, 5])
    optimizableVariable('b', [-5, 5])
];

% Run optimization
results = bayesopt(fun, vars, ...
    'MaxObjectiveEvaluations', 30, ...
    'IsObjectiveDeterministic', false, ...  % Function has noise
    'AcquisitionFunctionName', 'expected-improvement-plus', ...
    'Verbose', 1, ...
    'PlotFcn', {@plotObjectiveModel, @plotMinObjective});

% Best parameters
bestParams = results.XAtMinObjective;
fprintf('Best parameters: a=%.4f, b=%.4f\n', bestParams.a, bestParams.b);
fprintf('Best objective: %.4f\n', results.MinObjective);
```

### Hyperparameter Optimization for ML Models

```matlab
% Optimize SVM hyperparameters
load fisheriris
X = meas;
Y = species;

% Define hyperparameters to optimize
svm_vars = [
    optimizableVariable('BoxConstraint', [1e-3, 1e3], 'Transform', 'log')
    optimizableVariable('KernelScale', [1e-3, 1e3], 'Transform', 'log')
];

% Cross-validation objective
fun = @(params) cvLoss(X, Y, params);

function loss = cvLoss(X, Y, params)
    cv = cvpartition(Y, 'KFold', 5);
    Mdl = fitcsvm(X, Y, ...
        'BoxConstraint', params.BoxConstraint, ...
        'KernelScale', params.KernelScale, ...
        'KernelFunction', 'rbf', ...
        'CVPartition', cv);
    loss = kfoldLoss(Mdl);
end

% Run Bayesian optimization
results = bayesopt(fun, svm_vars, ...
    'MaxObjectiveEvaluations', 50, ...
    'AcquisitionFunctionName', 'expected-improvement-plus');

% Train final model with best parameters
bestParams = results.XAtMinObjective;
finalModel = fitcsvm(X, Y, ...
    'BoxConstraint', bestParams.BoxConstraint, ...
    'KernelScale', bestParams.KernelScale, ...
    'KernelFunction', 'rbf');
```

### Built-in Hyperparameter Optimization

```matlab
% Many fit functions have built-in optimization
% SVM with automatic optimization
Mdl = fitcsvm(X, Y, ...
    'OptimizeHyperparameters', 'auto', ...
    'HyperparameterOptimizationOptions', struct(...
        'AcquisitionFunctionName', 'expected-improvement-plus', ...
        'MaxObjectiveEvaluations', 30, ...
        'ShowPlots', true, ...
        'Verbose', 1));

% Ensemble with specific hyperparameters
Mdl = fitcensemble(X, Y, ...
    'OptimizeHyperparameters', {'NumLearningCycles', 'LearnRate', 'MinLeafSize'}, ...
    'HyperparameterOptimizationOptions', struct(...
        'MaxObjectiveEvaluations', 50, ...
        'Verbose', 0));

% Neural network
Mdl = fitcnet(X, Y, ...
    'OptimizeHyperparameters', 'auto', ...
    'HyperparameterOptimizationOptions', struct(...
        'MaxObjectiveEvaluations', 30));

% Random forest
Mdl = fitcensemble(X, Y, 'Method', 'Bag', ...
    'OptimizeHyperparameters', {'NumLearningCycles', 'MinLeafSize'});
```

### Acquisition Functions

```matlab
% Expected Improvement (EI) - Balanced exploration/exploitation
results = bayesopt(fun, vars, ...
    'AcquisitionFunctionName', 'expected-improvement');

% Expected Improvement Plus - EI with exploration term
results = bayesopt(fun, vars, ...
    'AcquisitionFunctionName', 'expected-improvement-plus');

% Probability of Improvement - Conservative, exploitation-focused
results = bayesopt(fun, vars, ...
    'AcquisitionFunctionName', 'probability-of-improvement');

% Lower Confidence Bound - Tunable exploration/exploitation
results = bayesopt(fun, vars, ...
    'AcquisitionFunctionName', 'lower-confidence-bound', ...
    'ExplorationRatio', 0.5);  % Higher = more exploration
```

### Conditional Variables and Constraints

```matlab
% Define conditional hyperparameters
vars = [
    optimizableVariable('Method', {'Bag', 'AdaBoostM1', 'GentleBoost'})
    optimizableVariable('NumLearningCycles', [10, 500], 'Type', 'integer')
    optimizableVariable('LearnRate', [0.001, 1], 'Transform', 'log')  % Only for boosting
    optimizableVariable('MinLeafSize', [1, 100], 'Type', 'integer')
];

% Define conditional constraint (LearnRate only for boosting methods)
function tf = learnRateCondition(x)
    tf = ~strcmp(x.Method, 'Bag');
end

results = bayesopt(fun, vars, ...
    'ConditionalVariableFcn', @learnRateCondition);
```

## MCMC Sampling

Markov Chain Monte Carlo (MCMC) methods generate samples from posterior distributions.

### Slice Sampling

```matlab
% Slice sampling is robust and requires minimal tuning
% Define log posterior (log-likelihood + log-prior)
logpdf = @(x) -0.5 * (x - 3).^2 / 2;  % Normal(3, sqrt(2))

% Initial value
x0 = 0;

% Generate samples
nsamples = 10000;
samples = slicesample(x0, nsamples, ...
    'logpdf', logpdf, ...
    'burnin', 1000, ...      % Discard first 1000 samples
    'thin', 5, ...           % Keep every 5th sample
    'width', 1);             % Initial slice width

% Analyze samples
fprintf('Posterior mean: %.4f (true: 3.0)\n', mean(samples));
fprintf('Posterior std: %.4f (true: %.4f)\n', std(samples), sqrt(2));

% Visualization
figure;
subplot(2,2,1);
plot(samples);
xlabel('Iteration');
ylabel('Sample');
title('Trace Plot');

subplot(2,2,2);
histogram(samples, 50, 'Normalization', 'pdf');
hold on;
x = linspace(min(samples), max(samples), 100);
plot(x, normpdf(x, 3, sqrt(2)), 'r-', 'LineWidth', 2);
xlabel('Value');
ylabel('Density');
title('Posterior Distribution');
legend('Samples', 'True Posterior');

subplot(2,2,3);
autocorr(samples, 50);
title('Autocorrelation');

subplot(2,2,4);
[f, xi] = ksdensity(samples);
plot(xi, f, 'b-', 'LineWidth', 2);
xlabel('Value');
ylabel('Density');
title('Kernel Density Estimate');
```

### Metropolis-Hastings

```matlab
% Define log posterior
logpdf = @(x) -0.5 * sum((x - [2; 3]).^2 ./ [1; 4]);  % 2D Normal

% Proposal distribution (random walk)
proprnd = @(x) x + 0.5 * randn(size(x));

% Initial value
x0 = [0; 0];

% Generate samples
nsamples = 10000;
samples = mhsample(x0, nsamples, ...
    'logpdf', logpdf, ...
    'proprnd', proprnd, ...
    'burnin', 2000, ...
    'thin', 2);

% Analyze 2D samples
fprintf('Posterior mean: [%.4f, %.4f]\n', mean(samples(:,1)), mean(samples(:,2)));

% Visualization
figure;
subplot(1,2,1);
plot(samples(:,1), samples(:,2), 'b.', 'MarkerSize', 1);
hold on;
plot(2, 3, 'r+', 'MarkerSize', 20, 'LineWidth', 3);
xlabel('x1');
ylabel('x2');
title('MCMC Samples');
axis equal;

subplot(1,2,2);
histogram2(samples(:,1), samples(:,2), 30, 'DisplayStyle', 'tile');
colorbar;
xlabel('x1');
ylabel('x2');
title('2D Histogram');
```

### MCMC Diagnostics

```matlab
function diagnoseMCMC(samples)
    % Comprehensive MCMC diagnostics

    fprintf('=== MCMC Diagnostics ===\n\n');

    % 1. Effective sample size
    n = length(samples);
    acf = autocorr(samples, min(500, n-1));
    first_negative = find(acf < 0, 1);
    if isempty(first_negative)
        first_negative = length(acf);
    end
    tau = 1 + 2 * sum(acf(2:first_negative-1));  % Autocorrelation time
    ess = n / tau;
    fprintf('Effective Sample Size: %.0f (of %d)\n', ess, n);
    fprintf('Autocorrelation time: %.2f\n', tau);

    % 2. Geweke convergence test
    first_10 = samples(1:round(0.1*n));
    last_50 = samples(round(0.5*n):end);
    z_score = (mean(first_10) - mean(last_50)) / ...
        sqrt(var(first_10)/length(first_10) + var(last_50)/length(last_50));
    p_geweke = 2 * (1 - normcdf(abs(z_score)));
    fprintf('Geweke test z-score: %.4f (p=%.4f)\n', z_score, p_geweke);

    if abs(z_score) > 1.96
        warning('Geweke test suggests non-convergence');
    else
        fprintf('  Chain appears to have converged\n');
    end

    % 3. Monte Carlo Standard Error
    mcse = std(samples) / sqrt(ess);
    fprintf('MCSE: %.6f\n', mcse);

    % 4. Visualization
    figure;
    subplot(2,2,1);
    plot(samples);
    xlabel('Iteration');
    ylabel('Value');
    title('Trace Plot');

    subplot(2,2,2);
    plot(cumsum(samples) ./ (1:length(samples))');
    xlabel('Iteration');
    ylabel('Running Mean');
    title('Convergence');

    subplot(2,2,3);
    autocorr(samples, min(100, n-1));
    title('Autocorrelation');

    subplot(2,2,4);
    histogram(samples, 50, 'Normalization', 'pdf');
    xlabel('Value');
    ylabel('Density');
    title('Posterior Distribution');
end

% Usage
diagnoseMCMC(samples);
```

### Multiple Chains (R-hat)

```matlab
function rhat = computeRhat(chains)
    % Gelman-Rubin R-hat statistic for multiple chains
    % chains: matrix where each column is a chain

    [n, m] = size(chains);  % n samples, m chains

    % Between-chain variance
    chain_means = mean(chains, 1);
    overall_mean = mean(chain_means);
    B = n * var(chain_means);

    % Within-chain variance
    chain_vars = var(chains, 0, 1);
    W = mean(chain_vars);

    % Pooled variance estimate
    var_plus = ((n-1)/n) * W + (1/n) * B;

    % R-hat
    rhat = sqrt(var_plus / W);

    fprintf('R-hat: %.4f\n', rhat);
    if rhat > 1.1
        warning('R-hat > 1.1 suggests non-convergence. Run longer chains.');
    else
        fprintf('R-hat < 1.1: Chains appear to have converged.\n');
    end
end

% Usage: Run multiple chains
nchains = 4;
nsamples = 5000;
chains = zeros(nsamples, nchains);

for i = 1:nchains
    x0 = randn;  % Different starting point
    chains(:, i) = slicesample(x0, nsamples, 'logpdf', logpdf, 'burnin', 1000);
end

rhat = computeRhat(chains);
```

## Bayesian Model Comparison

### Bayes Factor

```matlab
function [bf, log_bf] = bayesFactor(log_ml1, log_ml2)
    % Bayes factor for comparing two models
    % BF > 1: Evidence for model 1
    % BF < 1: Evidence for model 2

    log_bf = log_ml1 - log_ml2;
    bf = exp(log_bf);

    % Interpretation (Kass & Raftery, 1995)
    abs_log_bf = abs(log_bf);
    if abs_log_bf < 1
        strength = 'Not worth mentioning';
    elseif abs_log_bf < 3
        strength = 'Positive';
    elseif abs_log_bf < 5
        strength = 'Strong';
    else
        strength = 'Very strong';
    end

    fprintf('Bayes Factor: %.4f\n', bf);
    fprintf('Log BF: %.4f\n', log_bf);
    fprintf('Evidence strength: %s for Model %d\n', strength, 1 + (bf < 1));
end

% Example: Compare Normal vs t-distribution for data
data = randn(100, 1);

% Approximate marginal likelihoods via BIC
pd_norm = fitdist(data, 'Normal');
pd_t = fitdist(data, 'tLocationScale');

% BIC approximation: -2*log(ML) ≈ BIC
log_ml_norm = -0.5 * (2*negloglik(pd_norm) + 2*log(length(data)));
log_ml_t = -0.5 * (2*negloglik(pd_t) + 3*log(length(data)));  % t has 3 params

bayesFactor(log_ml_norm, log_ml_t);
```

### Posterior Model Probabilities

```matlab
function posteriorProbs = modelPosterior(log_marginal_likelihoods, prior_probs)
    % Compute posterior model probabilities
    % Assumes equal prior by default

    n_models = length(log_marginal_likelihoods);

    if nargin < 2
        prior_probs = ones(1, n_models) / n_models;  % Uniform prior
    end

    % Log posterior (unnormalized)
    log_posterior = log_marginal_likelihoods + log(prior_probs);

    % Normalize using log-sum-exp trick
    max_log = max(log_posterior);
    log_normalizer = max_log + log(sum(exp(log_posterior - max_log)));
    posteriorProbs = exp(log_posterior - log_normalizer);

    fprintf('Posterior Model Probabilities:\n');
    for i = 1:n_models
        fprintf('  Model %d: %.4f\n', i, posteriorProbs(i));
    end
end

% Compare multiple distributions
dists = {'Normal', 'Lognormal', 'Weibull', 'Gamma'};
log_mls = zeros(1, length(dists));

for i = 1:length(dists)
    try
        pd = fitdist(abs(data) + 0.01, dists{i});  % Ensure positive
        k = numel(pd.ParameterNames);
        log_mls(i) = -negloglik(pd) - 0.5*k*log(length(data));  % Laplace approx
    catch
        log_mls(i) = -Inf;
    end
end

posteriorProbs = modelPosterior(log_mls);
```

## Empirical Bayes

Empirical Bayes estimates prior parameters from data.

```matlab
function [mu_eb, tau_eb] = empiricalBayes(y, sigma)
    % Empirical Bayes estimation of normal prior parameters
    % y_i ~ N(theta_i, sigma^2)
    % theta_i ~ N(mu, tau^2)

    n = length(y);

    % Method of moments estimates
    y_bar = mean(y);
    s2 = var(y);

    % Prior variance estimate
    tau2_hat = max(0, s2 - sigma^2);

    mu_eb = y_bar;
    tau_eb = sqrt(tau2_hat);

    fprintf('Empirical Bayes estimates:\n');
    fprintf('  Prior mean (mu): %.4f\n', mu_eb);
    fprintf('  Prior std (tau): %.4f\n', tau_eb);

    % Shrinkage factor
    B = sigma^2 / (sigma^2 + tau2_hat);
    fprintf('  Shrinkage factor: %.4f\n', B);

    % Posterior means (shrinkage estimates)
    theta_hat = (1 - B) * y + B * mu_eb;

    fprintf('  Shrinkage pulls estimates toward %.4f\n', mu_eb);
end

% Example: Multiple testing with shrinkage
y = [2.1, 1.8, 3.5, 0.5, 2.8, 1.2, 4.0, 0.8];
sigma = 1.0;  % Known observation std

[mu_eb, tau_eb] = empiricalBayes(y, sigma);
```

## Best Practices

1. **Choosing priors:**
   - Use weakly informative priors when uncertain
   - Check sensitivity to prior choice
   - Document and justify prior selection

2. **MCMC convergence:**
   - Run multiple chains from different starting points
   - Check R-hat < 1.1 and effective sample size
   - Discard burn-in samples

3. **Model comparison:**
   - Use cross-validation or WAIC for predictive accuracy
   - Report Bayes factors with uncertainty
   - Consider model averaging for predictions

4. **Computational efficiency:**
   - Use conjugate priors when possible
   - Consider variational inference for large datasets
   - Profile and optimize bottlenecks

## Common Pitfalls

| Pitfall | Solution |
|---------|----------|
| Non-convergent MCMC | Increase iterations, check step size, use better initialization |
| Improper priors | Use proper priors or check that posterior is proper |
| Label switching in mixtures | Post-process to identify components |
| Overconfident posteriors | Verify model assumptions, check prior sensitivity |
| Slow Bayesian optimization | Reduce search space, use early stopping |

---

*See also: classification.md for supervised learning, distributions.md for probability distributions*
