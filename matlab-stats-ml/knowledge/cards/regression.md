# Regression

Regression models predict continuous outcomes from predictor variables. This card covers linear, generalized linear, regularized, ensemble, and Gaussian process regression with focus on biomedical applications.

## Algorithm Selection Guide

```
What's your goal?
├── Simple linear relationship
│   ├── One predictor → fitlm (simple linear)
│   └── Multiple predictors → fitlm (multiple linear)
├── Non-normal response
│   ├── Binary outcome → fitglm (logistic)
│   ├── Count data → fitglm (Poisson)
│   └── Proportions → fitglm (binomial)
├── Need uncertainty quantification → fitrgp (Gaussian process)
├── Complex nonlinear → fitrnet (neural network) or fitrsvm (SVM)
├── Feature selection + prediction
│   ├── Sparse solution → lasso
│   ├── Correlated features → ridge or elasticnet
│   └── Stepwise → stepwiselm
├── Best accuracy → fitrensemble (boosting or bagging)
└── Robust to outliers → fitlm with 'RobustOpts' or fitrsvm
```

## Linear Regression: `fitlm`

### Basic Linear Regression

```matlab
% Simple linear regression (one predictor)
mdl = fitlm(X, y);
disp(mdl);

% Multiple linear regression
mdl = fitlm(X, y);

% From table with formula
tbl = table(age, weight, height, bloodPressure);
mdl = fitlm(tbl, 'bloodPressure ~ age + weight + height');

% With interactions
mdl = fitlm(tbl, 'bloodPressure ~ age + weight + age:weight');

% With polynomial terms
mdl = fitlm(tbl, 'bloodPressure ~ age + age^2');

% Full factorial (all interactions)
mdl = fitlm(tbl, 'bloodPressure ~ age * weight * height');
```

### Model Diagnostics

```matlab
mdl = fitlm(X, y);

% Key statistics
fprintf('R-squared: %.4f\n', mdl.Rsquared.Ordinary);
fprintf('Adjusted R-squared: %.4f\n', mdl.Rsquared.Adjusted);
fprintf('RMSE: %.4f\n', mdl.RMSE);
fprintf('F-statistic: %.2f (p = %.4e)\n', mdl.ModelFitVsNullModel.Fstat, ...
    mdl.ModelFitVsNullModel.Pvalue);

% Coefficient table
disp(mdl.Coefficients);

% Residual diagnostics
figure;
subplot(2,2,1);
plotResiduals(mdl, 'histogram');
title('Residual Distribution');

subplot(2,2,2);
plotResiduals(mdl, 'fitted');
title('Residuals vs Fitted');

subplot(2,2,3);
plotResiduals(mdl, 'probability');
title('Normal Q-Q Plot');

subplot(2,2,4);
plotDiagnostics(mdl, 'cookd');
title('Cook''s Distance');
```

### Robust Regression

```matlab
% When data contains outliers
mdl = fitlm(X, y, 'RobustOpts', 'on');

% Specific robust method
mdl = fitlm(X, y, 'RobustOpts', 'bisquare');  % Tukey's bisquare
mdl = fitlm(X, y, 'RobustOpts', 'huber');     % Huber
mdl = fitlm(X, y, 'RobustOpts', 'cauchy');    % Cauchy
```

## Stepwise Regression: `stepwiselm`

Automatic variable selection for model building.

```matlab
% Forward stepwise (start with constant)
mdl = stepwiselm(X, y, 'constant', ...
    'Upper', 'linear', ...          % Maximum model complexity
    'PEnter', 0.05, ...             % p-value to enter
    'PRemove', 0.10);               % p-value to remove

% Backward stepwise (start with full model)
mdl = stepwiselm(X, y, 'linear', ...
    'Upper', 'linear', ...
    'PEnter', 0.05, ...
    'PRemove', 0.10);

% Bidirectional with interactions
mdl = stepwiselm(tbl, 'y ~ 1', ...
    'Upper', 'y ~ x1*x2*x3', ...
    'Criterion', 'bic');            % BIC instead of p-values

% Show steps
mdl = stepwiselm(X, y, 'Verbose', 2);
```

## Regularized Regression

### LASSO (L1 Regularization)

```matlab
% Basic LASSO with cross-validation
[B, FitInfo] = lasso(X, y, 'CV', 10);

% Optimal lambda selection
idxLambda1SE = FitInfo.Index1SE;    % 1 SE rule (more parsimonious)
idxLambdaMin = FitInfo.IndexMinMSE; % Minimum MSE

% Selected coefficients
coef_1SE = B(:, idxLambda1SE);
selectedVars = find(coef_1SE ~= 0);
fprintf('Selected %d variables\n', length(selectedVars));

% Predict
yhat = X * coef_1SE + FitInfo.Intercept(idxLambda1SE);

% Visualize regularization path
figure;
lassoPlot(B, FitInfo, 'PlotType', 'Lambda', 'XScale', 'log');

figure;
lassoPlot(B, FitInfo, 'PlotType', 'CV');
```

### Ridge Regression (L2 Regularization)

```matlab
% Ridge regression
[B, FitInfo] = ridge(y, X, lambda, 0);  % 0 = don't scale

% With cross-validation
lambdas = logspace(-4, 4, 100);
[B, FitInfo] = lasso(X, y, 'Alpha', 0, 'Lambda', lambdas, 'CV', 10);
```

### Elastic Net (L1 + L2)

```matlab
% Alpha controls L1/L2 balance (0 = ridge, 1 = lasso)
alpha = 0.5;  % 50% L1, 50% L2
[B, FitInfo] = lasso(X, y, 'Alpha', alpha, 'CV', 10);

% Search for optimal alpha
alphas = 0.1:0.1:1;
mse = zeros(length(alphas), 1);
for i = 1:length(alphas)
    [~, FitInfo] = lasso(X, y, 'Alpha', alphas(i), 'CV', 10);
    mse(i) = min(FitInfo.MSE);
end
[~, bestIdx] = min(mse);
bestAlpha = alphas(bestIdx);
```

## Generalized Linear Models: `fitglm`

For non-normal response distributions.

### Logistic Regression (Binary Outcome)

```matlab
% Binary logistic regression
mdl = fitglm(X, y, 'Distribution', 'binomial', 'Link', 'logit');

% From table
mdl = fitglm(tbl, 'outcome ~ age + treatment + age:treatment', ...
    'Distribution', 'binomial');

% Odds ratios and confidence intervals
coef = mdl.Coefficients.Estimate;
se = mdl.Coefficients.SE;
OR = exp(coef);
CI_low = exp(coef - 1.96 * se);
CI_high = exp(coef + 1.96 * se);

% Display results
varNames = mdl.CoefficientNames';
T = table(varNames, coef, OR, CI_low, CI_high, mdl.Coefficients.pValue, ...
    'VariableNames', {'Variable', 'Coefficient', 'OddsRatio', 'CI_Lower', 'CI_Upper', 'pValue'});
disp(T);

% Predict probabilities
prob = predict(mdl, Xnew);
predicted_class = prob > 0.5;
```

### Poisson Regression (Count Data)

```matlab
% For count outcomes (e.g., number of events)
mdl = fitglm(X, counts, 'Distribution', 'poisson', 'Link', 'log');

% Rate ratios (incidence rate ratios)
IRR = exp(mdl.Coefficients.Estimate);
```

### Gamma Regression (Positive Continuous)

```matlab
% For positive continuous outcomes (e.g., survival time, costs)
mdl = fitglm(X, y, 'Distribution', 'gamma', 'Link', 'log');
```

## Gaussian Process Regression: `fitrgp`

Provides uncertainty quantification with predictions.

```matlab
% Basic GPR
gprMdl = fitrgp(X, y);

% With automatic kernel selection
gprMdl = fitrgp(X, y, ...
    'KernelFunction', 'ardsquaredexponential', ...  % ARD SE kernel
    'Standardize', true);

% Predict with confidence intervals
[ypred, ysd, yint] = predict(gprMdl, Xnew);
% ypred: point predictions
% ysd: standard deviation
% yint: 95% confidence intervals

% Visualize uncertainty
figure;
fill([Xnew; flipud(Xnew)], [yint(:,1); flipud(yint(:,2))], ...
    [0.9 0.9 0.9], 'EdgeColor', 'none');
hold on;
plot(Xnew, ypred, 'b-', 'LineWidth', 2);
scatter(X, y, 'ro', 'filled');
legend('95% CI', 'Prediction', 'Training Data');
```

### Kernel Functions

| Kernel | Function | Best For |
|--------|----------|----------|
| `'squaredexponential'` | SE | Smooth functions |
| `'ardsquaredexponential'` | ARD SE | Automatic relevance detection |
| `'matern32'` | Matérn 3/2 | Moderate smoothness |
| `'matern52'` | Matérn 5/2 | Smooth but allows for local variation |
| `'rationalquadratic'` | RQ | Multi-scale patterns |

## Support Vector Regression: `fitrsvm`

```matlab
% Basic SVR with RBF kernel
svrMdl = fitrsvm(X, y, ...
    'KernelFunction', 'rbf', ...
    'Standardize', true);

% With hyperparameter optimization
svrMdl = fitrsvm(X, y, ...
    'KernelFunction', 'rbf', ...
    'OptimizeHyperparameters', 'auto', ...
    'HyperparameterOptimizationOptions', struct('MaxObjectiveEvaluations', 30));

% Key parameters
svrMdl = fitrsvm(X, y, ...
    'KernelFunction', 'rbf', ...
    'BoxConstraint', 10, ...        % C: regularization
    'Epsilon', 0.1, ...             % Tube width
    'KernelScale', 'auto', ...
    'Standardize', true);
```

## Neural Network Regression: `fitrnet`

```matlab
% Basic neural network
Mdl = fitrnet(X, y, ...
    'LayerSizes', [50 25], ...
    'Activations', 'relu', ...
    'Standardize', true);

% With regularization and early stopping
Mdl = fitrnet(X, y, ...
    'LayerSizes', [100 50 25], ...
    'Activations', 'relu', ...
    'Lambda', 0.001, ...            % L2 regularization
    'IterationLimit', 1000, ...
    'Standardize', true);

% With optimization
Mdl = fitrnet(X, y, ...
    'OptimizeHyperparameters', 'auto', ...
    'HyperparameterOptimizationOptions', struct('MaxObjectiveEvaluations', 30));
```

## Ensemble Regression: `fitrensemble`

### Random Forest Regression

```matlab
% Bagged trees (Random Forest)
t = templateTree('MinLeafSize', 5);
RFMdl = fitrensemble(X, y, ...
    'Method', 'Bag', ...
    'NumLearningCycles', 100, ...
    'Learners', t);

% Feature importance
imp = predictorImportance(RFMdl);
[sortedImp, idx] = sort(imp, 'descend');
bar(sortedImp(1:10));
xticklabels(varNames(idx(1:10)));

% Out-of-bag prediction (no separate test set needed)
yhat_oob = oobPredict(RFMdl);
oobMSE = mean((y - yhat_oob).^2);
```

### Gradient Boosting Regression

```matlab
% Least Squares Boosting
LSBoostMdl = fitrensemble(X, y, ...
    'Method', 'LSBoost', ...
    'NumLearningCycles', 200, ...
    'LearnRate', 0.1);

% With optimization
Mdl = fitrensemble(X, y, ...
    'OptimizeHyperparameters', {'NumLearningCycles', 'LearnRate', 'MinLeafSize'}, ...
    'HyperparameterOptimizationOptions', struct('MaxObjectiveEvaluations', 50));
```

## Model Evaluation

### Regression Metrics

```matlab
% Predictions
ypred = predict(Mdl, Xtest);

% Mean Squared Error
MSE = mean((ytest - ypred).^2);

% Root Mean Squared Error
RMSE = sqrt(MSE);

% Mean Absolute Error
MAE = mean(abs(ytest - ypred));

% R-squared (coefficient of determination)
SS_res = sum((ytest - ypred).^2);
SS_tot = sum((ytest - mean(ytest)).^2);
R2 = 1 - SS_res / SS_tot;

% Adjusted R-squared
n = length(ytest);
p = size(Xtest, 2);
R2_adj = 1 - (1 - R2) * (n - 1) / (n - p - 1);

% Mean Absolute Percentage Error
MAPE = mean(abs((ytest - ypred) ./ ytest)) * 100;

fprintf('RMSE: %.4f\n', RMSE);
fprintf('MAE: %.4f\n', MAE);
fprintf('R²: %.4f\n', R2);
fprintf('Adjusted R²: %.4f\n', R2_adj);
```

### Cross-Validation for Regression

```matlab
% K-fold CV
cv = cvpartition(length(y), 'KFold', 10);
Mdl = fitrensemble(X, y, 'CVPartition', cv);
cvMSE = kfoldLoss(Mdl);
cvRMSE = sqrt(cvMSE);

% Manual CV with multiple metrics
rmse_folds = zeros(cv.NumTestSets, 1);
r2_folds = zeros(cv.NumTestSets, 1);

for i = 1:cv.NumTestSets
    trainIdx = training(cv, i);
    testIdx = test(cv, i);

    Mdl = fitrensemble(X(trainIdx,:), y(trainIdx), 'Method', 'Bag');
    ypred = predict(Mdl, X(testIdx,:));

    rmse_folds(i) = sqrt(mean((y(testIdx) - ypred).^2));
    r2_folds(i) = 1 - sum((y(testIdx) - ypred).^2) / sum((y(testIdx) - mean(y(testIdx))).^2);
end

fprintf('CV RMSE: %.4f ± %.4f\n', mean(rmse_folds), std(rmse_folds));
fprintf('CV R²: %.4f ± %.4f\n', mean(r2_folds), std(r2_folds));
```

### Residual Plots

```matlab
residuals = ytest - ypred;

figure;
subplot(2,2,1);
histogram(residuals, 20);
xlabel('Residual'); ylabel('Frequency');
title('Residual Distribution');

subplot(2,2,2);
scatter(ypred, residuals);
xlabel('Predicted'); ylabel('Residual');
yline(0, 'r--');
title('Residuals vs Predicted');

subplot(2,2,3);
qqplot(residuals);
title('Normal Q-Q Plot');

subplot(2,2,4);
scatter(ytest, ypred);
hold on;
plot([min(ytest) max(ytest)], [min(ytest) max(ytest)], 'r--');
xlabel('Actual'); ylabel('Predicted');
title('Actual vs Predicted');
```

## Biomedical Regression Example

```matlab
%% Predict Patient Outcome Score from Clinical Variables

% 1. Load data
data = readtable('patient_outcomes.csv');
X = data{:, {'Age', 'BMI', 'BloodPressure', 'Cholesterol', 'GlucoseLevel'}};
y = data.OutcomeScore;
varNames = {'Age', 'BMI', 'BloodPressure', 'Cholesterol', 'GlucoseLevel'};

% 2. Check for missing values
fprintf('Missing values per variable:\n');
disp(sum(ismissing(X)));

% 3. Handle missing values (if any)
X = fillmissing(X, 'knn');

% 4. Split data
cv = cvpartition(length(y), 'Holdout', 0.2);
XTrain = X(training(cv), :);
yTrain = y(training(cv));
XTest = X(test(cv), :);
yTest = y(test(cv));

% 5. Compare models
models = {};
names = {};

% Linear regression
mdl_lm = fitlm(XTrain, yTrain);
models{end+1} = mdl_lm;
names{end+1} = 'Linear';

% LASSO
[B, FitInfo] = lasso(XTrain, yTrain, 'CV', 10);
models{end+1} = struct('B', B(:, FitInfo.Index1SE), 'Intercept', FitInfo.Intercept(FitInfo.Index1SE));
names{end+1} = 'LASSO';

% Random Forest
mdl_rf = fitrensemble(XTrain, yTrain, 'Method', 'Bag', 'NumLearningCycles', 100);
models{end+1} = mdl_rf;
names{end+1} = 'Random Forest';

% GPR
mdl_gpr = fitrgp(XTrain, yTrain, 'KernelFunction', 'ardsquaredexponential', 'Standardize', true);
models{end+1} = mdl_gpr;
names{end+1} = 'GPR';

% 6. Evaluate on test set
rmse_test = zeros(length(models), 1);
r2_test = zeros(length(models), 1);

for i = 1:length(models)
    if strcmp(names{i}, 'Linear')
        ypred = predict(models{i}, XTest);
    elseif strcmp(names{i}, 'LASSO')
        ypred = XTest * models{i}.B + models{i}.Intercept;
    else
        ypred = predict(models{i}, XTest);
    end

    rmse_test(i) = sqrt(mean((yTest - ypred).^2));
    r2_test(i) = 1 - sum((yTest - ypred).^2) / sum((yTest - mean(yTest)).^2);
end

% 7. Display results
T = table(names', rmse_test, r2_test, 'VariableNames', {'Model', 'RMSE', 'R2'});
disp(T);

% 8. Feature importance from best model
imp = predictorImportance(mdl_rf);
figure;
bar(imp);
xticklabels(varNames);
ylabel('Importance');
title('Feature Importance (Random Forest)');
```

## Common Pitfalls

### Pitfall 1: Multicollinearity

```matlab
% Check for multicollinearity
R = corrcoef(X);
fprintf('Correlation matrix:\n');
disp(R);

% Variance Inflation Factor (VIF)
mdl = fitlm(X, y);
VIF = diag(inv(corrcoef(X)));
fprintf('VIF values:\n');
disp(array2table(VIF', 'VariableNames', varNames));
% VIF > 10 indicates severe multicollinearity

% Solution: Use ridge regression or remove correlated features
```

### Pitfall 2: Extrapolation

```matlab
% WRONG: Predicting outside training range
Xnew = [150, 300];  % Far outside training data range
ypred = predict(mdl, Xnew);  % Unreliable!

% Check training data range
fprintf('Training X range: [%.2f, %.2f]\n', min(X), max(X));
fprintf('New X: %.2f (EXTRAPOLATION!)\n', Xnew);

% CORRECT: Warn or refuse extrapolation
if any(Xnew < min(X) | Xnew > max(X))
    warning('Extrapolation detected - prediction may be unreliable');
end
```

### Pitfall 3: Non-Linear Relationships

```matlab
% WRONG: Linear model for nonlinear data
mdl = fitlm(X, y);
% R² = 0.3, residuals show clear pattern

% CORRECT: Add polynomial terms or use nonlinear model
mdl = fitlm([X, X.^2], y);  % Quadratic terms
% Or
mdl = fitrgp(X, y);         % GPR captures nonlinearity
```

## Function Quick Reference

| Function | Purpose | Key Parameters |
|----------|---------|----------------|
| `fitlm` | Linear regression | RobustOpts, Intercept |
| `stepwiselm` | Stepwise regression | Upper, PEnter, PRemove, Criterion |
| `fitglm` | Generalized linear | Distribution, Link |
| `lasso` | LASSO/Elastic Net | Alpha, Lambda, CV |
| `ridge` | Ridge regression | — |
| `fitrgp` | Gaussian Process | KernelFunction, Standardize |
| `fitrsvm` | Support Vector Regression | KernelFunction, BoxConstraint, Epsilon |
| `fitrnet` | Neural Network | LayerSizes, Activations, Lambda |
| `fitrensemble` | Ensemble (RF, Boosting) | Method, NumLearningCycles, Learners |
| `predict` | Make predictions | — |
| `plotResiduals` | Residual diagnostics | — |
| `plotDiagnostics` | Leverage, Cook's D | — |

---

*Source: MathWorks Statistics and Machine Learning Toolbox Documentation (R2025a)*
