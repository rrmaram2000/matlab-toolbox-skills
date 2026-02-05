# Hypothesis Testing

Statistical hypothesis testing for comparing groups, testing assumptions, and making inferences. This card covers parametric and non-parametric tests commonly used in biomedical research.

## Test Selection Guide

```
How many groups?
├── One sample
│   ├── Normal data → ttest (one-sample t-test)
│   └── Non-normal → signrank (Wilcoxon signed-rank)
├── Two samples
│   ├── Independent
│   │   ├── Normal, equal variance → ttest2
│   │   ├── Normal, unequal variance → ttest2 with 'Vartype','unequal' (Welch's)
│   │   └── Non-normal → ranksum (Wilcoxon rank-sum / Mann-Whitney U)
│   ├── Paired
│   │   ├── Normal → ttest (paired)
│   │   └── Non-normal → signrank (paired)
│   └── Proportions → fishertest or chi2gof
├── 3+ groups
│   ├── Independent
│   │   ├── Normal → anova1 (one-way ANOVA)
│   │   └── Non-normal → kruskalwallis
│   ├── Repeated measures → fitrm + ranova
│   └── Multiple factors → anovan (n-way ANOVA)
├── Correlation
│   ├── Linear → corrcoef + hypothesis test
│   └── Monotonic → corr with 'Type','Spearman'
└── Categorical
    ├── 2×2 table → fishertest
    ├── Larger tables → chi2gof
    └── Goodness of fit → chi2gof
```

## Checking Assumptions

### Normality Tests

```matlab
% Visual inspection (most important)
figure;
subplot(1,2,1);
histogram(data, 'Normalization', 'pdf');
hold on;
x = linspace(min(data), max(data), 100);
plot(x, normpdf(x, mean(data), std(data)), 'r', 'LineWidth', 2);
title('Histogram vs Normal');

subplot(1,2,2);
qqplot(data);
title('Q-Q Plot');

% Formal tests
[h_lill, p_lill] = lillietest(data);     % Lilliefors test
[h_sw, p_sw] = swtest(data);             % Shapiro-Wilk (requires FEX)
[h_ad, p_ad] = adtest(data);             % Anderson-Darling
[h_jb, p_jb] = jbtest(data);             % Jarque-Bera

fprintf('Lilliefors: p = %.4f (Normal: %s)\n', p_lill, string(h_lill == 0));

% Note: With large n, even minor deviations are "significant"
% Visual inspection is more practical
```

### Homogeneity of Variance

```matlab
% Levene's test
p = vartestn(data, groups, 'TestType', 'LeveneAbsolute');

% Bartlett's test (more powerful if data is normal)
p = vartestn(data, groups, 'TestType', 'Bartlett');

% Brown-Forsythe test (robust)
p = vartestn(data, groups, 'TestType', 'BrownForsythe');

fprintf('Variance homogeneity p = %.4f (Homogeneous: %s)\n', p, string(p > 0.05));
```

## One-Sample Tests

### One-Sample t-test

Test if sample mean differs from a hypothesized value.

```matlab
% Two-tailed test: H0: mu = 0
[h, p, ci, stats] = ttest(data);

% Test against specific value
[h, p, ci, stats] = ttest(data, 100);  % H0: mu = 100

% One-tailed tests
[h, p] = ttest(data, 100, 'Tail', 'right');  % H1: mu > 100
[h, p] = ttest(data, 100, 'Tail', 'left');   % H1: mu < 100

% Custom alpha
[h, p, ci, stats] = ttest(data, 100, 'Alpha', 0.01);

fprintf('t(%d) = %.3f, p = %.4f\n', stats.df, stats.tstat, p);
fprintf('95%% CI: [%.3f, %.3f]\n', ci);
```

### Wilcoxon Signed-Rank Test (Non-parametric)

```matlab
% Test if median differs from hypothesized value
[p, h, stats] = signrank(data, 100);

fprintf('Signed-rank statistic = %.1f, p = %.4f\n', stats.signedrank, p);
```

## Two-Sample Tests

### Independent Samples t-test

```matlab
% Standard t-test (assumes equal variances)
[h, p, ci, stats] = ttest2(group1, group2);

% Welch's t-test (unequal variances - usually preferred)
[h, p, ci, stats] = ttest2(group1, group2, 'Vartype', 'unequal');

% One-tailed
[h, p] = ttest2(group1, group2, 'Tail', 'right');  % H1: mu1 > mu2

% Report results
fprintf('t(%.1f) = %.3f, p = %.4f\n', stats.df, stats.tstat, p);
fprintf('Mean difference: %.3f, 95%% CI: [%.3f, %.3f]\n', ...
    mean(group1) - mean(group2), ci);
```

### Mann-Whitney U Test (Wilcoxon Rank-Sum)

Non-parametric alternative to independent t-test.

```matlab
[p, h, stats] = ranksum(group1, group2);

% Effect size: rank-biserial correlation
n1 = length(group1);
n2 = length(group2);
U = stats.ranksum - n1*(n1+1)/2;
rankBiserial = 1 - 2*U/(n1*n2);

fprintf('U = %.1f, p = %.4f\n', U, p);
fprintf('Rank-biserial r = %.3f\n', rankBiserial);
```

### Paired Samples Tests

```matlab
% Paired t-test
[h, p, ci, stats] = ttest(pre_treatment, post_treatment);

% Or equivalently:
differences = post_treatment - pre_treatment;
[h, p, ci, stats] = ttest(differences);

% Non-parametric: Wilcoxon signed-rank
[p, h, stats] = signrank(pre_treatment, post_treatment);

fprintf('Paired t(%d) = %.3f, p = %.4f\n', stats.df, stats.tstat, p);
```

## ANOVA

### One-Way ANOVA

```matlab
% Data in single vector with group labels
[p, tbl, stats] = anova1(data, groups);

% Display ANOVA table
disp(tbl);

% Multiple comparisons (post-hoc)
[c, m, h, gnames] = multcompare(stats);

% Tukey-Kramer (default)
[c, m] = multcompare(stats, 'CType', 'tukey-kramer');

% Bonferroni
[c, m] = multcompare(stats, 'CType', 'bonferroni');

% Dunn-Sidak
[c, m] = multcompare(stats, 'CType', 'dunn-sidak');

% Interpret output: c columns are [group1, group2, lower CI, diff, upper CI, p]
% Significant if CI doesn't include 0
significant_pairs = c(c(:,6) < 0.05, 1:2);
```

### Two-Way ANOVA

```matlab
% Using anovan
y = [...];  % Response variable
factor1 = [...];  % First factor
factor2 = [...];  % Second factor

[p, tbl, stats] = anovan(y, {factor1, factor2}, ...
    'Model', 'interaction', ...          % Include interaction
    'Varnames', {'Factor1', 'Factor2'});

% Post-hoc for main effects
[c, m] = multcompare(stats, 'Dimension', 1);  % Factor 1
[c, m] = multcompare(stats, 'Dimension', 2);  % Factor 2
[c, m] = multcompare(stats, 'Dimension', [1 2]);  % Interaction
```

### Repeated Measures ANOVA

```matlab
% Create table with within-subject measurements
T = table(Subject, Time1, Time2, Time3, 'VariableNames', ...
    {'Subject', 'T1', 'T2', 'T3'});

% Define within-subject design
Within = table({'T1'; 'T2'; 'T3'}, 'VariableNames', {'Time'});

% Fit repeated measures model
rm = fitrm(T, 'T1-T3 ~ 1', 'WithinDesign', Within);

% Run repeated measures ANOVA
ranovatbl = ranova(rm);
disp(ranovatbl);

% Sphericity test (Mauchly's)
mauchly(rm)

% If sphericity violated, use Greenhouse-Geisser or Huynh-Feldt corrections
epsilon(rm)

% Post-hoc pairwise comparisons
margmean(rm, 'Time')
```

### Kruskal-Wallis Test (Non-parametric ANOVA)

```matlab
[p, tbl, stats] = kruskalwallis(data, groups);

% Post-hoc: Dunn's test (multiple comparisons)
[c, m, h, gnames] = multcompare(stats, 'CType', 'dunn-sidak');
```

## Correlation Tests

### Pearson Correlation

```matlab
% Correlation coefficient with significance test
[R, P] = corrcoef(X, Y);
r = R(1,2);
p = P(1,2);

fprintf('r = %.3f, p = %.4f\n', r, p);

% Multiple variables
[R, P] = corrcoef(dataMatrix);
% R is correlation matrix, P is p-value matrix
```

### Spearman Rank Correlation

```matlab
[rho, pval] = corr(X, Y, 'Type', 'Spearman');
fprintf('Spearman rho = %.3f, p = %.4f\n', rho, pval);
```

### Kendall's Tau

```matlab
[tau, pval] = corr(X, Y, 'Type', 'Kendall');
fprintf('Kendall tau = %.3f, p = %.4f\n', tau, pval);
```

### Partial Correlation

```matlab
% Correlation between X and Y controlling for Z
[rho, pval] = partialcorr(X, Y, Z);
```

## Categorical Data Tests

### Chi-Square Test of Independence

```matlab
% From contingency table
observed = [30 10; 20 40];  % 2×2 table
[h, p, stats] = chi2gof_cont(observed);  % Custom function needed

% Using built-in for contingency tables
[tbl, chi2, p, labels] = crosstab(var1, var2);
fprintf('Chi-square = %.2f, p = %.4f\n', chi2, p);
```

### Fisher's Exact Test

For small sample sizes or when chi-square assumptions aren't met.

```matlab
% 2×2 contingency table
x = [10 5; 3 12];  % [a b; c d]
[h, p, stats] = fishertest(x);

fprintf('Odds ratio = %.2f, p = %.4f\n', stats.OddsRatio, p);
```

### Chi-Square Goodness of Fit

```matlab
% Test if observed frequencies match expected
observed = [25, 30, 45];
expected = [33.33, 33.33, 33.33];  % Equal distribution

[h, p, stats] = chi2gof(1:3, 'Frequency', observed, 'Expected', expected);
```

### McNemar's Test (Paired Categorical)

```matlab
% For paired nominal data (e.g., before/after)
% x = [a b; c d] where b and c are discordant pairs
x = [50 10; 5 35];
[h, p, stats] = mcnemar_test(x);  % Custom function or use exact binomial
```

## Effect Size Measures

### Cohen's d (Standardized Mean Difference)

```matlab
function d = cohens_d(group1, group2)
    % Pooled standard deviation
    n1 = length(group1);
    n2 = length(group2);
    pooledStd = sqrt(((n1-1)*var(group1) + (n2-1)*var(group2)) / (n1+n2-2));

    % Cohen's d
    d = (mean(group1) - mean(group2)) / pooledStd;
end

% Interpretation:
% |d| < 0.2: negligible
% 0.2 ≤ |d| < 0.5: small
% 0.5 ≤ |d| < 0.8: medium
% |d| ≥ 0.8: large

d = cohens_d(group1, group2);
fprintf('Cohen''s d = %.3f (%s effect)\n', d, effect_size_label(abs(d)));
```

### Eta-squared (ANOVA Effect Size)

```matlab
[p, tbl, stats] = anova1(data, groups);

% From ANOVA table
SS_between = tbl{2, 2};
SS_total = tbl{4, 2};
eta_sq = SS_between / SS_total;

% Interpretation:
% eta² < 0.01: negligible
% 0.01 ≤ eta² < 0.06: small
% 0.06 ≤ eta² < 0.14: medium
% eta² ≥ 0.14: large

fprintf('Eta-squared = %.3f\n', eta_sq);
```

### Odds Ratio (Categorical)

```matlab
% From 2×2 table [a b; c d]
x = [30 10; 15 45];
OR = (x(1,1) * x(2,2)) / (x(1,2) * x(2,1));

% 95% CI for log(OR)
se_log_OR = sqrt(1/x(1,1) + 1/x(1,2) + 1/x(2,1) + 1/x(2,2));
CI_low = exp(log(OR) - 1.96 * se_log_OR);
CI_high = exp(log(OR) + 1.96 * se_log_OR);

fprintf('OR = %.2f (95%% CI: %.2f - %.2f)\n', OR, CI_low, CI_high);
```

## Multiple Testing Correction

### Bonferroni Correction

```matlab
alpha = 0.05;
num_tests = 10;
alpha_corrected = alpha / num_tests;

% Apply to p-values
p_values = [0.01, 0.03, 0.001, 0.08, 0.02];
p_bonferroni = min(p_values * num_tests, 1);
significant_bonferroni = p_values < alpha_corrected;
```

### Benjamini-Hochberg (FDR)

```matlab
function [h, crit_p, adj_ci_cvrg, adj_p] = fdr_bh(pvals, q)
    % Benjamini-Hochberg FDR correction
    % q: desired FDR level (default 0.05)
    if nargin < 2
        q = 0.05;
    end

    m = length(pvals);
    [sorted_p, sort_idx] = sort(pvals);

    % Critical values
    crit_p = (1:m)' / m * q;

    % Find threshold
    max_idx = find(sorted_p <= crit_p, 1, 'last');
    if isempty(max_idx)
        h = false(size(pvals));
    else
        thresh = sorted_p(max_idx);
        h = pvals <= thresh;
    end

    % Adjusted p-values
    adj_p = zeros(size(pvals));
    adj_p(sort_idx) = min(cummin(sorted_p(end:-1:1) .* m ./ (m:-1:1)'), 1);
    adj_p(sort_idx) = adj_p(sort_idx(end:-1:1));
end

p_values = [0.01, 0.03, 0.001, 0.08, 0.02];
[h, ~, ~, p_adj] = fdr_bh(p_values, 0.05);
```

## Power Analysis

### Sample Size Calculation

```matlab
% For two-sample t-test
effect_size = 0.5;  % Cohen's d (medium effect)
alpha = 0.05;
power = 0.80;

n = sampsizepwr('t2', [0 1], effect_size, power, [], 'Alpha', alpha);
fprintf('Required n per group: %d\n', ceil(n));

% For different effect sizes
effect_sizes = [0.2, 0.5, 0.8];  % Small, medium, large
for i = 1:length(effect_sizes)
    n = sampsizepwr('t2', [0 1], effect_sizes(i), power, [], 'Alpha', alpha);
    fprintf('d = %.1f: n = %d per group\n', effect_sizes(i), ceil(n));
end
```

### Post-hoc Power Analysis

```matlab
% Calculate achieved power given sample size and effect size
n = 30;  % Per group
effect_size = 0.5;
alpha = 0.05;

power = sampsizepwr('t2', [0 1], effect_size, [], n, 'Alpha', alpha);
fprintf('Achieved power: %.2f\n', power);
```

## Complete Biomedical Example

```matlab
%% Clinical Trial Analysis: Treatment vs Placebo

% 1. Load data
treatment = [23, 25, 28, 22, 27, 30, 26, 24, 29, 31, 28, 25];
placebo = [18, 20, 22, 19, 21, 17, 23, 20, 19, 22, 18, 21];

% 2. Descriptive statistics
fprintf('Treatment: Mean = %.2f, SD = %.2f, n = %d\n', ...
    mean(treatment), std(treatment), length(treatment));
fprintf('Placebo: Mean = %.2f, SD = %.2f, n = %d\n', ...
    mean(placebo), std(placebo), length(placebo));

% 3. Check normality
figure;
subplot(2,2,1); qqplot(treatment); title('Treatment Q-Q');
subplot(2,2,2); qqplot(placebo); title('Placebo Q-Q');
subplot(2,2,3); histogram(treatment); title('Treatment Hist');
subplot(2,2,4); histogram(placebo); title('Placebo Hist');

[~, p_norm_t] = lillietest(treatment);
[~, p_norm_p] = lillietest(placebo);
fprintf('Normality p-values: Treatment = %.4f, Placebo = %.4f\n', p_norm_t, p_norm_p);

% 4. Check variance homogeneity
all_data = [treatment, placebo];
groups = [repmat({'Treatment'}, 1, length(treatment)), repmat({'Placebo'}, 1, length(placebo))];
p_var = vartestn(all_data', groups', 'Display', 'off');
fprintf('Variance homogeneity p = %.4f\n', p_var);

% 5. Perform appropriate test
if p_norm_t > 0.05 && p_norm_p > 0.05  % Both normal
    if p_var > 0.05  % Equal variances
        [h, p, ci, stats] = ttest2(treatment, placebo);
        test_name = 'Independent t-test';
    else  % Unequal variances
        [h, p, ci, stats] = ttest2(treatment, placebo, 'Vartype', 'unequal');
        test_name = 'Welch''s t-test';
    end
    fprintf('%s: t(%.1f) = %.3f, p = %.4f\n', test_name, stats.df, stats.tstat, p);
    fprintf('Mean difference 95%% CI: [%.3f, %.3f]\n', ci);
else  % Non-normal
    [p, h, stats] = ranksum(treatment, placebo);
    fprintf('Mann-Whitney U test: U = %.1f, p = %.4f\n', stats.ranksum, p);
end

% 6. Effect size
d = (mean(treatment) - mean(placebo)) / ...
    sqrt(((length(treatment)-1)*var(treatment) + (length(placebo)-1)*var(placebo)) / ...
    (length(treatment) + length(placebo) - 2));
fprintf('Cohen''s d = %.3f\n', d);

% 7. Interpretation
if p < 0.05
    fprintf('\nConclusion: Significant difference between treatment and placebo (p = %.4f)\n', p);
    fprintf('Treatment group showed %.1f%% higher scores on average.\n', ...
        (mean(treatment) - mean(placebo)) / mean(placebo) * 100);
else
    fprintf('\nConclusion: No significant difference detected (p = %.4f)\n', p);
end
```

## Function Quick Reference

| Function | Purpose | Key Parameters |
|----------|---------|----------------|
| `ttest` | One-sample or paired t-test | Tail, Alpha |
| `ttest2` | Two-sample t-test | Vartype, Tail, Alpha |
| `signrank` | Wilcoxon signed-rank | — |
| `ranksum` | Wilcoxon rank-sum (Mann-Whitney) | — |
| `anova1` | One-way ANOVA | — |
| `anovan` | N-way ANOVA | Model, Varnames |
| `kruskalwallis` | Non-parametric ANOVA | — |
| `multcompare` | Post-hoc comparisons | CType, Dimension |
| `fitrm` | Repeated measures setup | WithinDesign |
| `ranova` | Repeated measures ANOVA | — |
| `corrcoef` | Pearson correlation | — |
| `corr` | Correlation (Spearman, Kendall) | Type |
| `fishertest` | Fisher's exact test | — |
| `chi2gof` | Chi-square goodness of fit | — |
| `lillietest` | Normality test | — |
| `vartestn` | Variance homogeneity | TestType |
| `sampsizepwr` | Power analysis | — |

---

*Source: MathWorks Statistics and Machine Learning Toolbox Documentation (R2025a)*
