# Hypothesis Testing — Clinical Trial Patterns

The model already knows `ttest`, `ttest2`, `anova1`, `anovan`, `ranksum`, `signrank`, `kruskalwallis`, `chi2gof`, `fishertest`, `corrcoef`, `corr`, `multcompare`, `lillietest`, and `vartestn`. This card covers only clinical trial-specific patterns.

## Clinical Test Selection Flowchart

```
Clinical study design?
├── Treatment vs control (continuous outcome)
│   ├── Check normality → lillietest or qqplot
│   ├── Normal + equal variance → ttest2
│   ├── Normal + unequal variance → ttest2(..., 'Vartype', 'unequal')
│   └── Non-normal → ranksum (Mann-Whitney U)
├── Pre-treatment vs post-treatment (same patients)
│   ├── Normal differences → ttest (paired)
│   └── Non-normal → signrank
├── Multi-arm trial (3+ treatments)
│   ├── Normal → anova1, then multcompare for post-hoc
│   └── Non-normal → kruskalwallis
├── Repeated measures (multiple timepoints per patient)
│   └── fitrm + ranova (check sphericity with mauchly)
├── Categorical outcome (response yes/no)
│   ├── 2x2 table (small n) → fishertest
│   └── Larger table → crosstab (returns chi2 and p)
└── Time-to-event → see survival-analysis.md
```

## Complete Clinical Trial Analysis

```matlab
%% Treatment vs Placebo Comparison
treatment = [23, 25, 28, 22, 27, 30, 26, 24, 29, 31, 28, 25];
placebo = [18, 20, 22, 19, 21, 17, 23, 20, 19, 22, 18, 21];

% 1. Descriptive statistics
fprintf('Treatment: Mean=%.2f, SD=%.2f, n=%d\n', ...
    mean(treatment), std(treatment), length(treatment));
fprintf('Placebo: Mean=%.2f, SD=%.2f, n=%d\n', ...
    mean(placebo), std(placebo), length(placebo));

% 2. Check normality (visual + formal)
[~, p_norm_t] = lillietest(treatment);
[~, p_norm_p] = lillietest(placebo);

% 3. Check variance homogeneity
allData = [treatment, placebo]';
groups = [repmat({'Treatment'}, length(treatment), 1); ...
          repmat({'Placebo'}, length(placebo), 1)];
p_var = vartestn(allData, groups, 'Display', 'off');

% 4. Choose appropriate test
if p_norm_t > 0.05 && p_norm_p > 0.05
    [h, p, ci, stats] = ttest2(treatment, placebo, 'Vartype', 'unequal');
    fprintf('Welch t-test: t(%.1f)=%.3f, p=%.4f\n', stats.df, stats.tstat, p);
else
    [p, h, stats] = ranksum(treatment, placebo);
    fprintf('Mann-Whitney U: p=%.4f\n', p);
end

% 5. Effect size (always report!)
pooledStd = sqrt(((length(treatment)-1)*var(treatment) + ...
    (length(placebo)-1)*var(placebo)) / (length(treatment)+length(placebo)-2));
d = (mean(treatment) - mean(placebo)) / pooledStd;
fprintf('Cohen''s d = %.3f\n', d);

% 6. Power analysis
n_required = sampsizepwr('t2', [0 1], 0.5, 0.80);
fprintf('N required per group (d=0.5, power=0.80): %d\n', ceil(n_required));
```

## Multiple Testing Correction

Critical when testing many biomarkers or multiple endpoints.

```matlab
% Benjamini-Hochberg FDR correction (preferred over Bonferroni in genomics)
p_values = [0.001, 0.01, 0.02, 0.03, 0.08, 0.15, 0.45];
m = length(p_values);
[sorted_p, sort_idx] = sort(p_values);
threshold = (1:m)' / m * 0.05;  % FDR = 5%
significant = sorted_p <= threshold;
k = find(significant, 1, 'last');
if ~isempty(k)
    fdr_threshold = sorted_p(k);
    sig_features = sort_idx(1:k);
    fprintf('FDR-significant: %d features (threshold p=%.4f)\n', k, fdr_threshold);
end

% Bonferroni (conservative, use for few comparisons)
alpha_corrected = 0.05 / m;
```

## Effect Size Measures for Clinical Studies

```matlab
% Cohen's d (standardized mean difference)
d = (mean(group1) - mean(group2)) / pooledStd;
% |d| < 0.2: negligible, 0.2-0.5: small, 0.5-0.8: medium, >= 0.8: large

% Eta-squared from ANOVA
[p, tbl, stats] = anova1(data, groups, 'off');
eta_sq = tbl{2,2} / tbl{4,2};  % SS_between / SS_total

% Odds ratio from 2x2 table
x = [a b; c d];  % contingency table
OR = (a*d) / (b*c);
se_log_OR = sqrt(1/a + 1/b + 1/c + 1/d);
CI = exp(log(OR) + [-1.96, 1.96] * se_log_OR);
fprintf('OR = %.2f (95%% CI: %.2f-%.2f)\n', OR, CI(1), CI(2));
```

## Repeated Measures for Longitudinal Studies

```matlab
% Multiple timepoints per patient
T = table(Subject, Baseline, Month3, Month6, Month12);
Within = table({'Baseline'; 'Month3'; 'Month6'; 'Month12'}, 'VariableNames', {'Time'});
rm = fitrm(T, 'Baseline-Month12 ~ Treatment', 'WithinDesign', Within);
ranovatbl = ranova(rm);

% Check sphericity (if violated, use Greenhouse-Geisser correction)
mauchly(rm)
epsilon(rm)
```

---

*See also: scripts/template_hypothesis_testing.m, survival-analysis.md for time-to-event comparisons*
