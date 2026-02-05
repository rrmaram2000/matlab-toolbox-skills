# Classification

Machine learning classification assigns categorical labels to observations. This card covers all major classifiers in the Statistics and Machine Learning Toolbox with focus on biomedical applications.

## Algorithm Selection Guide

```
What kind of data?
├── High-dimensional (p >> n)
│   ├── Linear separable → fitclinear (fast) or fitcsvm (linear kernel)
│   └── Nonlinear → fitcsvm (RBF) or fitcensemble (boosting)
├── Need interpretability
│   ├── Single rule set → fitctree (decision tree)
│   └── Feature importance → fitcensemble (Random Forest) + predictorImportance
├── Small dataset (< 1000)
│   ├── Simple patterns → fitcknn (k-NN)
│   └── Gaussian features → fitcdiscr (LDA/QDA)
├── Text/categorical features → fitcnb (Naive Bayes)
├── Complex nonlinear → fitcnet (neural network) or fitcsvm (RBF)
├── Multi-class → fitcecoc (error-correcting output codes)
├── Class imbalance → fitcensemble with 'Prior', 'uniform' or 'Cost' matrix
└── Best accuracy → fitcensemble (Random Forest or boosting) with optimization
```

## Support Vector Machine (SVM): `fitcsvm`

SVMs find the optimal hyperplane that maximizes margin between classes.

### Binary SVM

```matlab
% Basic SVM with RBF kernel
Mdl = fitcsvm(X, Y, 'KernelFunction', 'rbf');

% With hyperparameter optimization (recommended)
Mdl = fitcsvm(X, Y, ...
    'KernelFunction', 'rbf', ...
    'OptimizeHyperparameters', 'auto', ...
    'HyperparameterOptimizationOptions', struct(...
        'AcquisitionFunctionName', 'expected-improvement-plus', ...
        'MaxObjectiveEvaluations', 30, ...
        'ShowPlots', false));

% Manual hyperparameters
Mdl = fitcsvm(X, Y, ...
    'KernelFunction', 'rbf', ...
    'BoxConstraint', 10, ...       % C: higher = less regularization
    'KernelScale', 'auto', ...     % gamma for RBF
    'Standardize', true);          % Always standardize for SVM!
```

### Kernel Selection

| Kernel | Use Case | Parameters |
|--------|----------|------------|
| `'linear'` | High-dimensional, linearly separable | BoxConstraint |
| `'rbf'` | General nonlinear (default choice) | BoxConstraint, KernelScale |
| `'polynomial'` | Specific nonlinear patterns | PolynomialOrder |

### Multi-Class SVM with ECOC

```matlab
% Error-Correcting Output Codes for multi-class
template = templateSVM('KernelFunction', 'rbf', 'Standardize', true);
Mdl = fitcecoc(X, Y, 'Learners', template);

% Predict with scores
[label, ~, ~, posterior] = predict(Mdl, Xtest);
```

## Decision Trees and Ensembles

### Single Decision Tree: `fitctree`

```matlab
tree = fitctree(X, Y, ...
    'MaxNumSplits', 20, ...        % Control complexity
    'MinLeafSize', 5, ...          % Minimum samples per leaf
    'CrossVal', 'on');             % Built-in cross-validation

% Visualize
view(tree, 'Mode', 'graph');

% Prune to avoid overfitting
optimalTree = prune(tree, 'Level', tree.PruneList(end));
```

### Random Forest: `fitcensemble` with Bagging

```matlab
% Random Forest (bagged trees)
t = templateTree('MinLeafSize', 5, 'Surrogate', 'on');
RFModel = fitcensemble(X, Y, ...
    'Method', 'Bag', ...
    'NumLearningCycles', 100, ...   % Number of trees
    'Learners', t);

% Feature importance
imp = predictorImportance(RFModel);
[sortedImp, idx] = sort(imp, 'descend');
bar(sortedImp(1:10));
xticklabels(varNames(idx(1:10)));
title('Top 10 Features');

% Out-of-bag error (built-in validation)
oobError = oobLoss(RFModel);
fprintf('OOB Error: %.2f%%\n', oobError * 100);
```

### Gradient Boosting: `fitcensemble`

```matlab
% AdaBoost for binary classification
AdaModel = fitcensemble(X, Y, ...
    'Method', 'AdaBoostM1', ...
    'NumLearningCycles', 100, ...
    'LearnRate', 0.1);             % Smaller = more robust

% Gradient Boosting (GentleBoost)
GBModel = fitcensemble(X, Y, ...
    'Method', 'GentleBoost', ...
    'NumLearningCycles', 200, ...
    'LearnRate', 0.05);

% XGBoost-style with optimization
Mdl = fitcensemble(X, Y, ...
    'OptimizeHyperparameters', {'NumLearningCycles', 'LearnRate', 'MinLeafSize'}, ...
    'HyperparameterOptimizationOptions', struct('MaxObjectiveEvaluations', 50));
```

## Neural Network: `fitcnet`

```matlab
% Basic neural network
Mdl = fitcnet(X, Y, ...
    'LayerSizes', [100 50], ...     % Two hidden layers
    'Activations', 'relu', ...       % 'relu', 'tanh', 'sigmoid', 'none'
    'Standardize', true, ...         % Always standardize!
    'Lambda', 0.001);                % L2 regularization

% With optimization
Mdl = fitcnet(X, Y, ...
    'OptimizeHyperparameters', 'auto', ...
    'HyperparameterOptimizationOptions', struct('MaxObjectiveEvaluations', 30));

% Training options
Mdl = fitcnet(X, Y, ...
    'LayerSizes', [128 64 32], ...
    'Activations', 'relu', ...
    'IterationLimit', 1000, ...
    'GradientTolerance', 1e-6, ...
    'LossTolerance', 1e-6, ...
    'Verbose', 1, ...                % Show training progress
    'VerboseFrequency', 50);
```

## k-Nearest Neighbors: `fitcknn`

```matlab
% Basic k-NN
Mdl = fitcknn(X, Y, ...
    'NumNeighbors', 5, ...
    'Distance', 'euclidean', ...
    'Standardize', true);

% Find optimal k
k_values = 1:2:21;
cvLoss = zeros(length(k_values), 1);
for i = 1:length(k_values)
    Mdl = fitcknn(X, Y, 'NumNeighbors', k_values(i), 'CrossVal', 'on');
    cvLoss(i) = kfoldLoss(Mdl);
end
[~, bestIdx] = min(cvLoss);
bestK = k_values(bestIdx);
```

## Naive Bayes: `fitcnb`

```matlab
% For mixed data types
Mdl = fitcnb(X, Y, ...
    'DistributionNames', {'normal', 'normal', 'kernel', 'mvmn'}, ...
    'Standardize', true);

% For all continuous (Gaussian)
Mdl = fitcnb(X, Y, 'DistributionNames', 'normal');

% Posterior probabilities
[label, Posterior] = predict(Mdl, Xnew);
```

## Cross-Validation

### K-Fold Cross-Validation

```matlab
% Method 1: cvpartition
cv = cvpartition(Y, 'KFold', 10, 'Stratify', true);
Mdl = fitcsvm(X, Y, 'CVPartition', cv);
cvLoss = kfoldLoss(Mdl);
accuracy = 1 - cvLoss;

% Method 2: crossval wrapper
Mdl = fitcensemble(X, Y, 'Method', 'Bag');
CVMdl = crossval(Mdl, 'KFold', 10);
loss = kfoldLoss(CVMdl);

% Get predictions for each fold
[label, score] = kfoldPredict(CVMdl);
```

### Leave-One-Out (Small Datasets)

```matlab
cv = cvpartition(Y, 'LeaveOut');
Mdl = fitcsvm(X, Y, 'CVPartition', cv);
looLoss = kfoldLoss(Mdl);
```

### Holdout Validation

```matlab
cv = cvpartition(Y, 'Holdout', 0.2, 'Stratify', true);
XTrain = X(training(cv), :);
YTrain = Y(training(cv));
XTest = X(test(cv), :);
YTest = Y(test(cv));

Mdl = fitcensemble(XTrain, YTrain, 'Method', 'Bag');
YPred = predict(Mdl, XTest);
accuracy = mean(YPred == YTest);
```

## Model Evaluation

### Confusion Matrix and Metrics

```matlab
[YPred, scores] = predict(Mdl, XTest);

% Confusion matrix
C = confusionmat(YTest, YPred);
confusionchart(YTest, YPred);

% Manual metrics
TP = C(2,2); TN = C(1,1); FP = C(1,2); FN = C(2,1);
accuracy = (TP + TN) / sum(C(:));
sensitivity = TP / (TP + FN);  % Recall, TPR
specificity = TN / (TN + FP);  % TNR
precision = TP / (TP + FP);    % PPV
F1 = 2 * precision * sensitivity / (precision + sensitivity);

fprintf('Accuracy: %.2f%%\n', accuracy * 100);
fprintf('Sensitivity: %.2f%%\n', sensitivity * 100);
fprintf('Specificity: %.2f%%\n', specificity * 100);
fprintf('F1 Score: %.2f\n', F1);
```

### ROC Curve and AUC

```matlab
% Binary classification
[Xroc, Yroc, T, AUC] = perfcurve(YTest, scores(:,2), 'positive');

figure;
plot(Xroc, Yroc, 'LineWidth', 2);
hold on;
plot([0 1], [0 1], 'k--');
xlabel('False Positive Rate');
ylabel('True Positive Rate');
title(sprintf('ROC Curve (AUC = %.3f)', AUC));

% Find optimal threshold (Youden's J)
J = Yroc - Xroc;
[~, optIdx] = max(J);
optThreshold = T(optIdx);
```

### Multi-Class Evaluation

```matlab
% Per-class metrics
for i = 1:numClasses
    classMetrics = confusionmat(YTest == classes(i), YPred == classes(i));
    precision(i) = classMetrics(2,2) / sum(classMetrics(:,2));
    recall(i) = classMetrics(2,2) / sum(classMetrics(2,:));
end

% Macro-averaged
macroPrecision = mean(precision);
macroRecall = mean(recall);
macroF1 = 2 * macroPrecision * macroRecall / (macroPrecision + macroRecall);
```

## Handling Class Imbalance

### Cost-Sensitive Learning

```matlab
% Cost matrix: Cost(i,j) = cost of predicting j when true class is i
% For binary: [TN cost, FP cost; FN cost, TP cost]
Cost = [0 1; 10 0];  % 10x cost for false negatives

Mdl = fitcsvm(X, Y, 'Cost', Cost);
Mdl = fitcensemble(X, Y, 'Cost', Cost);
```

### Prior Adjustment

```matlab
% Uniform prior (treats classes equally)
Mdl = fitcensemble(X, Y, 'Prior', 'uniform');

% Custom prior
Mdl = fitcnb(X, Y, 'Prior', [0.3 0.7]);
```

### Resampling Techniques

```matlab
% Oversample minority class
minorityIdx = find(Y == 'positive');
oversampleIdx = minorityIdx(randi(length(minorityIdx), numToAdd, 1));
XBalanced = [X; X(oversampleIdx, :)];
YBalanced = [Y; Y(oversampleIdx)];

% Undersample majority class
majorityIdx = find(Y == 'negative');
keepIdx = majorityIdx(randperm(length(majorityIdx), numMinority));
XBalanced = [X(minorityIdx, :); X(keepIdx, :)];
```

## Biomedical Classification Example

```matlab
%% Complete Diagnostic Classifier Pipeline

% 1. Load and prepare data
data = readtable('patient_data.csv');
X = table2array(data(:, 2:end-1));  % Features
Y = categorical(data.Diagnosis);     % Labels

% 2. Check class balance
tabulate(Y);

% 3. Handle missing values (fillmissing is in Stats-ML Toolbox; knnimpute requires Bioinformatics)
X = fillmissing(X, 'knn');  % k-NN imputation

% 4. Feature selection (MRMR)
idx = fscmrmr(X, Y);
selectedFeatures = idx(1:20);  % Top 20 features
X = X(:, selectedFeatures);

% 5. Stratified split
cv = cvpartition(Y, 'Holdout', 0.2, 'Stratify', true);
XTrain = X(training(cv), :);
YTrain = Y(training(cv));
XTest = X(test(cv), :);
YTest = Y(test(cv));

% 6. Train with hyperparameter optimization
Mdl = fitcensemble(XTrain, YTrain, ...
    'Method', 'Bag', ...
    'OptimizeHyperparameters', 'auto', ...
    'HyperparameterOptimizationOptions', struct(...
        'AcquisitionFunctionName', 'expected-improvement-plus', ...
        'MaxObjectiveEvaluations', 50, ...
        'ShowPlots', false));

% 7. Evaluate
[YPred, scores] = predict(Mdl, XTest);
C = confusionmat(YTest, YPred);

% 8. Compute metrics
sensitivity = C(2,2) / sum(C(2,:));
specificity = C(1,1) / sum(C(1,:));
[~, ~, ~, AUC] = perfcurve(YTest, scores(:,2), categorical({'positive'}));

fprintf('Sensitivity: %.2f%%\n', sensitivity * 100);
fprintf('Specificity: %.2f%%\n', specificity * 100);
fprintf('AUC: %.3f\n', AUC);

% 9. Feature importance
imp = predictorImportance(Mdl);
bar(imp);
xticklabels(featureNames(selectedFeatures));
xtickangle(45);
title('Feature Importance');
```

## Common Pitfalls

### Pitfall 1: Forgetting to Standardize

```matlab
% WRONG: SVM without standardization
Mdl = fitcsvm(X, Y, 'KernelFunction', 'rbf');  % Features on different scales!

% CORRECT: Always standardize for distance-based methods
Mdl = fitcsvm(X, Y, 'KernelFunction', 'rbf', 'Standardize', true);
```

### Pitfall 2: Data Leakage

```matlab
% WRONG: Standardizing before split
X_scaled = zscore(X);  % Uses ALL data including test set!
cv = cvpartition(Y, 'Holdout', 0.2);

% CORRECT: Standardize within training only (or use 'Standardize' option)
cv = cvpartition(Y, 'Holdout', 0.2);
XTrain = X(training(cv), :);
[XTrain_scaled, mu, sigma] = zscore(XTrain);
XTest_scaled = (X(test(cv), :) - mu) ./ sigma;
```

### Pitfall 3: Ignoring Class Imbalance

```matlab
% WRONG: Training on imbalanced data without adjustment
tabulate(Y);  % 95% negative, 5% positive
Mdl = fitcsvm(X, Y);  % Biased toward majority class

% CORRECT: Use cost-sensitive or resampling
Mdl = fitcsvm(X, Y, 'Cost', [0 1; 20 0], 'Standardize', true);
```

## Function Quick Reference

| Function | Purpose | Key Parameters |
|----------|---------|----------------|
| `fitcsvm` | Support Vector Machine | KernelFunction, BoxConstraint, Standardize |
| `fitctree` | Decision Tree | MaxNumSplits, MinLeafSize |
| `fitcensemble` | Ensemble (RF, Boosting) | Method, NumLearningCycles, Learners |
| `fitcecoc` | Multi-class wrapper | Learners, Coding |
| `fitcknn` | k-Nearest Neighbors | NumNeighbors, Distance |
| `fitcnb` | Naive Bayes | DistributionNames |
| `fitcnet` | Neural Network | LayerSizes, Activations, Lambda |
| `fitcdiscr` | Discriminant Analysis | DiscrimType |
| `cvpartition` | Create CV partition | KFold, Holdout, Stratify |
| `crossval` | Cross-validate model | KFold, CVPartition |
| `kfoldLoss` | CV loss | — |
| `kfoldPredict` | CV predictions | — |
| `predict` | Make predictions | — |
| `perfcurve` | ROC curve | — |
| `confusionmat` | Confusion matrix | — |
| `predictorImportance` | Feature importance | — |

---

*Source: MathWorks Statistics and Machine Learning Toolbox Documentation (R2025a)*
