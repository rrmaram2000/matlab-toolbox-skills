%% Template: Cox Proportional Hazards and Kaplan-Meier Survival Analysis
% Perform survival analysis on clinical trial or patient follow-up data.
% Uses coxphfit for Cox regression (logrank does NOT exist in MATLAB),
% ecdf for Kaplan-Meier curves, and hazard ratio estimation.
% MATLAB R2025b | Statistics and Machine Learning Toolbox
%
% Usage:
%   1. Fill in all TODO sections with your data
%   2. Run section-by-section or as complete script
%
% Requirements:
%   - Statistics and Machine Learning Toolbox

%% TODO: Configure your data and parameters
dataPath = '';          % TODO: Path to your dataset (CSV, MAT, etc.)
timeVar = '';           % TODO: Name of survival/follow-up time variable
eventVar = '';          % TODO: Name of event indicator variable (1=event, 0=censored)
groupVar = '';          % TODO: Name of group/treatment variable
covariateVars = {};     % TODO: Cell array of covariate names (e.g., {'Age', 'Stage'})
alpha = 0.05;          % TODO: Significance level for confidence intervals

%% Step 1: Load and prepare survival data
data = readtable(dataPath);

T = data.(timeVar);          % Survival times
E = data.(eventVar);         % Event indicator (1 = event, 0 = censored)
G = data.(groupVar);         % Group labels

fprintf('Total patients: %d\n', height(data));
fprintf('Events observed: %d (%.1f%%)\n', sum(E), 100 * mean(E));
fprintf('Censored: %d (%.1f%%)\n', sum(~E), 100 * mean(~E));

%% Step 2: Kaplan-Meier survival curves by group
groups = unique(G);
nGroups = numel(groups);

figure('Name', 'Kaplan-Meier Curves', 'Position', [100 100 600 450]);
hold on;
colors = lines(nGroups);
legendLabels = cell(1, nGroups);

for g = 1:nGroups
    mask = (G == groups(g)) | strcmp(string(G), string(groups(g)));
    censoring = ~E(mask);  % ecdf uses 1 = censored

    [f, x] = ecdf(T(mask), 'Censoring', censoring, 'Function', 'survivor');
    stairs(x, f, 'Color', colors(g, :), 'LineWidth', 2);
    legendLabels{g} = sprintf('Group %s (n=%d)', string(groups(g)), sum(mask));
end

hold off;
xlabel('Time');
ylabel('Survival Probability');
title('Kaplan-Meier Survival Curves');
legend(legendLabels, 'Location', 'southwest');
grid on;
ylim([0 1]);

%% Step 3: Median survival time per group
fprintf('\n--- Median Survival Time ---\n');
for g = 1:nGroups
    mask = (G == groups(g)) | strcmp(string(G), string(groups(g)));
    censoring = ~E(mask);
    [f, x] = ecdf(T(mask), 'Censoring', censoring, 'Function', 'survivor');

    medIdx = find(f <= 0.5, 1, 'first');
    if ~isempty(medIdx)
        fprintf('Group %s: %.1f\n', string(groups(g)), x(medIdx));
    else
        fprintf('Group %s: Not reached\n', string(groups(g)));
    end
end

%% Step 4: Cox proportional hazards regression (single group covariate)
% NOTE: logrank() does NOT exist in MATLAB. Use coxphfit for group comparison.
groupNumeric = double(categorical(G));  % Convert group to numeric

[b, logl, H, stats] = coxphfit(groupNumeric, T, 'Censoring', ~E);

hr = exp(b);
hrCI = exp([b - norminv(1 - alpha/2) * stats.se, ...
            b + norminv(1 - alpha/2) * stats.se]);

fprintf('\n--- Cox Regression (Group Effect) ---\n');
fprintf('Beta coefficient: %.4f (SE: %.4f)\n', b, stats.se);
fprintf('Hazard Ratio: %.3f (%.0f%% CI: %.3f - %.3f)\n', ...
    hr, (1 - alpha) * 100, hrCI(1), hrCI(2));
fprintf('p-value: %.4f\n', stats.p);

if stats.p < alpha
    fprintf('Result: Significant difference between groups (p < %.2f)\n', alpha);
else
    fprintf('Result: No significant difference between groups (p >= %.2f)\n', alpha);
end

%% Step 5: Multivariate Cox regression with covariates
if ~isempty(covariateVars)
    XCov = zeros(height(data), numel(covariateVars) + 1);
    XCov(:, 1) = groupNumeric;

    for c = 1:numel(covariateVars)
        XCov(:, c + 1) = data.(covariateVars{c});
    end

    [bMV, loglMV, HMV, statsMV] = coxphfit(XCov, T, 'Censoring', ~E);

    varNames = [{'Group'}, covariateVars];
    fprintf('\n--- Multivariate Cox Regression ---\n');
    fprintf('%-15s  Beta      SE       HR       p-value\n', 'Variable');
    for v = 1:numel(varNames)
        hrMV = exp(bMV(v));
        fprintf('%-15s  %7.4f   %6.4f   %6.3f   %.4f\n', ...
            varNames{v}, bMV(v), statsMV.se(v), hrMV, statsMV.p(v));
    end
end

%% Step 6: Cumulative hazard function
figure('Name', 'Cumulative Hazard', 'Position', [750 100 550 400]);
hold on;
for g = 1:nGroups
    mask = (G == groups(g)) | strcmp(string(G), string(groups(g)));
    censoring = ~E(mask);
    [f, x] = ecdf(T(mask), 'Censoring', censoring, 'Function', 'cumulative hazard');
    stairs(x, f, 'Color', colors(g, :), 'LineWidth', 2);
end
hold off;
xlabel('Time');
ylabel('Cumulative Hazard');
title('Nelson-Aalen Cumulative Hazard Estimates');
legend(legendLabels, 'Location', 'northwest');
grid on;

%% Step 7: Summary
fprintf('\n--- Analysis Summary ---\n');
fprintf('Patients: %d | Events: %d | Censored: %d\n', ...
    height(data), sum(E), sum(~E));
fprintf('Groups compared: %d\n', nGroups);
fprintf('Cox p-value: %.4f | Hazard Ratio: %.3f\n', stats.p, hr);
