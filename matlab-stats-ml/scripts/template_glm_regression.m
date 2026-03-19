%% Template: Generalized Linear Model for Clinical Outcome Prediction
% Fit GLMs for clinical outcomes using fitglm and stepwiseglm. Supports
% binomial (binary outcomes), Poisson (count data), and normal (continuous)
% distributions. Includes deviance analysis, residual diagnostics, and
% stepwise variable selection.
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
responseVar = '';       % TODO: Name of response/outcome variable
predictorVars = {};     % TODO: Cell array of predictor names (empty = use all)
glmDistribution = 'binomial';  % TODO: 'binomial', 'poisson', 'normal'
linkFunction = 'logit';        % TODO: 'logit', 'log', 'identity', 'probit'

%% Step 1: Load and prepare data
data = readtable(dataPath);

if isempty(predictorVars)
    predictorVars = setdiff(data.Properties.VariableNames, {responseVar});
end

fprintf('Response: %s (Distribution: %s, Link: %s)\n', ...
    responseVar, glmDistribution, linkFunction);
fprintf('Predictors: %d\n', numel(predictorVars));
fprintf('Observations: %d\n', height(data));

%% Step 2: Explore response variable
Y = data.(responseVar);
fprintf('\n--- Response Summary ---\n');

switch glmDistribution
    case 'binomial'
        fprintf('Binary outcome: %d events (%.1f%%), %d non-events\n', ...
            sum(Y == 1), 100 * mean(Y), sum(Y == 0));
    case 'poisson'
        fprintf('Count data: Mean=%.2f, Var=%.2f, Max=%d\n', ...
            mean(Y), var(Y), max(Y));
        fprintf('Overdispersion ratio (Var/Mean): %.2f\n', var(Y)/mean(Y));
    case 'normal'
        fprintf('Continuous: Mean=%.3f, SD=%.3f\n', mean(Y), std(Y));
end

%% Step 3: Fit full GLM
formula = sprintf('%s ~ %s', responseVar, strjoin(predictorVars, ' + '));

glmFull = fitglm(data, formula, ...
    'Distribution', glmDistribution, ...
    'Link', linkFunction);

fprintf('\n--- Full GLM Summary ---\n');
disp(glmFull);

%% Step 4: Extract coefficients and odds ratios
coeffTable = glmFull.Coefficients;
fprintf('\n--- Coefficient Table ---\n');
fprintf('%-25s  Estimate    SE        p-value', 'Predictor');

if strcmp(glmDistribution, 'binomial')
    fprintf('   Odds Ratio  OR 95%% CI\n');
else
    fprintf('\n');
end
fprintf('%s\n', repmat('-', 1, 85));

for i = 1:height(coeffTable)
    pName = coeffTable.Properties.RowNames{i};
    est = coeffTable.Estimate(i);
    se = coeffTable.SE(i);
    pVal = coeffTable.pValue(i);

    fprintf('%-25s  %+8.4f    %-8.4f  %.4f', pName, est, se, pVal);

    if strcmp(glmDistribution, 'binomial')
        orVal = exp(est);
        orCI = exp([est - 1.96*se, est + 1.96*se]);
        fprintf('   %7.3f    [%.3f, %.3f]', orVal, orCI(1), orCI(2));
    end

    if pVal < 0.05
        fprintf(' *');
    end
    fprintf('\n');
end

%% Step 5: Model deviance and goodness-of-fit
fprintf('\n--- Model Fit Statistics ---\n');
fprintf('Deviance:          %.3f\n', glmFull.Deviance);
fprintf('AIC:               %.3f\n', glmFull.ModelCriterion.AIC);
fprintf('BIC:               %.3f\n', glmFull.ModelCriterion.BIC);
fprintf('Log-likelihood:    %.3f\n', glmFull.LogLikelihood);
fprintf('DF residual:       %d\n', glmFull.DFE);

% Null model comparison
nullFormula = sprintf('%s ~ 1', responseVar);
glmNull = fitglm(data, nullFormula, ...
    'Distribution', glmDistribution, ...
    'Link', linkFunction);

devianceDiff = glmNull.Deviance - glmFull.Deviance;
dfDiff = glmNull.DFE - glmFull.DFE;
pDeviance = 1 - chi2cdf(devianceDiff, dfDiff);
fprintf('\nDeviance test vs null: chi2(%d)=%.3f, p=%.4f\n', ...
    dfDiff, devianceDiff, pDeviance);

%% Step 6: Stepwise model selection
fprintf('\n--- Stepwise GLM Selection ---\n');
glmStep = stepwiseglm(data, 'constant', ...
    'ResponseVar', responseVar, ...
    'PredictorVars', predictorVars, ...
    'Distribution', glmDistribution, ...
    'Link', linkFunction, ...
    'Upper', 'linear', ...
    'Verbose', 0);

fprintf('Selected predictors: %s\n', ...
    strjoin(glmStep.CoefficientNames(2:end), ', '));
fprintf('Stepwise AIC: %.3f (Full: %.3f)\n', ...
    glmStep.ModelCriterion.AIC, glmFull.ModelCriterion.AIC);
fprintf('Stepwise BIC: %.3f (Full: %.3f)\n', ...
    glmStep.ModelCriterion.BIC, glmFull.ModelCriterion.BIC);

%% Step 7: Residual diagnostics
figure('Name', 'GLM Diagnostics', 'Position', [100 100 900 700]);

% Deviance residuals vs fitted values
subplot(2, 2, 1);
residDev = glmFull.Residuals.Deviance;
fittedVals = glmFull.Fitted.Response;
scatter(fittedVals, residDev, 20, 'filled', 'MarkerFaceAlpha', 0.5);
yline(0, 'k--');
xlabel('Fitted Values');
ylabel('Deviance Residuals');
title('Residuals vs Fitted');
grid on;

% QQ plot of deviance residuals
subplot(2, 2, 2);
qqplot(residDev);
title('QQ Plot — Deviance Residuals');
grid on;

% Leverage (Hat values)
subplot(2, 2, 3);
leverage = glmFull.Diagnostics.HatMatrix;
stem(leverage, 'Marker', '.', 'MarkerSize', 8);
yline(2 * numel(glmFull.CoefficientNames) / height(data), 'r--', 'Threshold');
xlabel('Observation');
ylabel('Leverage');
title('Leverage Plot');
grid on;

% Cook's distance
subplot(2, 2, 4);
cooksD = glmFull.Diagnostics.CooksDistance;
stem(cooksD, 'Marker', '.', 'MarkerSize', 8);
yline(4 / height(data), 'r--', 'Threshold');
xlabel('Observation');
ylabel("Cook's Distance");
title("Cook's Distance — Influential Points");
grid on;

sgtitle('GLM Diagnostic Plots');

%% Step 8: Predictions on new data
% newData = table(...);  % TODO: New patient data as table
% [yPred, yCI] = predict(glmFull, newData);
% fprintf('Predicted: %.3f [%.3f, %.3f]\n', yPred, yCI(1), yCI(2));

%% Step 9: Model comparison table
fprintf('\n--- Model Comparison ---\n');
fprintf('%-20s  AIC        BIC        Deviance   Predictors\n', 'Model');
fprintf('%-20s  %-10.2f %-10.2f %-10.2f %d\n', 'Null', ...
    glmNull.ModelCriterion.AIC, glmNull.ModelCriterion.BIC, ...
    glmNull.Deviance, 0);
fprintf('%-20s  %-10.2f %-10.2f %-10.2f %d\n', 'Stepwise', ...
    glmStep.ModelCriterion.AIC, glmStep.ModelCriterion.BIC, ...
    glmStep.Deviance, glmStep.NumCoefficients - 1);
fprintf('%-20s  %-10.2f %-10.2f %-10.2f %d\n', 'Full', ...
    glmFull.ModelCriterion.AIC, glmFull.ModelCriterion.BIC, ...
    glmFull.Deviance, glmFull.NumCoefficients - 1);
