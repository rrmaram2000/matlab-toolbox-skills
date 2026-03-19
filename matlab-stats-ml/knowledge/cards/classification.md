# Classification — Biomedical Patterns

The model already knows `fitcsvm`, `fitcensemble`, `fitctree`, `fitcknn`, `fitcnb`, `fitcnet`, `fitcecoc`, cross-validation, ROC/AUC, and confusion matrices. This card covers only advanced biomedical-specific patterns.

## Algorithm Selection for Clinical Data

```
Clinical classification scenario?
├── High-dimensional biomarkers (p >> n, e.g., genomics)
│   ├── Feature selection first → fscmrmr or LASSO, then fitcsvm/fitcensemble
│   └── Regularized → fitclinear (fast for very high p)
├── Need clinical interpretability
│   ├── Single decision tree → fitctree (show to clinicians)
│   └── Feature importance → fitcensemble('Method','Bag') + predictorImportance
├── Class imbalance (rare disease, adverse events)
│   ├── Cost-sensitive → fitcsvm(X,Y,'Cost',[0 1; 20 0]) — penalize FN heavily
│   └── Prior adjustment → fitcensemble(X,Y,'Prior','uniform')
├── Need calibrated probabilities → fitcnb or Platt scaling on SVM
└── Multi-site / multi-cohort → nested CV to avoid overfitting
```

## Handling Class Imbalance in Medical Data

Class imbalance is the norm in diagnostic classification (e.g., 5% disease prevalence).

```matlab
% Cost-sensitive: penalize missed diagnoses more than false alarms
% Cost(i,j) = cost of predicting j when true class is i
Cost = [0 1; 10 0];  % 10x cost for false negatives (missed disease)
Mdl = fitcsvm(X, Y, 'Cost', Cost, 'Standardize', true);

% SMOTE-like oversampling for minority class
minorityIdx = find(Y == 'positive');
oversampleIdx = minorityIdx(randi(length(minorityIdx), numToAdd, 1));
XBalanced = [X; X(oversampleIdx, :)];
YBalanced = [Y; Y(oversampleIdx)];
```

## Clinical Metrics Beyond Accuracy

```matlab
% Standard accuracy is misleading with imbalanced classes
% Always report these for clinical models:
C = confusionmat(YTest, YPred);
TP = C(2,2); TN = C(1,1); FP = C(1,2); FN = C(2,1);

sensitivity = TP / (TP + FN);  % Critical: can we catch the disease?
specificity = TN / (TN + FP);  % Important: avoid unnecessary treatment
ppv = TP / (TP + FP);          % Positive Predictive Value
npv = TN / (TN + FN);          % Negative Predictive Value

% Likelihood ratios (clinically actionable)
LR_pos = sensitivity / (1 - specificity);  % LR+ > 10 is strong
LR_neg = (1 - sensitivity) / specificity;  % LR- < 0.1 is strong

% Youden's J for optimal threshold
[Xroc, Yroc, T, AUC] = perfcurve(YTest, scores(:,2), 'positive');
J = Yroc - Xroc;
[~, optIdx] = max(J);
optThreshold = T(optIdx);
```

## Data Leakage Prevention

```matlab
% WRONG: Feature selection or normalization on ALL data before split
X_scaled = zscore(X);  % Uses test data statistics!
idx = fscmrmr(X_scaled, Y);  % Feature selection on test data!
cv = cvpartition(Y, 'Holdout', 0.2);

% CORRECT: All preprocessing within training fold only
cv = cvpartition(Y, 'Holdout', 0.2);
XTrain = X(training(cv), :);
[XTrain_scaled, mu, sigma] = zscore(XTrain);
XTest_scaled = (X(test(cv), :) - mu) ./ sigma;
idx = fscmrmr(XTrain_scaled, Y(training(cv)));  % Feature selection on training only
```

## Biomedical Diagnostic Classifier Pipeline

See `scripts/template_svm_classification.m` and `scripts/template_random_forest_ensemble.m` for complete working templates.

```matlab
%% Complete Diagnostic Classifier Pipeline (summary)
% 1. Load and prepare data
data = readtable('patient_data.csv');
X = table2array(data(:, 2:end-1));
Y = categorical(data.Diagnosis);

% 2. Handle missing values
X = fillmissing(X, 'knn');

% 3. Feature selection (MRMR) — on training data only
cv = cvpartition(Y, 'Holdout', 0.2, 'Stratify', true);
XTrain = X(training(cv), :);  YTrain = Y(training(cv));
idx = fscmrmr(XTrain, YTrain);
selectedFeatures = idx(1:20);

% 4. Train with hyperparameter optimization
Mdl = fitcensemble(XTrain(:, selectedFeatures), YTrain, ...
    'Method', 'Bag', ...
    'OptimizeHyperparameters', 'auto', ...
    'HyperparameterOptimizationOptions', struct(...
        'AcquisitionFunctionName', 'expected-improvement-plus', ...
        'MaxObjectiveEvaluations', 50, 'ShowPlots', false));

% 5. Evaluate — report clinical metrics
[YPred, scores] = predict(Mdl, X(test(cv), selectedFeatures));
[~, ~, ~, AUC] = perfcurve(Y(test(cv)), scores(:,2), categorical({'positive'}));
```

---

*See also: biomedical.md for full workflows, scripts/template_svm_classification.m, scripts/template_random_forest_ensemble.m*
