%% Clinical Trial Survival Analysis Pipeline
% Survival analysis for a clinical trial comparing Drug A vs Drug B.
% Includes missing data handling, KNN imputation, log-rank test,
% and parametric model comparison.
%
% MATLAB R2025b | Statistics and Machine Learning Toolbox

%% Step 1: Load data
dataFile = '';  % Path to clinical trial data
T = readtable(dataFile);

fprintf("Patients: %d | Events: %d\n", height(T), sum(T.Event));

%% Step 2: Handle missing values with knnimpute
% Use KNN imputation for missing clinical variables
numericData = [T.Age, T.Biomarker];

% Impute missing values using KNN
numericData = knnimpute(numericData', 5)';  % k=5 nearest neighbors

T.Age = numericData(:, 1);
T.Biomarker = numericData(:, 2);

fprintf("Missing values imputed with knnimpute (k=5)\n");

%% Step 3: Kaplan-Meier curves
idxA = T.Treatment == 0;
idxB = T.Treatment == 1;

[fA, xA] = ecdf(T.Time(idxA), ...
    'Censoring', ~logical(T.Event(idxA)), ...
    'Function', 'survivor');
[fB, xB] = ecdf(T.Time(idxB), ...
    'Censoring', ~logical(T.Event(idxB)), ...
    'Function', 'survivor');

figure;
stairs(xA, fA, 'b-', 'LineWidth', 2); hold on;
stairs(xB, fB, 'r-', 'LineWidth', 2); hold off;
xlabel("Time (months)");
ylabel("Survival Probability");
legend("Drug A", "Drug B");
title("Kaplan-Meier Survival Curves");
grid on;

%% Step 4: Log-rank test for group comparison
% Compare survival distributions between Drug A and Drug B
[h, p, stats] = logrank(T.Time(idxA), T.Event(idxA), ...
                         T.Time(idxB), T.Event(idxB));

fprintf("\nLog-Rank Test:\n");
fprintf("  Test statistic: %.3f\n", stats.teststat);
fprintf("  p-value: %.4f\n", p);
if h
    fprintf("  Result: Significant difference (p < 0.05)\n");
else
    fprintf("  Result: No significant difference\n");
end

%% Step 5: Cox proportional hazards model
X = [T.Treatment, T.Age, double(T.Stage), T.Biomarker];
[b, logl, H, stats] = coxphfit(X, T.Time, ...
    'Censoring', ~logical(T.Event));

fprintf("\n--- Cox Model Results ---\n");
varNames = {"Treatment", "Age", "Stage", "Biomarker"};
for i = 1:length(b)
    HR = exp(b(i));
    fprintf("  %s: HR = %.3f, p = %.4f\n", varNames{i}, HR, stats.p(i));
end

%% Step 6: Parametric model comparison
% Fit different distributions and compare using NegLogLikelihood property
distributions = {"Weibull", "Exponential", "Lognormal"};
censoring = ~logical(T.Event);

fprintf("\n--- Model Comparison ---\n");
for i = 1:numel(distributions)
    pd = fitdist(T.Time, distributions{i}, 'Censoring', censoring);

    % Get negative log-likelihood from the distribution object property
    nll = pd.NegLogLikelihood;
    nParams = numel(pd.ParameterNames);
    aic = 2 * nll + 2 * nParams;

    fprintf("  %s: NLL = %.2f, AIC = %.2f\n", distributions{i}, nll, aic);
end

%% Step 7: Save results
fprintf("\n=== Analysis Complete ===\n");
