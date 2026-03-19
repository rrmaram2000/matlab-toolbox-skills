# Biomedical Applications

This card covers machine learning workflows specific to biomedical data analysis, including diagnostic classifiers, biomarker discovery, clinical trial analysis, and handling common challenges in medical datasets.

## Diagnostic Classifier Pipeline

### Complete Diagnostic Model Workflow

```matlab
function [Mdl, results] = buildDiagnosticClassifier(data, targetVar, predictorVars)
    % Complete workflow for building a diagnostic classifier
    %
    % data: table with clinical data
    % targetVar: name of diagnosis column
    % predictorVars: cell array of predictor column names

    fprintf('=== Diagnostic Classifier Pipeline ===\n\n');

    %% 1. Data Preparation
    X = table2array(data(:, predictorVars));
    Y = data.(targetVar);

    fprintf('1. Data: %d samples, %d features, %d classes\n', ...
        size(X, 1), size(X, 2), numel(unique(Y)));

    % Check for missing values
    missingRate = mean(isnan(X(:)));
    if missingRate > 0
        fprintf('   Missing values: %.1f%% - Imputing...\n', missingRate*100);
        X = fillmissing(X, 'knn', 5);  % KNN imputation
    end

    % Normalize features
    [X_norm, mu, sigma] = zscore(X);
    fprintf('   Features normalized (z-score)\n');

    %% 2. Train-Test Split (Stratified)
    cv_split = cvpartition(Y, 'Holdout', 0.2, 'Stratify', true);
    XTrain = X_norm(training(cv_split), :);
    YTrain = Y(training(cv_split));
    XTest = X_norm(test(cv_split), :);
    YTest = Y(test(cv_split));

    fprintf('\n2. Split: %d train, %d test\n', ...
        size(XTrain, 1), size(XTest, 1));

    %% 3. Model Selection with Cross-Validation
    fprintf('\n3. Model Selection (5-fold CV):\n');

    models = struct();
    models.SVM = fitcsvm(XTrain, YTrain, ...
        'KernelFunction', 'rbf', ...
        'OptimizeHyperparameters', 'auto', ...
        'HyperparameterOptimizationOptions', struct(...
            'Verbose', 0, 'ShowPlots', false, 'Kfold', 5));

    models.RF = fitcensemble(XTrain, YTrain, ...
        'Method', 'Bag', ...
        'NumLearningCycles', 100);

    models.NN = fitcnet(XTrain, YTrain, ...
        'LayerSizes', [64 32], ...
        'Standardize', false, ...  % Already normalized
        'Lambda', 0.001);

    % Cross-validated performance
    modelNames = fieldnames(models);
    cvAccuracies = zeros(length(modelNames), 1);

    for i = 1:length(modelNames)
        Mdl_cv = crossval(models.(modelNames{i}), 'KFold', 5);
        cvAccuracies(i) = 1 - kfoldLoss(Mdl_cv);
        fprintf('   %s: %.2f%% CV accuracy\n', modelNames{i}, cvAccuracies(i)*100);
    end

    % Select best model
    [~, bestIdx] = max(cvAccuracies);
    bestModelName = modelNames{bestIdx};
    Mdl = models.(bestModelName);
    fprintf('   Best model: %s\n', bestModelName);

    %% 4. Final Evaluation on Test Set
    fprintf('\n4. Test Set Evaluation:\n');

    [YPred, scores] = predict(Mdl, XTest);

    % Accuracy
    accuracy = mean(YPred == YTest);
    fprintf('   Accuracy: %.2f%%\n', accuracy * 100);

    % Confusion matrix
    C = confusionmat(YTest, YPred);
    fprintf('   Confusion Matrix:\n');
    disp(C);

    % For binary classification
    if size(C, 1) == 2
        TP = C(2,2); TN = C(1,1); FP = C(1,2); FN = C(2,1);

        sensitivity = TP / (TP + FN);  % True Positive Rate
        specificity = TN / (TN + FP);  % True Negative Rate
        ppv = TP / (TP + FP);          % Positive Predictive Value
        npv = TN / (TN + FN);          % Negative Predictive Value

        fprintf('   Sensitivity: %.2f%%\n', sensitivity * 100);
        fprintf('   Specificity: %.2f%%\n', specificity * 100);
        fprintf('   PPV: %.2f%%\n', ppv * 100);
        fprintf('   NPV: %.2f%%\n', npv * 100);

        % ROC curve and AUC
        if size(scores, 2) >= 2
            [Xroc, Yroc, ~, AUC] = perfcurve(YTest, scores(:,2), ...
                categories(YTest));
            AUC = AUC(1);  % Get scalar if cell
            fprintf('   AUC: %.3f\n', AUC);

            % Plot ROC
            figure;
            plot(Xroc, Yroc, 'b-', 'LineWidth', 2);
            hold on;
            plot([0 1], [0 1], 'k--');
            xlabel('False Positive Rate (1 - Specificity)');
            ylabel('True Positive Rate (Sensitivity)');
            title(sprintf('ROC Curve (AUC = %.3f)', AUC));
            grid on;
        end
    end

    %% 5. Package Results
    results.accuracy = accuracy;
    results.confusionMatrix = C;
    results.normParams = struct('mu', mu, 'sigma', sigma);
    results.predictorVars = predictorVars;

    if exist('sensitivity', 'var')
        results.sensitivity = sensitivity;
        results.specificity = specificity;
        results.AUC = AUC;
    end
end
```

### Clinical-Specific Metrics (Beyond Basic Accuracy)

For diagnostic classifiers, always compute these clinical metrics in addition to accuracy, sensitivity, and specificity:

```matlab
C = confusionmat(YTrue, YPred);
TP = C(2,2); TN = C(1,1); FP = C(1,2); FN = C(2,1);
sensitivity = TP / (TP + FN);
specificity = TN / (TN + FP);

% Likelihood ratios (clinically actionable — rule-in/rule-out)
LR_pos = sensitivity / (1 - specificity);  % LR+ > 10 strongly rules in
LR_neg = (1 - sensitivity) / specificity;  % LR- < 0.1 strongly rules out

% Matthews Correlation Coefficient (best single metric for imbalanced data)
MCC = (TP*TN - FP*FN) / sqrt((TP+FP)*(TP+FN)*(TN+FP)*(TN+FN));

% Balanced accuracy (accounts for class imbalance)
balancedAcc = (sensitivity + specificity) / 2;
```

## Biomarker Discovery

### Univariate Feature Selection

```matlab
function [selectedFeatures, pvalues] = univariateSelection(X, Y, method, alpha)
    % Univariate feature selection with FDR correction
    %
    % method: 'ttest', 'ranksum', 'anova'
    % alpha: significance level after FDR correction

    if nargin < 3, method = 'ttest'; end
    if nargin < 4, alpha = 0.05; end

    [n, p] = size(X);
    pvalues = zeros(p, 1);
    classes = unique(Y);

    for j = 1:p
        switch method
            case 'ttest'
                % Two-sample t-test (parametric)
                [~, pvalues(j)] = ttest2(X(Y==classes(1), j), ...
                    X(Y==classes(2), j));
            case 'ranksum'
                % Wilcoxon rank-sum test (non-parametric)
                pvalues(j) = ranksum(X(Y==classes(1), j), ...
                    X(Y==classes(2), j));
            case 'anova'
                % One-way ANOVA (multiple groups)
                pvalues(j) = anova1(X(:, j), Y, 'off');
        end
    end

    % FDR correction (Benjamini-Hochberg)
    [pvalues_sorted, sortIdx] = sort(pvalues);
    m = length(pvalues);
    threshold = (1:m)' / m * alpha;
    significant = pvalues_sorted <= threshold;

    % Find largest k such that p(k) <= k/m * alpha
    k = find(significant, 1, 'last');
    if isempty(k)
        selectedFeatures = [];
    else
        selectedFeatures = sortIdx(1:k);
    end

    fprintf('Univariate selection (%s, FDR<%.2f):\n', method, alpha);
    fprintf('  %d/%d features selected\n', length(selectedFeatures), p);
end

% Usage
[selectedVars, pvals] = univariateSelection(X, Y, 'ttest', 0.05);
```

### LASSO Feature Selection

```matlab
function [selectedVars, B, FitInfo] = lassoSelection(X, Y, nfolds)
    % Feature selection using LASSO with cross-validation

    if nargin < 3, nfolds = 10; end

    % Convert labels to numeric for regression
    if iscategorical(Y) || iscell(Y)
        classes = unique(Y);
        y_numeric = double(Y == classes(end));  % Binary: positive class = 1
    else
        y_numeric = Y;
    end

    % Standardize X
    [X_std, mu, sigma] = zscore(X);

    % LASSO with CV
    [B, FitInfo] = lasso(X_std, y_numeric, ...
        'CV', nfolds, ...
        'NumLambda', 100, ...
        'Alpha', 1);  % LASSO (L1 penalty)

    % Select features using 1SE rule (more conservative)
    coef_1se = B(:, FitInfo.Index1SE);
    selectedVars = find(coef_1se ~= 0);

    % Also get coefficients at minimum MSE
    coef_min = B(:, FitInfo.IndexMinMSE);
    selectedVars_min = find(coef_min ~= 0);

    fprintf('LASSO Feature Selection:\n');
    fprintf('  Lambda_min: %d features selected\n', length(selectedVars_min));
    fprintf('  Lambda_1SE: %d features selected (more conservative)\n', ...
        length(selectedVars));

    % Visualize
    figure;
    lassoPlot(B, FitInfo, 'PlotType', 'CV');
    title('LASSO Cross-Validation');
end
```

### Random Forest Feature Importance

```matlab
function [importance, sortedIdx] = rfFeatureImportance(X, Y, varNames, nTrees)
    % Feature importance using Random Forest

    if nargin < 4, nTrees = 200; end

    % Train Random Forest
    Mdl = fitcensemble(X, Y, ...
        'Method', 'Bag', ...
        'NumLearningCycles', nTrees, ...
        'Learners', templateTree('MinLeafSize', 5));

    % Get predictor importance (out-of-bag permutation)
    importance = oobPermutedPredictorImportance(Mdl);

    % Sort by importance
    [sortedImp, sortedIdx] = sort(importance, 'descend');

    % Visualize
    figure;
    nShow = min(20, length(importance));
    barh(sortedImp(nShow:-1:1));
    if nargin >= 3 && ~isempty(varNames)
        yticks(1:nShow);
        yticklabels(varNames(sortedIdx(nShow:-1:1)));
    end
    xlabel('Importance');
    title('Random Forest Feature Importance');

    % Display top features
    fprintf('Top 10 Features (RF Importance):\n');
    for i = 1:min(10, length(sortedIdx))
        if nargin >= 3 && ~isempty(varNames)
            fprintf('  %d. %s (%.4f)\n', i, varNames{sortedIdx(i)}, ...
                sortedImp(i));
        else
            fprintf('  %d. Feature %d (%.4f)\n', i, sortedIdx(i), sortedImp(i));
        end
    end
end
```

### Combined Feature Selection

```matlab
function [consensusFeatures, rankings] = consensusFeatureSelection(X, Y, varNames)
    % Combine multiple feature selection methods

    [n, p] = size(X);
    rankings = zeros(p, 4);  % 4 methods

    % 1. Univariate t-test
    pvals = zeros(p, 1);
    classes = unique(Y);
    for j = 1:p
        [~, pvals(j)] = ttest2(X(Y==classes(1), j), X(Y==classes(2), j));
    end
    [~, rankings(:,1)] = sort(pvals);

    % 2. mRMR
    rankings(:,2) = fscmrmr(X, Y);

    % 3. LASSO
    y_numeric = double(Y == classes(end));
    [B, FitInfo] = lasso(zscore(X), y_numeric, 'CV', 5);
    coef_abs = abs(B(:, FitInfo.Index1SE));
    [~, rankings(:,3)] = sort(coef_abs, 'descend');

    % 4. Random Forest
    Mdl = fitcensemble(X, Y, 'Method', 'Bag', 'NumLearningCycles', 100);
    imp = oobPermutedPredictorImportance(Mdl);
    [~, rankings(:,4)] = sort(imp, 'descend');

    % Compute consensus (average rank)
    avgRank = zeros(p, 1);
    for j = 1:p
        ranks = zeros(4, 1);
        for m = 1:4
            ranks(m) = find(rankings(:,m) == j);
        end
        avgRank(j) = mean(ranks);
    end

    [~, consensusFeatures] = sort(avgRank);

    % Display results
    fprintf('=== Consensus Feature Ranking ===\n');
    fprintf('%-20s %8s %8s %8s %8s %8s\n', ...
        'Feature', 't-test', 'mRMR', 'LASSO', 'RF', 'Avg');
    fprintf('%s\n', repmat('-', 1, 70));

    for i = 1:min(10, p)
        feat = consensusFeatures(i);
        ranks = zeros(4, 1);
        for m = 1:4
            ranks(m) = find(rankings(:,m) == feat);
        end
        if nargin >= 3 && ~isempty(varNames)
            name = varNames{feat};
        else
            name = sprintf('Feature %d', feat);
        end
        fprintf('%-20s %8d %8d %8d %8d %8.1f\n', ...
            name, ranks(1), ranks(2), ranks(3), ranks(4), avgRank(feat));
    end
end
```

## Handling Class Imbalance

### Strategies Overview

```matlab
function Mdl = handleClassImbalance(X, Y, method)
    % Handle class imbalance in medical datasets
    %
    % method: 'cost', 'prior', 'smote', 'undersample'

    % Check class distribution
    classes = unique(Y);
    counts = arrayfun(@(c) sum(Y == c), classes);
    fprintf('Class distribution:\n');
    for i = 1:length(classes)
        fprintf('  %s: %d (%.1f%%)\n', string(classes(i)), ...
            counts(i), 100*counts(i)/length(Y));
    end

    switch method
        case 'cost'
            % Cost-sensitive learning
            % Penalize minority class misclassification more
            minority_weight = counts(1) / counts(2);  % If class 2 is majority
            if minority_weight > 1
                minority_weight = 1 / minority_weight;
            end

            costMatrix = [0, 1; 1/minority_weight, 0];
            Mdl = fitcsvm(X, Y, ...
                'Cost', costMatrix, ...
                'KernelFunction', 'rbf', ...
                'Standardize', true);

        case 'prior'
            % Uniform prior (ignore class frequencies)
            Mdl = fitcensemble(X, Y, ...
                'Prior', 'uniform', ...
                'Method', 'Bag');

        case 'smote'
            % SMOTE oversampling (synthetic minority oversampling)
            [X_balanced, Y_balanced] = applySMOTE(X, Y);
            Mdl = fitcensemble(X_balanced, Y_balanced, 'Method', 'Bag');

        case 'undersample'
            % Random undersampling of majority class
            [X_balanced, Y_balanced] = undersample(X, Y);
            Mdl = fitcensemble(X_balanced, Y_balanced, 'Method', 'Bag');
    end
end

function [X_new, Y_new] = applySMOTE(X, Y, k)
    % Simple SMOTE implementation

    if nargin < 3, k = 5; end

    classes = unique(Y);
    counts = [sum(Y == classes(1)), sum(Y == classes(2))];
    [minCount, minIdx] = min(counts);
    maxCount = max(counts);

    minClass = classes(minIdx);
    X_minority = X(Y == minClass, :);

    % Number of synthetic samples needed
    nSynthetic = maxCount - minCount;

    % k-NN for minority class
    Mdl_knn = fitcknn(X_minority, (1:size(X_minority, 1))', 'NumNeighbors', k);

    % Generate synthetic samples
    X_synthetic = zeros(nSynthetic, size(X, 2));
    for i = 1:nSynthetic
        % Random minority sample
        idx = randi(size(X_minority, 1));
        sample = X_minority(idx, :);

        % Random neighbor
        [~, neighbors] = predict(Mdl_knn, sample);
        neighbor_idx = neighbors(randi(k));
        neighbor = X_minority(neighbor_idx, :);

        % Interpolate
        alpha = rand;
        X_synthetic(i, :) = sample + alpha * (neighbor - sample);
    end

    % Combine
    X_new = [X; X_synthetic];
    Y_new = [Y; repmat(minClass, nSynthetic, 1)];

    fprintf('SMOTE: Added %d synthetic samples\n', nSynthetic);
end

function [X_new, Y_new] = undersample(X, Y)
    % Random undersampling of majority class

    classes = unique(Y);
    counts = [sum(Y == classes(1)), sum(Y == classes(2))];
    [minCount, minIdx] = min(counts);

    idx_keep = [];
    for i = 1:length(classes)
        classIdx = find(Y == classes(i));
        if i == minIdx
            idx_keep = [idx_keep; classIdx];
        else
            % Random subsample
            selected = randsample(classIdx, minCount);
            idx_keep = [idx_keep; selected];
        end
    end

    X_new = X(idx_keep, :);
    Y_new = Y(idx_keep);

    fprintf('Undersampling: Reduced to %d samples\n', length(Y_new));
end
```

## Model Validation

### Nested Cross-Validation

```matlab
function [results] = nestedCrossValidation(X, Y, outerFolds, innerFolds)
    % Nested CV for unbiased performance estimation with hyperparameter tuning

    if nargin < 3, outerFolds = 5; end
    if nargin < 4, innerFolds = 5; end

    outerCV = cvpartition(Y, 'KFold', outerFolds);
    testAccuracies = zeros(outerFolds, 1);
    testAUCs = zeros(outerFolds, 1);

    fprintf('Nested Cross-Validation (%d outer × %d inner folds)\n', ...
        outerFolds, innerFolds);

    for i = 1:outerFolds
        fprintf('  Outer fold %d/%d...\n', i, outerFolds);

        % Split
        trainIdx = training(outerCV, i);
        testIdx = test(outerCV, i);

        X_train = X(trainIdx, :);
        Y_train = Y(trainIdx);
        X_test = X(testIdx, :);
        Y_test = Y(testIdx);

        % Inner CV for hyperparameter optimization
        Mdl = fitcsvm(X_train, Y_train, ...
            'KernelFunction', 'rbf', ...
            'OptimizeHyperparameters', 'auto', ...
            'HyperparameterOptimizationOptions', struct(...
                'Kfold', innerFolds, ...
                'ShowPlots', false, ...
                'Verbose', 0));

        % Evaluate on outer test fold
        [YPred, scores] = predict(Mdl, X_test);
        testAccuracies(i) = mean(YPred == Y_test);

        % AUC (if binary)
        if size(scores, 2) >= 2
            classes = unique(Y);
            [~, ~, ~, auc] = perfcurve(Y_test, scores(:,2), classes(2));
            testAUCs(i) = auc;
        end
    end

    % Results
    results.accuracies = testAccuracies;
    results.aucs = testAUCs;
    results.meanAccuracy = mean(testAccuracies);
    results.stdAccuracy = std(testAccuracies);
    results.meanAUC = mean(testAUCs);
    results.stdAUC = std(testAUCs);

    fprintf('\nResults:\n');
    fprintf('  Accuracy: %.2f%% (±%.2f%%)\n', ...
        results.meanAccuracy * 100, results.stdAccuracy * 100);
    fprintf('  AUC: %.3f (±%.3f)\n', results.meanAUC, results.stdAUC);
end
```

### Bootstrap Confidence Intervals

```matlab
function ci = bootstrapConfidenceInterval(YTrue, YPred, metric, nboot, alpha)
    % Bootstrap confidence interval for classification metrics

    if nargin < 4, nboot = 1000; end
    if nargin < 5, alpha = 0.05; end

    n = length(YTrue);
    bootStats = zeros(nboot, 1);

    for b = 1:nboot
        % Bootstrap sample
        idx = randsample(n, n, true);
        YTrue_boot = YTrue(idx);
        YPred_boot = YPred(idx);

        % Compute metric
        switch metric
            case 'accuracy'
                bootStats(b) = mean(YTrue_boot == YPred_boot);
            case 'sensitivity'
                C = confusionmat(YTrue_boot, YPred_boot);
                bootStats(b) = C(2,2) / sum(C(2,:));
            case 'specificity'
                C = confusionmat(YTrue_boot, YPred_boot);
                bootStats(b) = C(1,1) / sum(C(1,:));
        end
    end

    % Percentile CI
    ci = prctile(bootStats, [alpha/2 * 100, (1 - alpha/2) * 100]);

    fprintf('%s: %.3f [95%% CI: %.3f - %.3f]\n', ...
        metric, mean(bootStats), ci(1), ci(2));
end
```

## Clinical Study Analysis

### Power Analysis

```matlab
function n = sampleSizeBinary(auc_null, auc_alt, alpha, power, ratio)
    % Sample size for comparing AUC to null value
    %
    % auc_null: null hypothesis AUC (e.g., 0.5 for random)
    % auc_alt: alternative AUC (expected)
    % alpha: significance level
    % power: desired power
    % ratio: ratio of positive to negative cases

    if nargin < 5, ratio = 1; end

    % Z-values
    z_alpha = norminv(1 - alpha/2);
    z_beta = norminv(power);

    % Variance estimation (Hanley & McNeil approximation)
    q1 = auc_alt / (2 - auc_alt);
    q2 = 2 * auc_alt^2 / (1 + auc_alt);

    var_auc = (auc_alt * (1 - auc_alt) + ...
        (ratio - 1) * (q1 - auc_alt^2) + ...
        (1/ratio - 1) * (q2 - auc_alt^2)) / ...
        (ratio + 1);

    % Sample size per group
    effect = auc_alt - auc_null;
    n_per_group = ((z_alpha + z_beta)^2 * var_auc) / effect^2;
    n = ceil(n_per_group * (1 + ratio));

    fprintf('Sample Size Analysis:\n');
    fprintf('  H0: AUC = %.2f\n', auc_null);
    fprintf('  H1: AUC = %.2f\n', auc_alt);
    fprintf('  Alpha: %.3f, Power: %.2f\n', alpha, power);
    fprintf('  Required n: %d total\n', n);
end

% Example: Need 80% power to detect AUC = 0.75 vs 0.5
n = sampleSizeBinary(0.5, 0.75, 0.05, 0.80);
```

### Calibration Assessment

```matlab
function calibrationPlot(YTrue, probabilities)
    % Calibration plot for probabilistic predictions

    % Bin predictions
    nBins = 10;
    edges = linspace(0, 1, nBins + 1);
    binCenters = (edges(1:end-1) + edges(2:end)) / 2;

    observedFreq = zeros(nBins, 1);
    expectedFreq = zeros(nBins, 1);
    binCounts = zeros(nBins, 1);

    for i = 1:nBins
        inBin = probabilities >= edges(i) & probabilities < edges(i+1);
        if any(inBin)
            observedFreq(i) = mean(YTrue(inBin));
            expectedFreq(i) = mean(probabilities(inBin));
            binCounts(i) = sum(inBin);
        end
    end

    % Plot
    figure;
    subplot(2,1,1);
    scatter(expectedFreq, observedFreq, 50 + binCounts, 'filled');
    hold on;
    plot([0 1], [0 1], 'k--', 'LineWidth', 2);
    xlabel('Mean Predicted Probability');
    ylabel('Observed Frequency');
    title('Calibration Plot');
    axis([0 1 0 1]);
    grid on;

    subplot(2,1,2);
    bar(binCenters, binCounts, 1);
    xlabel('Predicted Probability');
    ylabel('Count');
    title('Prediction Distribution');

    % Hosmer-Lemeshow statistic (informal)
    valid = binCounts > 0;
    HL_stat = sum(binCounts(valid) .* (observedFreq(valid) - expectedFreq(valid)).^2 ./ ...
        (expectedFreq(valid) .* (1 - expectedFreq(valid)) + eps));
    fprintf('Hosmer-Lemeshow statistic: %.2f\n', HL_stat);
end
```

## Best Practices

1. **Data Quality:**
   - Always check for missing values before modeling
   - Use appropriate imputation (KNN for biomedical data)
   - Document data preprocessing steps

2. **Class Imbalance:**
   - Report balanced accuracy, not just accuracy
   - Use cost-sensitive learning or resampling
   - AUC is often more informative than accuracy

3. **Validation:**
   - Use nested CV for unbiased estimates
   - Report confidence intervals, not just point estimates
   - External validation on independent dataset is gold standard

4. **Clinical Relevance:**
   - Report clinically meaningful metrics (sensitivity, specificity)
   - Consider clinical costs of false positives vs false negatives
   - Collaborate with domain experts for feature engineering

5. **Reproducibility:**
   - Set random seeds for reproducibility
   - Document all preprocessing steps
   - Save normalization parameters with model

## Common Pitfalls

| Pitfall | Solution |
|---------|----------|
| Data leakage | Fit preprocessing on training data only |
| Overfitting to imbalanced data | Use balanced metrics, cost-sensitive learning |
| Ignoring clinical context | Consult with clinicians on feature importance |
| Poor calibration | Use Platt scaling or isotonic regression |
| Single train-test split | Use nested cross-validation |
| Reporting only accuracy | Report sensitivity, specificity, AUC, and CIs |

---

*See also: classification.md for general classifiers, survival-analysis.md for time-to-event data*
