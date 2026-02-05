# Probability Distributions

MATLAB provides comprehensive support for probability distributions through distribution objects (`makedist`, `fitdist`) and direct functions. This card covers distribution fitting, comparison, and diagnostics.

## Distribution Object Framework

### Creating Distribution Objects

```matlab
% Method 1: From known parameters
pd_norm = makedist('Normal', 'mu', 100, 'sigma', 15);
pd_exp = makedist('Exponential', 'mu', 5);
pd_weib = makedist('Weibull', 'a', 10, 'b', 2);  % a=scale, b=shape
pd_gamma = makedist('Gamma', 'a', 2, 'b', 3);    % a=shape, b=scale

% Method 2: Fit to data
data = randn(1000, 1) * 15 + 100;  % Sample from N(100, 15)
pd_fitted = fitdist(data, 'Normal');

% Display fitted parameters
fprintf('Fitted mean: %.2f (true: 100)\n', pd_fitted.mu);
fprintf('Fitted std: %.2f (true: 15)\n', pd_fitted.sigma);
```

### Distribution Object Methods

```matlab
% All distribution objects support these methods:
pd = makedist('Normal', 'mu', 0, 'sigma', 1);

% Probability density function (PDF)
x = linspace(-4, 4, 100);
y_pdf = pdf(pd, x);

% Cumulative distribution function (CDF)
y_cdf = cdf(pd, x);

% Inverse CDF (quantile function)
p = [0.025, 0.5, 0.975];
quantiles = icdf(pd, p);
fprintf('2.5%%, 50%%, 97.5%% quantiles: %.3f, %.3f, %.3f\n', quantiles);

% Random number generation
samples = random(pd, 1000, 1);

% Mean and variance
fprintf('Mean: %.4f, Variance: %.4f\n', mean(pd), var(pd));

% Negative log-likelihood (for fitted distributions)
pd_fit = fitdist(data, 'Normal');
nll = negloglik(pd_fit);
fprintf('Negative log-likelihood: %.2f\n', nll);

% Parameter confidence intervals
ci = paramci(pd_fit);
fprintf('95%% CI for mu: [%.2f, %.2f]\n', ci(1,1), ci(2,1));
fprintf('95%% CI for sigma: [%.2f, %.2f]\n', ci(1,2), ci(2,2));
```

### Visualizing Distributions

```matlab
pd = fitdist(data, 'Normal');

figure;

% PDF with histogram
subplot(2,2,1);
histogram(data, 'Normalization', 'pdf');
hold on;
x = linspace(min(data), max(data), 100);
plot(x, pdf(pd, x), 'r-', 'LineWidth', 2);
xlabel('Value');
ylabel('Density');
title('PDF');
legend('Data', 'Fitted Normal');

% CDF with empirical CDF
subplot(2,2,2);
[f, xvals] = ecdf(data);
stairs(xvals, f, 'b', 'LineWidth', 1.5);
hold on;
plot(x, cdf(pd, x), 'r-', 'LineWidth', 2);
xlabel('Value');
ylabel('Cumulative Probability');
title('CDF');
legend('Empirical', 'Fitted Normal');

% Q-Q plot
subplot(2,2,3);
qqplot(data, pd);
title('Q-Q Plot');

% P-P plot
subplot(2,2,4);
theoretical_cdf = cdf(pd, sort(data));
empirical_cdf = (1:length(data))' / length(data);
plot(theoretical_cdf, empirical_cdf, 'bo');
hold on;
plot([0 1], [0 1], 'r--', 'LineWidth', 2);
xlabel('Theoretical CDF');
ylabel('Empirical CDF');
title('P-P Plot');
axis square;
```

## Common Continuous Distributions

### Normal (Gaussian) Distribution

```matlab
% Standard normal
pd_std = makedist('Normal');  % mu=0, sigma=1

% Custom parameters
pd_norm = makedist('Normal', 'mu', 50, 'sigma', 10);

% Fit to data
pd_fit = fitdist(data, 'Normal');

% Standard normal quantiles (z-scores)
z_95 = icdf(pd_std, 0.975);  % 1.96
fprintf('95%% critical value (two-tailed): ±%.4f\n', z_95);

% Probability calculations
p_below_60 = cdf(pd_norm, 60);
fprintf('P(X < 60) = %.4f\n', p_below_60);

p_between = cdf(pd_norm, 70) - cdf(pd_norm, 40);
fprintf('P(40 < X < 70) = %.4f\n', p_between);
```

### Lognormal Distribution

```matlab
% For positive, right-skewed data (incomes, concentrations, sizes)
pd_ln = makedist('Lognormal', 'mu', 2, 'sigma', 0.5);

% Mean and variance are NOT mu and sigma^2!
% Mean = exp(mu + sigma^2/2)
% Var = (exp(sigma^2) - 1) * exp(2*mu + sigma^2)

fprintf('Lognormal mean: %.4f\n', mean(pd_ln));
fprintf('Lognormal median: %.4f\n', exp(2));  % exp(mu)
fprintf('Lognormal mode: %.4f\n', exp(2 - 0.5^2));  % exp(mu - sigma^2)

% Fit lognormal
positive_data = exp(randn(1000, 1) * 0.5 + 2);
pd_ln_fit = fitdist(positive_data, 'Lognormal');
```

### Weibull Distribution

```matlab
% Common for reliability analysis, survival data
% Shape parameter (b) interpretation:
%   b < 1: Decreasing hazard (infant mortality)
%   b = 1: Constant hazard (exponential)
%   b > 1: Increasing hazard (wear-out)

pd_weib = makedist('Weibull', 'a', 100, 'b', 2);  % a=scale, b=shape

% Reliability function: P(T > t) = 1 - CDF
t = 50;
reliability = 1 - cdf(pd_weib, t);
fprintf('Reliability at t=%d: %.4f\n', t, reliability);

% Characteristic life (scale parameter a): 63.2% failure point
char_life = icdf(pd_weib, 1 - exp(-1));  % Should equal 'a'
fprintf('Characteristic life: %.2f\n', char_life);

% Fit Weibull
failure_times = random(pd_weib, 100, 1);
pd_weib_fit = fitdist(failure_times, 'Weibull');
fprintf('Fitted scale: %.2f, shape: %.2f\n', pd_weib_fit.a, pd_weib_fit.b);
```

### Gamma Distribution

```matlab
% Shape (a) and scale (b) parameterization
pd_gamma = makedist('Gamma', 'a', 3, 'b', 2);

% Mean = a*b, Variance = a*b^2
fprintf('Gamma mean: %.4f (expected: %.4f)\n', mean(pd_gamma), 3*2);

% Special case: Exponential is Gamma(1, b)
pd_exp = makedist('Exponential', 'mu', 5);
pd_gamma1 = makedist('Gamma', 'a', 1, 'b', 5);
% These are equivalent

% Fit gamma
gamma_data = random(pd_gamma, 500, 1);
pd_gamma_fit = fitdist(gamma_data, 'Gamma');
```

### Exponential Distribution

```matlab
% Memoryless distribution for waiting times
pd_exp = makedist('Exponential', 'mu', 5);  % Mean = 5

% Rate parameter lambda = 1/mu
lambda = 1 / pd_exp.mu;
fprintf('Rate: %.4f events per unit time\n', lambda);

% Memoryless property: P(T > s+t | T > s) = P(T > t)
% If you've waited 10 units, the remaining wait time distribution is the same

% Survival function
t = 3;
survival = 1 - cdf(pd_exp, t);  % = exp(-lambda*t)
fprintf('P(T > %d) = %.4f\n', t, survival);
```

### Beta Distribution

```matlab
% For proportions and probabilities (bounded [0,1])
pd_beta = makedist('Beta', 'a', 2, 'b', 5);

% Mean = a/(a+b)
fprintf('Beta mean: %.4f\n', mean(pd_beta));

% Uniform is Beta(1,1)
pd_uniform = makedist('Beta', 'a', 1, 'b', 1);

% Different shapes based on a and b
figure;
alphas = [0.5, 1, 2, 5];
betas = [0.5, 1, 5, 2];
x = linspace(0, 1, 100);

for i = 1:4
    subplot(2, 2, i);
    pd = makedist('Beta', 'a', alphas(i), 'b', betas(i));
    plot(x, pdf(pd, x), 'LineWidth', 2);
    title(sprintf('Beta(%.1f, %.1f)', alphas(i), betas(i)));
    xlabel('x');
    ylabel('Density');
end
sgtitle('Beta Distribution Shapes');
```

## Common Discrete Distributions

### Binomial Distribution

```matlab
% Number of successes in n trials with probability p
pd_binom = makedist('Binomial', 'N', 100, 'p', 0.3);

% Probability of exactly k successes
k = 30;
p_exact = pdf(pd_binom, k);
fprintf('P(X = %d) = %.4f\n', k, p_exact);

% Probability of at most k successes
p_atmost = cdf(pd_binom, k);
fprintf('P(X <= %d) = %.4f\n', k, p_atmost);

% Expected value and variance
fprintf('E[X] = %.2f, Var(X) = %.2f\n', mean(pd_binom), var(pd_binom));
% E[X] = n*p, Var(X) = n*p*(1-p)
```

### Poisson Distribution

```matlab
% Count of events in fixed interval (given rate lambda)
pd_pois = makedist('Poisson', 'lambda', 5);

% Probability of observing k events
for k = 0:10
    fprintf('P(X = %d) = %.4f\n', k, pdf(pd_pois, k));
end

% Mean = Variance = lambda
fprintf('\nMean = Variance = %.2f\n', mean(pd_pois));
```

### Negative Binomial

```matlab
% Number of failures before r successes
pd_nb = makedist('NegativeBinomial', 'R', 5, 'P', 0.3);

% Useful for overdispersed count data (Var > Mean)
fprintf('Mean: %.2f, Variance: %.2f\n', mean(pd_nb), var(pd_nb));
```

## Fitting and Model Selection

### Fit Multiple Distributions

```matlab
function results = fitMultipleDistributions(data)
    % Fit common distributions and compare via AIC/BIC

    distributions = {'Normal', 'Lognormal', 'Weibull', 'Gamma', ...
                     'Exponential', 'Logistic', 'ExtremeValue'};

    results = struct('Name', {}, 'NLL', {}, 'AIC', {}, 'BIC', {}, 'PD', {});
    n = length(data);

    for i = 1:length(distributions)
        try
            pd = fitdist(data, distributions{i});
            nll = negloglik(pd);
            k = numel(pd.ParameterNames);

            % AIC = 2k + 2*NLL
            aic = 2*k + 2*nll;

            % BIC = k*log(n) + 2*NLL
            bic = k*log(n) + 2*nll;

            results(end+1) = struct('Name', distributions{i}, ...
                'NLL', nll, 'AIC', aic, 'BIC', bic, 'PD', pd);
        catch
            % Distribution doesn't fit (e.g., negative data for Lognormal)
        end
    end

    % Sort by AIC
    [~, idx] = sort([results.AIC]);
    results = results(idx);

    % Display
    fprintf('Distribution Comparison (sorted by AIC):\n');
    fprintf('%-15s %10s %10s %10s\n', 'Distribution', 'NLL', 'AIC', 'BIC');
    fprintf('%s\n', repmat('-', 1, 50));
    for i = 1:length(results)
        fprintf('%-15s %10.2f %10.2f %10.2f\n', ...
            results(i).Name, results(i).NLL, results(i).AIC, results(i).BIC);
    end

    fprintf('\nBest fit: %s\n', results(1).Name);
end

% Usage
results = fitMultipleDistributions(data);
```

### AIC and BIC Interpretation

```matlab
% AIC (Akaike Information Criterion)
% - Lower is better
% - AIC difference < 2: No meaningful difference
% - AIC difference 2-10: Less support for higher AIC model
% - AIC difference > 10: Essentially no support

% BIC (Bayesian Information Criterion)
% - Penalizes model complexity more than AIC
% - Better for model selection when n is large
% - Use BIC when parsimony is important

function interpretAIC(aic_values, model_names)
    [min_aic, best_idx] = min(aic_values);
    delta_aic = aic_values - min_aic;

    fprintf('AIC Model Comparison:\n');
    fprintf('%-20s %10s %10s %s\n', 'Model', 'AIC', 'Delta AIC', 'Support');
    fprintf('%s\n', repmat('-', 1, 60));

    for i = 1:length(aic_values)
        if delta_aic(i) < 2
            support = 'Strong';
        elseif delta_aic(i) < 10
            support = 'Moderate';
        else
            support = 'Weak';
        end
        fprintf('%-20s %10.2f %10.2f %s\n', ...
            model_names{i}, aic_values(i), delta_aic(i), support);
    end
end
```

## Goodness-of-Fit Tests

### Kolmogorov-Smirnov Test

```matlab
% Test if data comes from a specific distribution
pd = makedist('Normal', 'mu', 0, 'sigma', 1);

% One-sample K-S test
[h, p, ksstat] = kstest(data, 'CDF', pd);

fprintf('K-S Test:\n');
fprintf('  Statistic: %.4f\n', ksstat);
fprintf('  p-value: %.4f\n', p);
if h == 0
    fprintf('  Result: Cannot reject null (data consistent with distribution)\n');
else
    fprintf('  Result: Reject null (data NOT from this distribution)\n');
end

% K-S test with fitted distribution (use Lilliefors for normal)
[h, p] = lillietest(data);  % Tests normality specifically
fprintf('\nLilliefors test for normality: p = %.4f\n', p);
```

### Chi-Square Goodness-of-Fit

```matlab
% For discrete distributions or binned continuous data
observed = histcounts(data, 10);  % 10 bins
n = length(data);
pd = fitdist(data, 'Normal');

% Expected counts
edges = linspace(min(data), max(data), 11);
expected = n * diff(cdf(pd, edges));

% Chi-square test
[h, p, stats] = chi2gof(data, 'CDF', pd);

fprintf('Chi-square GOF test:\n');
fprintf('  Chi-square: %.4f, df: %d\n', stats.chi2stat, stats.df);
fprintf('  p-value: %.4f\n', p);
```

### Anderson-Darling Test

```matlab
% More sensitive in the tails than K-S test
[h, p, adstat, cv] = adtest(data, 'Distribution', 'normal');

fprintf('Anderson-Darling test:\n');
fprintf('  Statistic: %.4f\n', adstat);
fprintf('  Critical value (5%%): %.4f\n', cv);
fprintf('  p-value: %.4f\n', p);
```

### Visual Diagnostics

```matlab
function plotGOFDiagnostics(data, pd)
    figure;

    % 1. Histogram with fitted PDF
    subplot(2,2,1);
    histogram(data, 'Normalization', 'pdf', 'FaceAlpha', 0.7);
    hold on;
    x = linspace(min(data), max(data), 200);
    plot(x, pdf(pd, x), 'r-', 'LineWidth', 2);
    xlabel('Value');
    ylabel('Density');
    title('Histogram vs Fitted PDF');

    % 2. Q-Q plot
    subplot(2,2,2);
    qqplot(data, pd);
    title('Q-Q Plot');

    % 3. CDF comparison
    subplot(2,2,3);
    [f, xval] = ecdf(data);
    stairs(xval, f, 'b', 'LineWidth', 1.5);
    hold on;
    plot(x, cdf(pd, x), 'r-', 'LineWidth', 2);
    xlabel('Value');
    ylabel('CDF');
    title('Empirical vs Fitted CDF');
    legend('Empirical', 'Fitted', 'Location', 'best');

    % 4. Residual plot (standardized)
    subplot(2,2,4);
    sorted_data = sort(data);
    theoretical_quantiles = icdf(pd, (1:length(data))' / (length(data)+1));
    residuals = sorted_data - theoretical_quantiles;
    stem(1:length(data), residuals, 'b.');
    xlabel('Order');
    ylabel('Residual');
    title('Residual Plot');
    yline(0, 'r--');

    sgtitle(sprintf('GOF Diagnostics: %s', class(pd)));
end

% Usage
pd = fitdist(data, 'Normal');
plotGOFDiagnostics(data, pd);
```

## Nonparametric Density Estimation

### Kernel Density Estimation

```matlab
% When no parametric form is assumed
pd_kernel = fitdist(data, 'Kernel');

% With custom bandwidth
pd_kernel_custom = fitdist(data, 'Kernel', 'BandWidth', 1.5);

% Different kernel functions
kernel_types = {'normal', 'box', 'triangle', 'epanechnikov'};

figure;
x = linspace(min(data)-2, max(data)+2, 200);
for i = 1:length(kernel_types)
    pd = fitdist(data, 'Kernel', 'Kernel', kernel_types{i});
    plot(x, pdf(pd, x), 'LineWidth', 2);
    hold on;
end
legend(kernel_types);
xlabel('Value');
ylabel('Density');
title('Kernel Density Estimation');
```

### Bandwidth Selection

```matlab
% Default: Rule of thumb (Silverman)
pd_default = fitdist(data, 'Kernel');
fprintf('Default bandwidth: %.4f\n', pd_default.BandWidth);

% Cross-validation for bandwidth selection
function optimal_bw = selectBandwidthCV(data, bw_range)
    n = length(data);
    cv_scores = zeros(size(bw_range));

    for i = 1:length(bw_range)
        bw = bw_range(i);
        loo_ll = 0;

        for j = 1:n
            % Leave one out
            train_data = data([1:j-1, j+1:n]);
            test_point = data(j);

            % Fit KDE without j-th point
            pd = fitdist(train_data, 'Kernel', 'BandWidth', bw);

            % Log-likelihood of left-out point
            loo_ll = loo_ll + log(pdf(pd, test_point) + eps);
        end

        cv_scores(i) = loo_ll;
    end

    [~, idx] = max(cv_scores);
    optimal_bw = bw_range(idx);

    % Plot
    figure;
    plot(bw_range, cv_scores, 'b-o', 'LineWidth', 2);
    xline(optimal_bw, 'r--', sprintf('Optimal: %.2f', optimal_bw));
    xlabel('Bandwidth');
    ylabel('Leave-One-Out Log-Likelihood');
    title('Bandwidth Selection via CV');
end

% Usage
bw_range = linspace(0.5, 5, 20);
optimal_bw = selectBandwidthCV(data, bw_range);
```

## Multivariate Distributions

### Multivariate Normal

```matlab
% Mean vector and covariance matrix
mu = [1, 2];
Sigma = [1, 0.5; 0.5, 2];

% Random samples
rng(42);
X = mvnrnd(mu, Sigma, 1000);

% Density at specific points
point = [1.5, 2.5];
density = mvnpdf(point, mu, Sigma);
fprintf('Density at [1.5, 2.5]: %.4f\n', density);

% Visualize
figure;
subplot(1,2,1);
scatter(X(:,1), X(:,2), 10, 'filled', 'MarkerFaceAlpha', 0.3);
hold on;
plot(mu(1), mu(2), 'r+', 'MarkerSize', 20, 'LineWidth', 3);
xlabel('X1');
ylabel('X2');
title('Multivariate Normal Samples');
axis equal;

subplot(1,2,2);
[X1, X2] = meshgrid(linspace(-2, 4, 100), linspace(-2, 6, 100));
Z = mvnpdf([X1(:), X2(:)], mu, Sigma);
Z = reshape(Z, size(X1));
contourf(X1, X2, Z, 20);
colorbar;
xlabel('X1');
ylabel('X2');
title('Bivariate Normal Density');
```

### Copulas for Dependence Modeling

```matlab
% Copulas separate marginal distributions from dependence structure
% Useful when marginals are non-normal but correlated

% Fit copula to data
U = [normcdf(data(:,1)), normcdf(data(:,2))];  % Transform to uniform

% Gaussian copula
rho = copulafit('Gaussian', U);
fprintf('Gaussian copula correlation: %.4f\n', rho);

% Generate correlated samples with arbitrary marginals
n = 1000;
U_sim = copularnd('Gaussian', rho, n);

% Transform back to desired marginals
pd1 = makedist('Gamma', 'a', 2, 'b', 1);
pd2 = makedist('Weibull', 'a', 3, 'b', 2);

X1 = icdf(pd1, U_sim(:,1));
X2 = icdf(pd2, U_sim(:,2));

figure;
scatter(X1, X2, 10, 'filled', 'MarkerFaceAlpha', 0.3);
xlabel('Gamma(2,1)');
ylabel('Weibull(3,2)');
title('Correlated Non-Normal via Copula');
```

## Mixture Models

### Gaussian Mixture Models

```matlab
% Fit GMM to data with multiple clusters
k = 3;  % Number of components
GMModel = fitgmdist(data, k, ...
    'CovarianceType', 'full', ...  % or 'diagonal', 'spherical'
    'SharedCovariance', false, ...
    'Replicates', 10);             % Multiple starts

% Component parameters
for i = 1:k
    fprintf('Component %d:\n', i);
    fprintf('  Weight: %.4f\n', GMModel.ComponentProportion(i));
    fprintf('  Mean: %.4f\n', GMModel.mu(i));
    fprintf('  Variance: %.4f\n', GMModel.Sigma(i));
end

% Posterior probabilities (soft clustering)
[idx, nlogl, P] = cluster(GMModel, data);

% Visualization
figure;
histogram(data, 50, 'Normalization', 'pdf', 'FaceAlpha', 0.5);
hold on;
x = linspace(min(data), max(data), 200);
plot(x, pdf(GMModel, x'), 'r-', 'LineWidth', 2);
xlabel('Value');
ylabel('Density');
title('Gaussian Mixture Model');
```

### Selecting Number of Components

```matlab
function bestK = selectGMMComponents(data, maxK)
    % Select number of GMM components via BIC
    n = length(data);
    bic_values = zeros(maxK, 1);

    for k = 1:maxK
        try
            GMModel = fitgmdist(data, k, 'Replicates', 5);
            bic_values(k) = GMModel.BIC;
        catch
            bic_values(k) = Inf;
        end
    end

    [~, bestK] = min(bic_values);

    figure;
    plot(1:maxK, bic_values, 'b-o', 'LineWidth', 2);
    xline(bestK, 'r--', sprintf('Optimal k=%d', bestK));
    xlabel('Number of Components');
    ylabel('BIC');
    title('GMM Component Selection');
end

% Usage
bestK = selectGMMComponents(data, 10);
```

## Best Practices

1. **Always visualize** data before fitting (histogram, boxplot, Q-Q plot)

2. **Check domain constraints:**
   - Lognormal, Weibull, Gamma, Exponential: data must be positive
   - Beta: data must be in [0, 1]

3. **Sample size guidelines:**
   - At least 30 observations for stable parameter estimates
   - Use bootstrap for confidence intervals with small samples

4. **Multiple comparison:**
   - Fit several candidate distributions
   - Compare via AIC/BIC (lower is better)
   - Validate with goodness-of-fit tests

5. **Report uncertainty:**
   - Always report parameter confidence intervals
   - Use `paramci` for fitted distributions

## Common Pitfalls

| Pitfall | Solution |
|---------|----------|
| Fitting Lognormal to data with zeros | Add small constant or use Gamma |
| Using K-S test for fitted distribution | Use Lilliefors (accounts for estimation) |
| Ignoring censoring in survival data | Use `fitdist(..., 'Censoring', cens)` |
| Overfitting with mixture models | Use BIC, not AIC, for component selection |
| Assuming normality | Always test; biomedical data often non-normal |

---

*See also: hypothesis-testing.md for statistical tests, survival-analysis.md for censored data*
