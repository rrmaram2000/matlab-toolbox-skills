%% Clinical Trial Survival Analysis Pipeline
% Complete survival analysis for a clinical trial comparing Drug A vs
% Drug B, with proper missing data handling, group comparison, and
% parametric model fitting.
%
% MATLAB R2025b | Statistics and Machine Learning Toolbox
%
% Workflow:
%   1. Load and clean clinical trial data
%   2. Handle missing values with fillmissing (KNN imputation)
%   3. Kaplan-Meier survival curves with confidence intervals
%   4. Group comparison via coxphfit (NOT logrank — doesn't exist)
%   5. Multivariate Cox proportional hazards model
%   6. Parametric model comparison using negloglik function
%   7. Risk stratification and prediction

%% ---- USER CONFIGURATION ----
dataFile = '';  % TODO: Path to clinical trial CSV/MAT file
outputDir = ''; % TODO: Path to save results

%% Step 1: Load clinical trial data
% Expected columns: PatientID, Time, Event, Treatment, Age, Stage, Biomarker
T = readtable(dataFile);

fprintf('Clinical Trial Data Summary:\n');
fprintf('  Total patients: %d\n', height(T));
fprintf('  Events observed: %d (%.1f%%)\n', sum(T.Event), 100*mean(T.Event));
fprintf('  Treatment groups: Drug A = %d, Drug B = %d\n', ...
    sum(T.Treatment == 0), sum(T.Treatment == 1));

%% Step 2: Handle missing values with KNN imputation
% CRITICAL: knnimpute() does NOT exist in base MATLAB / Stats Toolbox
% It requires the Bioinformatics Toolbox. Use fillmissing instead.
%
% fillmissing(X, 'knn') performs KNN-based imputation natively
% in the Statistics and Machine Learning Toolbox.

missingBefore = sum(ismissing(T), 'all');
fprintf('\nMissing values before imputation: %d\n', missingBefore);

% Impute missing numeric values using KNN
numericVars = {'Age', 'Biomarker'};
for v = 1:numel(numericVars)
    varName = numericVars{v};
    if any(ismissing(T.(varName)))
        T.(varName) = fillmissing(T.(varName), 'knn');
        fprintf('  Imputed %s using KNN\n', varName);
    end
end

% For categorical/ordinal: use mode imputation
if any(ismissing(T.Stage))
    T.Stage = fillmissing(T.Stage, 'constant', mode(T.Stage));
    fprintf('  Imputed Stage using mode\n');
end

missingAfter = sum(ismissing(T), 'all');
fprintf('Missing values after imputation: %d\n', missingAfter);

%% Step 3: Kaplan-Meier survival curves with confidence intervals
% Separate data by treatment group
idxA = T.Treatment == 0;
idxB = T.Treatment == 1;

% ecdf with 'survivor' function computes Kaplan-Meier estimator
[fA, xA, floA, fupA] = ecdf(T.Time(idxA), ...
    'Censoring', ~logical(T.Event(idxA)), ...
    'Function', 'survivor');
[fB, xB, floB, fupB] = ecdf(T.Time(idxB), ...
    'Censoring', ~logical(T.Event(idxB)), ...
    'Function', 'survivor');

% Plot Kaplan-Meier curves
figure('Name', 'Kaplan-Meier Survival Curves', 'Position', [100 100 900 600]);

% Drug A (blue)
stairs(xA, fA, 'b-', 'LineWidth', 2.5); hold on;
stairs(xA, floA, 'b--', 'LineWidth', 1);
stairs(xA, fupA, 'b--', 'LineWidth', 1);

% Drug B (red)
stairs(xB, fB, 'r-', 'LineWidth', 2.5);
stairs(xB, floB, 'r--', 'LineWidth', 1);
stairs(xB, fupB, 'r--', 'LineWidth', 1);

% Add censoring marks
cenA = T.Time(idxA & ~logical(T.Event));
for i = 1:numel(cenA)
    idx = find(xA <= cenA(i), 1, 'last');
    if ~isempty(idx)
        plot(xA(idx), fA(idx), 'b+', 'MarkerSize', 8, 'LineWidth', 1.5);
    end
end
cenB = T.Time(idxB & ~logical(T.Event));
for i = 1:numel(cenB)
    idx = find(xB <= cenB(i), 1, 'last');
    if ~isempty(idx)
        plot(xB(idx), fB(idx), 'r+', 'MarkerSize', 8, 'LineWidth', 1.5);
    end
end
hold off;

xlabel('Time (months)');
ylabel('Survival Probability');
title('Kaplan-Meier Survival Curves');
legend('Drug A', 'Drug A 95% CI', '', 'Drug B', 'Drug B 95% CI', '', ...
    'Location', 'best');
ylim([0 1]);
grid on;

% Median survival times
medA = xA(find(fA <= 0.5, 1));
medB = xB(find(fB <= 0.5, 1));
if ~isempty(medA), fprintf('\nMedian survival (Drug A): %.1f months\n', medA);
else, fprintf('\nMedian survival (Drug A): Not reached\n'); end
if ~isempty(medB), fprintf('Median survival (Drug B): %.1f months\n', medB);
else, fprintf('Median survival (Drug B): Not reached\n'); end

%% Step 4: Group comparison — Cox regression (log-rank equivalent)
% CRITICAL: The logrank() function does NOT exist in MATLAB.
% Use coxphfit with group indicator as the sole predictor.
% With a single binary covariate, the Wald test from coxphfit is
% equivalent to the log-rank test.

[b, logl, H, stats] = coxphfit(T.Treatment, T.Time, ...
    'Censoring', ~logical(T.Event));

HR = exp(b);
HR_CI = exp([b - 1.96*stats.se, b + 1.96*stats.se]);
pValue = stats.p;

fprintf('\n=== Log-Rank Test Equivalent (Cox Regression) ===\n');
fprintf('  Hazard Ratio (Drug B vs A): %.3f\n', HR);
fprintf('  95%% CI: [%.3f, %.3f]\n', HR_CI(1), HR_CI(2));
fprintf('  p-value: %.4f\n', pValue);

if pValue < 0.05
    fprintf('  Result: SIGNIFICANT difference between groups\n');
else
    fprintf('  Result: No significant difference\n');
end

% Clinical significance check
if HR > 1.5 || HR < 0.67
    fprintf('  Clinical significance: HR %.3f exceeds threshold (>1.5 or <0.67)\n', HR);
else
    fprintf('  Clinical significance: HR %.3f is modest\n', HR);
end

%% Step 5: Multivariate Cox proportional hazards model
% Adjust for covariates: Age, Stage, Biomarker
X = [T.Treatment, T.Age, double(T.Stage), T.Biomarker];
varNames = {'Treatment', 'Age', 'Stage', 'Biomarker'};

[b_multi, logl_multi, H_multi, stats_multi] = coxphfit(X, T.Time, ...
    'Censoring', ~logical(T.Event));

fprintf('\n=== Multivariate Cox Model ===\n');
fprintf('%-12s %8s %8s %14s %8s\n', 'Variable', 'Beta', 'HR', '95% CI', 'p-value');
fprintf('%s\n', repmat('-', 1, 58));

for i = 1:length(b_multi)
    HR_i = exp(b_multi(i));
    CI_lo = exp(b_multi(i) - 1.96*stats_multi.se(i));
    CI_hi = exp(b_multi(i) + 1.96*stats_multi.se(i));
    fprintf('%-12s %8.3f %8.3f  [%.2f, %.2f]  %8.4f\n', ...
        varNames{i}, b_multi(i), HR_i, CI_lo, CI_hi, stats_multi.p(i));
end

% Proportional hazards check (visual)
% Log-log plot: if curves are parallel, PH assumption holds
figure('Name', 'Proportional Hazards Check');
loglogS_A = log(-log(max(fA(2:end), 1e-10)));
loglogS_B = log(-log(max(fB(2:end), 1e-10)));
plot(log(xA(2:end)), loglogS_A, 'b-', 'LineWidth', 2); hold on;
plot(log(xB(2:end)), loglogS_B, 'r-', 'LineWidth', 2); hold off;
xlabel('log(Time)');
ylabel('log(-log(S(t)))');
title('Log-Log Plot for PH Assumption Check');
legend('Drug A', 'Drug B', 'Location', 'best');
grid on;
fprintf('\nPH check: If log-log curves are parallel, assumption holds.\n');

%% Step 6: Parametric model comparison
% Compare Weibull, Exponential, Lognormal, Loglogistic
% CRITICAL: Use negloglik(pd) FUNCTION, NOT pd.NegLogLikelihood PROPERTY
% The .NegLogLikelihood property does NOT exist on distribution objects.

distributions = {'Weibull', 'Exponential', 'Lognormal', 'Loglogistic'};
censoring = ~logical(T.Event);

fprintf('\n=== Parametric Model Comparison ===\n');
fprintf('%-14s %10s %8s %8s\n', 'Distribution', 'NegLogLik', 'Params', 'AIC');
fprintf('%s\n', repmat('-', 1, 45));

bestAIC = Inf;
bestDist = '';

for i = 1:numel(distributions)
    try
        pd = fitdist(T.Time, distributions{i}, 'Censoring', censoring);

        % CORRECT: Use negloglik() function
        nll = negloglik(pd);
        nParams = numel(pd.ParameterNames);
        aic = 2 * nll + 2 * nParams;

        fprintf('%-14s %10.2f %8d %8.2f\n', distributions{i}, nll, nParams, aic);

        if aic < bestAIC
            bestAIC = aic;
            bestDist = distributions{i};
        end
    catch ME
        fprintf('%-14s %10s %8s %8s  (%s)\n', distributions{i}, 'FAIL', '-', '-', ME.message);
    end
end

fprintf('\nBest fit: %s (AIC = %.2f)\n', bestDist, bestAIC);

%% Step 7: Number-at-risk table
% Clinical standard: report number at risk at key timepoints
timePoints = [0, 6, 12, 18, 24, 30, 36];

fprintf('\n=== Number at Risk ===\n');
fprintf('%-8s', 'Time');
for t = timePoints
    fprintf('%6d', t);
end
fprintf('\n');

for grp = [0, 1]
    idx = T.Treatment == grp;
    grpTime = T.Time(idx);
    grpEvent = T.Event(idx);
    grpLabel = sprintf('Drug %s', char('A' + grp));

    fprintf('%-8s', grpLabel);
    for t = timePoints
        nAtRisk = sum(grpTime >= t);
        fprintf('%6d', nAtRisk);
    end
    fprintf('\n');
end

%% Step 8: Save results
if ~isempty(outputDir)
    if ~isfolder(outputDir), mkdir(outputDir); end
    saveas(figure(1), fullfile(outputDir, 'kaplan_meier.png'));
    saveas(figure(2), fullfile(outputDir, 'ph_check.png'));
    fprintf('\nResults saved to: %s\n', outputDir);
end

fprintf('\n=== Clinical Trial Survival Analysis Complete ===\n');
