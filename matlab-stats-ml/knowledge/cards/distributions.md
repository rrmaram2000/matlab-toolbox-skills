# Distributions — Clinical Measurement Patterns

The model already knows `makedist`, `fitdist`, `pdf`, `cdf`, `icdf`, `random`, `negloglik`, `paramci`, `mle`, `ecdf`, `kstest`, `lillietest`, `adtest`, `chi2gof`, and all common distribution names. This card covers only clinical-specific patterns.

## Distribution Selection for Clinical Data

```
What kind of clinical measurement?
├── Lab values (normally distributed, e.g., cholesterol)
│   └── fitdist(data, 'Normal')
├── Positive-only, right-skewed (e.g., concentrations, costs, LOS)
│   ├── Moderate skew → fitdist(data, 'Gamma')
│   └── Heavy skew → fitdist(data, 'Lognormal')
├── Time-to-event (survival, device lifetime)
│   ├── Decreasing hazard → Weibull with shape < 1
│   ├── Constant hazard → Exponential
│   └── Increasing hazard → Weibull with shape > 1
├── Proportions (e.g., percentage adherence)
│   └── fitdist(data, 'Beta')
├── Count data (number of events per period)
│   ├── Mean ≈ Variance → Poisson
│   └── Variance > Mean (overdispersed) → Negative Binomial
└── Unknown / complex
    └── fitdist(data, 'Kernel') — nonparametric
```

## Comparing Distribution Fits for Clinical Data

The most common task: fitting multiple candidate distributions and selecting the best one.

```matlab
function results = fitClinicalDistributions(data, dataName)
    % Fit common distributions for clinical measurements
    distributions = {'Normal', 'Lognormal', 'Weibull', 'Gamma', ...
                     'Exponential', 'Logistic'};
    n = length(data);

    fprintf('=== Distribution Fitting: %s (n=%d) ===\n', dataName, n);
    fprintf('%-15s %10s %10s %10s\n', 'Distribution', 'NLL', 'AIC', 'BIC');

    best_aic = Inf;
    best_name = '';

    for i = 1:length(distributions)
        try
            pd = fitdist(data, distributions{i});
            nll = negloglik(pd);
            k = numel(pd.ParameterNames);
            aic = 2*k + 2*nll;
            bic = k*log(n) + 2*nll;

            fprintf('%-15s %10.2f %10.2f %10.2f\n', distributions{i}, nll, aic, bic);

            if aic < best_aic
                best_aic = aic;
                best_name = distributions{i};
            end
        catch
            % Distribution doesn't fit (e.g., negative data for Lognormal)
        end
    end
    fprintf('Best fit: %s\n', best_name);
end
```

## Censored Distribution Fitting (Survival Data)

```matlab
% Weibull fit with right-censored data
pdWeib = fitdist(survivalTime, 'Weibull', 'Censoring', censored);
fprintf('Shape: %.2f (>1 = increasing hazard, <1 = decreasing)\n', pdWeib.b);
fprintf('Scale: %.2f (characteristic life)\n', pdWeib.a);

% Compare parametric survival models via AIC
dists = {'Weibull', 'Exponential', 'Lognormal', 'Loglogistic'};
for i = 1:length(dists)
    pd = fitdist(survivalTime, dists{i}, 'Censoring', censored);
    nll = negloglik(pd);
    k = numel(pd.ParameterNames);
    fprintf('%s: AIC = %.2f\n', dists{i}, 2*k + 2*nll);
end
```

## Reference Interval Estimation

A key clinical application: determining normal reference ranges from healthy population data.

```matlab
% Non-parametric reference interval (2.5th to 97.5th percentile)
lower = prctile(healthyData, 2.5);
upper = prctile(healthyData, 97.5);
fprintf('Reference interval: [%.2f, %.2f]\n', lower, upper);

% Parametric (assuming normality)
pd = fitdist(healthyData, 'Normal');
ci = paramci(pd);  % 95% CI for parameters
lower_param = icdf(pd, 0.025);
upper_param = icdf(pd, 0.975);

% Flag abnormal patient values
abnormal = patientValues < lower | patientValues > upper;
fprintf('%d/%d patients outside reference range\n', sum(abnormal), length(patientValues));
```

## Mixture Models for Bimodal Clinical Data

```matlab
% Example: bimodal distribution (e.g., responders vs non-responders)
GMModel = fitgmdist(data, 2, ...
    'RegularizationValue', 0.01, ...
    'Replicates', 10);

% Classify patients into subgroups
[idx, ~, P] = cluster(GMModel, data);
fprintf('Group 1: mean=%.2f (n=%d)\n', GMModel.mu(1), sum(idx==1));
fprintf('Group 2: mean=%.2f (n=%d)\n', GMModel.mu(2), sum(idx==2));
```

---

*See also: scripts/template_distribution_fitting.m, survival-analysis.md for censored data*
