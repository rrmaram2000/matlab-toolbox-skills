# Survival Analysis

Survival analysis deals with time-to-event data where some observations may be censored (event not yet observed). Common applications include patient survival, time to device failure, and customer churn.

## Key Concepts

### Survival Function
The survival function S(t) gives the probability of surviving beyond time t:
```
S(t) = P(T > t) = 1 - F(t)
```
where F(t) is the cumulative distribution function.

### Hazard Function
The hazard (instantaneous risk) at time t:
```
h(t) = lim[Δt→0] P(t ≤ T < t+Δt | T ≥ t) / Δt
```

### Censoring Types
- **Right censoring**: Subject leaves study before event (most common)
- **Left censoring**: Event occurred before observation started
- **Interval censoring**: Event occurred between two observations

## Kaplan-Meier Estimator

Non-parametric estimation of survival function. Best for visualization and exploratory analysis.

### Basic Kaplan-Meier Curve

```matlab
% Example: Time to relapse in clinical trial
time = [3, 5, 7, 8, 10, 12, 15, 16, 20, 22];       % Months
censored = [0, 0, 1, 0, 1, 0, 1, 0, 0, 1];         % 0=event, 1=censored

% Compute survival curve with confidence intervals
[f, x, flo, fup] = ecdf(time, 'Censoring', censored, ...
    'Function', 'survivor');

% Plot Kaplan-Meier curve
figure;
stairs(x, f, 'b-', 'LineWidth', 2);
hold on;
stairs(x, flo, 'b--', 'LineWidth', 1);
stairs(x, fup, 'b--', 'LineWidth', 1);

% Add censoring marks
censIdx = find(censored);
for i = 1:length(censIdx)
    idx = find(x == time(censIdx(i)), 1);
    if ~isempty(idx)
        plot(x(idx), f(idx), 'b+', 'MarkerSize', 10, 'LineWidth', 2);
    end
end

xlabel('Time (months)');
ylabel('Survival Probability');
title('Kaplan-Meier Survival Curve');
legend('Survival', '95% CI', '', 'Censored', 'Location', 'best');
ylim([0 1]);
grid on;
```

### Median Survival Time

```matlab
% Find median survival (time when S(t) = 0.5)
[f, x] = ecdf(time, 'Censoring', censored, 'Function', 'survivor');

idx = find(f <= 0.5, 1);
if ~isempty(idx)
    medianSurvival = x(idx);
    fprintf('Median survival: %.1f months\n', medianSurvival);
else
    fprintf('Median survival not reached\n');
end

% Quartile survival times
idx25 = find(f <= 0.75, 1);  % 25th percentile
idx75 = find(f <= 0.25, 1);  % 75th percentile

if ~isempty(idx25)
    fprintf('25%% survival: %.1f months\n', x(idx25));
end
if ~isempty(idx75)
    fprintf('75%% survival: %.1f months\n', x(idx75));
end
```

### At-Risk Table

```matlab
function atRiskTable = computeAtRiskTable(time, censored, timepoints)
    % Compute number at risk at specified time points
    n = length(time);
    atRiskTable = zeros(length(timepoints), 3);  % [timepoint, atRisk, events]

    for i = 1:length(timepoints)
        t = timepoints(i);
        atRisk = sum(time >= t);
        events = sum(time <= t & censored == 0);
        atRiskTable(i, :) = [t, atRisk, events];
    end

    % Display as table
    T = array2table(atRiskTable, 'VariableNames', {'Time', 'AtRisk', 'Events'});
    disp(T);
end

% Usage
timepoints = [0, 6, 12, 18, 24];
computeAtRiskTable(time, censored, timepoints);
```

## Comparing Groups

> ⚠️ **Important:** The `logrank` function does NOT exist in MATLAB. Use `coxphfit` for group comparisons.

### Log-Rank Test via Cox Regression

```matlab
% Compare survival between two groups (e.g., treatment vs control)
time1 = [3, 5, 7, 10, 12, 15, 20];       % Treatment group
cens1 = [0, 0, 1, 0, 1, 0, 1];
time2 = [2, 4, 6, 8, 9, 11, 14];         % Control group
cens2 = [0, 0, 0, 0, 1, 0, 0];

% Combine data with group indicator
allTime = [time1(:); time2(:)];
allCens = [cens1(:); cens2(:)];
group = [zeros(length(time1), 1); ones(length(time2), 1)];

% Cox regression with group as single predictor = log-rank test
[b, logl, H, stats] = coxphfit(group, allTime, 'Censoring', allCens);

% Report results
HR = exp(b);
HR_CI = exp([b - 1.96*stats.se, b + 1.96*stats.se]);
p_value = stats.p;

fprintf('Log-rank test equivalent (Cox regression):\n');
fprintf('  Hazard Ratio: %.3f (95%% CI: %.3f - %.3f)\n', HR, HR_CI(1), HR_CI(2));
fprintf('  p-value: %.4f\n', p_value);

if p_value < 0.05
    fprintf('  Conclusion: Significant difference between groups (p < 0.05)\n');
else
    fprintf('  Conclusion: No significant difference between groups\n');
end
```

### Stratified Comparison

```matlab
% Compare with stratification variable
% Example: Compare treatment effect stratified by disease stage

% Combine data
allTime = [time1(:); time2(:)];
allCens = [cens1(:); cens2(:)];
treatment = [zeros(length(time1), 1); ones(length(time2), 1)];
stage = [1, 1, 2, 2, 3, 3, 3, 1, 1, 2, 2, 3, 3, 3]';  % Stratification variable

% Cox model with stratification
% Note: coxphfit doesn't directly support strata, use baseline approach
[b, logl, H, stats] = coxphfit([treatment, stage], allTime, 'Censoring', allCens);

fprintf('\nMultivariate Cox model:\n');
fprintf('  Treatment HR: %.3f (p=%.4f)\n', exp(b(1)), stats.p(1));
fprintf('  Stage HR: %.3f (p=%.4f)\n', exp(b(2)), stats.p(2));
```

### Plot Grouped Survival Curves

```matlab
function plotGroupedKM(time1, cens1, label1, time2, cens2, label2)
    % Plot survival curves for two groups
    [f1, x1] = ecdf(time1, 'Censoring', cens1, 'Function', 'survivor');
    [f2, x2] = ecdf(time2, 'Censoring', cens2, 'Function', 'survivor');

    figure;
    stairs(x1, f1, 'b-', 'LineWidth', 2);
    hold on;
    stairs(x2, f2, 'r-', 'LineWidth', 2);

    % Add censoring marks
    addCensorMarks(time1, cens1, x1, f1, 'b');
    addCensorMarks(time2, cens2, x2, f2, 'r');

    xlabel('Time');
    ylabel('Survival Probability');
    legend(label1, label2, 'Location', 'best');
    title('Kaplan-Meier Survival Comparison');
    ylim([0 1]);
    grid on;
end

function addCensorMarks(time, cens, x, f, color)
    censIdx = find(cens);
    for i = 1:length(censIdx)
        idx = find(x == time(censIdx(i)), 1);
        if ~isempty(idx)
            plot(x(idx), f(idx), [color '+'], 'MarkerSize', 8, 'LineWidth', 2);
        end
    end
end

% Usage
plotGroupedKM(time1, cens1, 'Treatment', time2, cens2, 'Control');
```

## Cox Proportional Hazards Model

The Cox model relates hazard to covariates without assuming a specific baseline hazard:
```
h(t|X) = h₀(t) × exp(β₁X₁ + β₂X₂ + ... + βₚXₚ)
```

### Basic Cox Regression

```matlab
% Multivariate Cox model
% Example: Predicting survival from clinical variables
X = [age, gender, stage, biomarker];  % Covariate matrix
time = survivalTime;                   % Time to event
censored = censorIndicator;            % 1 = censored

% Fit Cox model
[b, logl, H, stats] = coxphfit(X, time, 'Censoring', censored);

% Display results
varNames = {'Age', 'Gender', 'Stage', 'Biomarker'};
fprintf('\nCox Proportional Hazards Model Results:\n');
fprintf('%-12s %8s %8s %12s %8s\n', 'Variable', 'Beta', 'HR', '95% CI', 'p-value');
fprintf('%s\n', repmat('-', 1, 60));

for i = 1:length(b)
    HR = exp(b(i));
    CI_lo = exp(b(i) - 1.96*stats.se(i));
    CI_hi = exp(b(i) + 1.96*stats.se(i));
    fprintf('%-12s %8.3f %8.3f %6.2f-%-5.2f %8.4f\n', ...
        varNames{i}, b(i), HR, CI_lo, CI_hi, stats.p(i));
end

fprintf('\nModel log-likelihood: %.2f\n', logl);
```

### Interpreting Hazard Ratios

```matlab
% Hazard ratio interpretation
HR = exp(b);

fprintf('\n=== Hazard Ratio Interpretation ===\n');
for i = 1:length(HR)
    if HR(i) > 1
        riskIncrease = (HR(i) - 1) * 100;
        fprintf('%s: %.1f%% increased risk per unit increase\n', ...
            varNames{i}, riskIncrease);
    elseif HR(i) < 1
        riskDecrease = (1 - HR(i)) * 100;
        fprintf('%s: %.1f%% decreased risk per unit increase\n', ...
            varNames{i}, riskDecrease);
    else
        fprintf('%s: No effect\n', varNames{i});
    end
end

% For categorical variables (e.g., gender: 0=female, 1=male)
% HR = 1.5 means males have 50% higher hazard than females
```

### Check Proportional Hazards Assumption

```matlab
function checkPHAssumption(X, time, censored, varNames)
    % Check proportional hazards assumption using Schoenfeld residuals
    % Note: MATLAB doesn't have built-in Schoenfeld residuals
    % Use log-log survival plot method

    figure;
    nVars = size(X, 2);

    for i = 1:min(nVars, 4)  % Plot first 4 variables
        subplot(2, 2, i);

        % Dichotomize continuous variable at median
        if length(unique(X(:,i))) > 2
            threshold = median(X(:,i));
            groups = X(:,i) >= threshold;
        else
            groups = X(:,i);
        end

        % Compute survival for each group
        idx0 = groups == 0;
        idx1 = groups == 1;

        [f0, x0] = ecdf(time(idx0), 'Censoring', censored(idx0), 'Function', 'survivor');
        [f1, x1] = ecdf(time(idx1), 'Censoring', censored(idx1), 'Function', 'survivor');

        % Log-log plot: log(-log(S(t))) vs log(t)
        % Parallel lines indicate PH assumption holds
        valid0 = f0 > 0 & f0 < 1;
        valid1 = f1 > 0 & f1 < 1;

        plot(log(x0(valid0)), log(-log(f0(valid0))), 'b.-');
        hold on;
        plot(log(x1(valid1)), log(-log(f1(valid1))), 'r.-');

        xlabel('log(time)');
        ylabel('log(-log(S(t)))');
        title(varNames{i});
        legend('Low', 'High', 'Location', 'best');

        % Parallel lines = PH assumption satisfied
    end
    sgtitle('Proportional Hazards Check (Parallel = OK)');
end

% Usage
checkPHAssumption(X, time, censored, varNames);
```

### Baseline Survival and Cumulative Hazard

```matlab
% Get baseline cumulative hazard from coxphfit
[b, logl, H, stats] = coxphfit(X, time, 'Censoring', censored);

% H contains cumulative baseline hazard at event times
% H(:,1) = event times, H(:,2) = cumulative hazard

figure;
subplot(1,2,1);
stairs(H(:,1), H(:,2), 'LineWidth', 2);
xlabel('Time');
ylabel('Cumulative Hazard H₀(t)');
title('Baseline Cumulative Hazard');
grid on;

subplot(1,2,2);
% Baseline survival: S₀(t) = exp(-H₀(t))
S0 = exp(-H(:,2));
stairs(H(:,1), S0, 'LineWidth', 2);
xlabel('Time');
ylabel('Survival Probability');
title('Baseline Survival S₀(t)');
ylim([0 1]);
grid on;
```

## Parametric Survival Models

When the distribution is known or assumed, parametric models provide more efficient estimates.

### Weibull Model

```matlab
% Fit Weibull distribution to survival data
pdWeib = fitdist(time, 'Weibull', 'Censoring', censored);

% Parameters
scale = pdWeib.a;  % Scale parameter (characteristic life)
shape = pdWeib.b;  % Shape parameter

fprintf('Weibull parameters:\n');
fprintf('  Scale (a): %.2f\n', scale);
fprintf('  Shape (b): %.2f\n', shape);

% Interpretation of shape parameter:
if shape < 1
    fprintf('  Interpretation: Decreasing hazard (early failures)\n');
elseif shape == 1
    fprintf('  Interpretation: Constant hazard (exponential)\n');
else
    fprintf('  Interpretation: Increasing hazard (wear-out)\n');
end

% Survival function at specific times
t_eval = [6, 12, 24, 36];
S_t = 1 - cdf(pdWeib, t_eval);
fprintf('\nSurvival probabilities:\n');
for i = 1:length(t_eval)
    fprintf('  S(%d) = %.3f\n', t_eval(i), S_t(i));
end
```

### Exponential Model

```matlab
% Exponential (constant hazard)
pdExp = fitdist(time, 'Exponential', 'Censoring', censored);

lambda = 1/pdExp.mu;  % Hazard rate
fprintf('Exponential model:\n');
fprintf('  Rate (λ): %.4f\n', lambda);
fprintf('  Mean survival: %.2f\n', pdExp.mu);
```

### Compare Distribution Fits

```matlab
function compareSurvivalDistributions(time, censored)
    % Fit multiple distributions and compare via AIC
    distributions = {'Weibull', 'Exponential', 'Lognormal', 'Loglogistic'};
    results = cell(length(distributions), 4);

    for i = 1:length(distributions)
        try
            pd = fitdist(time, distributions{i}, 'Censoring', censored);
            nll = negloglik(pd);
            nParams = numel(pd.ParameterNames);
            aic = 2*nll + 2*nParams;
            results{i, 1} = distributions{i};
            results{i, 2} = nll;
            results{i, 3} = nParams;
            results{i, 4} = aic;
        catch
            results{i, 1} = distributions{i};
            results{i, 2} = NaN;
            results{i, 3} = NaN;
            results{i, 4} = NaN;
        end
    end

    % Display comparison
    T = cell2table(results, 'VariableNames', ...
        {'Distribution', 'NegLogLik', 'NumParams', 'AIC'});
    disp(T);

    % Find best fit
    aicVals = cell2mat(results(:, 4));
    [~, bestIdx] = min(aicVals);
    fprintf('\nBest fit: %s (lowest AIC)\n', distributions{bestIdx});
end

% Usage
compareSurvivalDistributions(time, censored);
```

## Prediction and Prognosis

### Individual Survival Curves

```matlab
function [t_pred, S_pred] = predictSurvival(b, H, x_new)
    % Predict survival curve for new individual
    % b = Cox coefficients
    % H = baseline cumulative hazard [time, H0]
    % x_new = covariate vector for new individual

    risk_score = exp(x_new * b);
    t_pred = H(:, 1);
    H_pred = H(:, 2) * risk_score;  % Individual cumulative hazard
    S_pred = exp(-H_pred);          % Individual survival
end

% Example: Predict survival for a new patient
x_new = [65, 1, 2, 1.5];  % Age=65, Male, Stage=2, Biomarker=1.5
[t_pred, S_pred] = predictSurvival(b, H, x_new);

figure;
stairs(t_pred, S_pred, 'LineWidth', 2);
xlabel('Time');
ylabel('Predicted Survival Probability');
title('Individual Survival Prediction');
ylim([0 1]);
grid on;
```

### Risk Stratification

```matlab
% Stratify patients by risk score
risk_scores = X * b;

% Divide into risk groups
tertiles = quantile(risk_scores, [1/3, 2/3]);
risk_group = ones(length(risk_scores), 1);
risk_group(risk_scores > tertiles(1)) = 2;
risk_group(risk_scores > tertiles(2)) = 3;

% Plot survival by risk group
figure;
colors = {'b', 'g', 'r'};
labels = {'Low Risk', 'Medium Risk', 'High Risk'};

for g = 1:3
    idx = risk_group == g;
    [f, x] = ecdf(time(idx), 'Censoring', censored(idx), 'Function', 'survivor');
    stairs(x, f, colors{g}, 'LineWidth', 2);
    hold on;
end

xlabel('Time');
ylabel('Survival Probability');
legend(labels, 'Location', 'best');
title('Survival by Risk Tertile');
ylim([0 1]);
grid on;
```

## Model Validation

### Concordance Index (C-Index)

```matlab
function cIndex = concordanceIndex(time, censored, risk_score)
    % Compute Harrell's concordance index
    % Higher is better (0.5 = random, 1.0 = perfect)

    n = length(time);
    concordant = 0;
    discordant = 0;
    tied = 0;

    for i = 1:n
        for j = i+1:n
            % Only consider comparable pairs
            if censored(i) == 0 && censored(j) == 0
                % Both events observed
                if time(i) < time(j)
                    if risk_score(i) > risk_score(j)
                        concordant = concordant + 1;
                    elseif risk_score(i) < risk_score(j)
                        discordant = discordant + 1;
                    else
                        tied = tied + 1;
                    end
                elseif time(j) < time(i)
                    if risk_score(j) > risk_score(i)
                        concordant = concordant + 1;
                    elseif risk_score(j) < risk_score(i)
                        discordant = discordant + 1;
                    else
                        tied = tied + 1;
                    end
                end
            elseif censored(i) == 0 && time(i) < time(j)
                % i had event before j was censored
                if risk_score(i) > risk_score(j)
                    concordant = concordant + 1;
                elseif risk_score(i) < risk_score(j)
                    discordant = discordant + 1;
                else
                    tied = tied + 1;
                end
            elseif censored(j) == 0 && time(j) < time(i)
                % j had event before i was censored
                if risk_score(j) > risk_score(i)
                    concordant = concordant + 1;
                elseif risk_score(j) < risk_score(i)
                    discordant = discordant + 1;
                else
                    tied = tied + 1;
                end
            end
        end
    end

    cIndex = (concordant + 0.5*tied) / (concordant + discordant + tied);
end

% Usage
risk_scores = X * b;
cIndex = concordanceIndex(time, censored, risk_scores);
fprintf('Concordance Index: %.3f\n', cIndex);

% Interpretation:
% 0.5 = Random prediction
% 0.7-0.8 = Acceptable
% 0.8-0.9 = Good
% > 0.9 = Excellent
```

### Cross-Validated C-Index

```matlab
function cvCIndex = crossValidatedCIndex(X, time, censored, k)
    % K-fold cross-validated concordance index
    cv = cvpartition(length(time), 'KFold', k);
    cIndices = zeros(k, 1);

    for i = 1:k
        trainIdx = cv.training(i);
        testIdx = cv.test(i);

        % Fit on training
        [b, ~, ~, ~] = coxphfit(X(trainIdx,:), time(trainIdx), ...
            'Censoring', censored(trainIdx));

        % Predict on test
        risk_scores = X(testIdx,:) * b;

        % Compute C-index on test set
        cIndices(i) = concordanceIndex(time(testIdx), censored(testIdx), risk_scores);
    end

    cvCIndex = mean(cIndices);
    fprintf('Cross-validated C-Index: %.3f (±%.3f)\n', cvCIndex, std(cIndices));
end

% Usage
cvCIndex = crossValidatedCIndex(X, time, censored, 5);
```

## Biomedical Applications

### Clinical Trial Survival Analysis

```matlab
function clinicalTrialAnalysis(time, censored, treatment, covariates, varNames)
    % Complete clinical trial survival analysis

    fprintf('=== Clinical Trial Survival Analysis ===\n\n');

    % 1. Descriptive statistics
    fprintf('1. Study Population:\n');
    fprintf('   Total patients: %d\n', length(time));
    fprintf('   Events: %d (%.1f%%)\n', sum(~censored), 100*mean(~censored));
    fprintf('   Treatment: %d | Control: %d\n', sum(treatment==1), sum(treatment==0));

    % 2. Kaplan-Meier by treatment
    fprintf('\n2. Kaplan-Meier Analysis:\n');

    idx_trt = treatment == 1;
    idx_ctrl = treatment == 0;

    [f_trt, x_trt] = ecdf(time(idx_trt), 'Censoring', censored(idx_trt), 'Function', 'survivor');
    [f_ctrl, x_ctrl] = ecdf(time(idx_ctrl), 'Censoring', censored(idx_ctrl), 'Function', 'survivor');

    % Median survival
    med_trt = x_trt(find(f_trt <= 0.5, 1));
    med_ctrl = x_ctrl(find(f_ctrl <= 0.5, 1));

    if ~isempty(med_trt)
        fprintf('   Median survival (Treatment): %.1f months\n', med_trt);
    else
        fprintf('   Median survival (Treatment): Not reached\n');
    end
    if ~isempty(med_ctrl)
        fprintf('   Median survival (Control): %.1f months\n', med_ctrl);
    else
        fprintf('   Median survival (Control): Not reached\n');
    end

    % 3. Cox regression (treatment effect)
    fprintf('\n3. Unadjusted Treatment Effect:\n');
    [b, ~, ~, stats] = coxphfit(treatment, time, 'Censoring', censored);
    HR = exp(b);
    CI = exp([b - 1.96*stats.se, b + 1.96*stats.se]);
    fprintf('   HR = %.3f (95%% CI: %.3f-%.3f), p = %.4f\n', HR, CI(1), CI(2), stats.p);

    % 4. Adjusted Cox regression
    if ~isempty(covariates)
        fprintf('\n4. Adjusted Analysis (controlling for covariates):\n');
        X_full = [treatment, covariates];
        [b, ~, ~, stats] = coxphfit(X_full, time, 'Censoring', censored);

        allNames = ['Treatment', varNames];
        for i = 1:length(b)
            HR = exp(b(i));
            CI = exp([b(i) - 1.96*stats.se(i), b(i) + 1.96*stats.se(i)]);
            fprintf('   %s: HR = %.3f (%.3f-%.3f), p = %.4f\n', ...
                allNames{i}, HR, CI(1), CI(2), stats.p(i));
        end
    end
end
```

## Best Practices

1. **Always report:**
   - Number at risk at key timepoints
   - Confidence intervals for survival estimates
   - Hazard ratios with confidence intervals and p-values

2. **Check assumptions:**
   - Proportional hazards (for Cox model)
   - Distribution fit (for parametric models)
   - Informative censoring (should be minimal)

3. **Handle tied event times:**
   - MATLAB's `coxphfit` uses Breslow method by default
   - For many ties, consider exact methods

4. **Report effect sizes:**
   - HR > 1.5 or HR < 0.67 typically considered clinically meaningful
   - Statistical significance alone is not sufficient

5. **Validate models:**
   - Use cross-validation for C-index
   - Check calibration in external datasets
   - Report discrimination and calibration separately

## Common Pitfalls

| Pitfall | Solution |
|---------|----------|
| Using `logrank` function | Does NOT exist in MATLAB - use `coxphfit` instead |
| Ignoring censoring | Always specify 'Censoring' parameter |
| Violating PH assumption | Check log-log plots, consider time-varying covariates |
| Overfitting | Use cross-validation, penalized regression |
| Immortal time bias | Carefully define time origin |

---

*See also: regression.md for general regression methods, hypothesis-testing.md for statistical inference*
