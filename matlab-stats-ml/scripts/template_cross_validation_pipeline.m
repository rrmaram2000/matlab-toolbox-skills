%% Template: K-Fold Cross-Validation Pipeline with Comprehensive Metrics
% Stratified k-fold cross-validation with per-fold metrics including
% accuracy, sensitivity, specificity, and AUC. Compares multiple
% classifiers (SVM, Random Forest, KNN, Decision Tree) side by side.
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
responseVar = '';       % TODO: Name of response/target variable
positiveClass = '';     % TODO: Positive class label for ROC
kFolds = 10;           % TODO: Number of cross-validation folds

%% Step 1: Load and prepare data
data = readtable(dataPath);

Y = data.(responseVar);
predictorNames = setdiff(data.Properties.VariableNames, {responseVar});
X = table2array(data(:, predictorNames));

[X, mu, sigma] = zscore(X);
fprintf('Dataset: %d samples, %d features, %d-fold CV\n', ...
    size(X, 1), size(X, 2), kFolds);

%% Step 2: Create stratified partition
cv = cvpartition(Y, 'KFold', kFolds, 'Stratify', true);

%% Step 3: Define classifiers to compare
classifierNames = {'SVM (RBF)', 'Random Forest', 'KNN (k=5)', 'Decision Tree'};
nClassifiers = numel(classifierNames);

%% Step 4: Initialize metric storage
metrics = struct();
metricFields = {'Accuracy', 'Sensitivity', 'Specificity', 'Precision', 'F1', 'AUC'};
for m = 1:numel(metricFields)
    metrics.(metricFields{m}) = zeros(kFolds, nClassifiers);
end

%% Step 5: Run cross-validation loop
fprintf('\nRunning %d-fold cross-validation...\n', kFolds);

for fold = 1:kFolds
    trainIdx = training(cv, fold);
    testIdx  = test(cv, fold);

    XTrain = X(trainIdx, :);  YTrain = Y(trainIdx);
    XTest  = X(testIdx, :);   YTest  = Y(testIdx);

    for c = 1:nClassifiers
        % Train classifier
        switch c
            case 1  % SVM
                mdl = fitcsvm(XTrain, YTrain, ...
                    'KernelFunction', 'rbf', 'Standardize', false);
                mdl = fitPosterior(mdl);
            case 2  % Random Forest
                mdl = fitcensemble(XTrain, YTrain, ...
                    'Method', 'Bag', 'NumLearningCycles', 100, ...
                    'Learners', templateTree('MinLeafSize', 5));
            case 3  % KNN
                mdl = fitcknn(XTrain, YTrain, 'NumNeighbors', 5);
            case 4  % Decision Tree
                mdl = fitctree(XTrain, YTrain, 'MinLeafSize', 5);
        end

        % Predict
        [yPred, scores] = predict(mdl, XTest);

        % Confusion matrix elements
        cm = confusionmat(YTest, yPred);
        TP = cm(2, 2); FP = cm(1, 2);
        FN = cm(2, 1); TN = cm(1, 1);

        % Compute metrics
        metrics.Accuracy(fold, c) = (TP + TN) / sum(cm(:));
        metrics.Sensitivity(fold, c) = TP / max(TP + FN, 1);
        metrics.Specificity(fold, c) = TN / max(TN + FP, 1);
        metrics.Precision(fold, c) = TP / max(TP + FP, 1);

        prec = metrics.Precision(fold, c);
        sens = metrics.Sensitivity(fold, c);
        metrics.F1(fold, c) = 2 * (prec * sens) / max(prec + sens, eps);

        % AUC
        [~, ~, ~, aucVal] = perfcurve(YTest, scores(:, 2), positiveClass);
        metrics.AUC(fold, c) = aucVal;
    end

    fprintf('  Fold %2d/%d complete\n', fold, kFolds);
end

%% Step 6: Aggregate and display results
fprintf('\n========================================\n');
fprintf('  Cross-Validation Results (%d folds)\n', kFolds);
fprintf('========================================\n\n');

fprintf('%-18s', 'Metric');
for c = 1:nClassifiers
    fprintf('%-18s', classifierNames{c});
end
fprintf('\n');
fprintf('%s\n', repmat('-', 1, 18 + 18 * nClassifiers));

for m = 1:numel(metricFields)
    fprintf('%-18s', metricFields{m});
    for c = 1:nClassifiers
        vals = metrics.(metricFields{m})(:, c);
        fprintf('%.3f +/- %.3f   ', mean(vals), std(vals));
    end
    fprintf('\n');
end

%% Step 7: Box plot comparison
figure('Name', 'Classifier Comparison', 'Position', [100 100 900 500]);
metricsToPlot = {'Accuracy', 'AUC', 'F1', 'Sensitivity'};

for p = 1:numel(metricsToPlot)
    subplot(2, 2, p);
    boxplot(metrics.(metricsToPlot{p}), classifierNames);
    ylabel(metricsToPlot{p});
    title(metricsToPlot{p});
    grid on;
    xtickangle(20);
end
sgtitle(sprintf('%d-Fold Cross-Validation Comparison', kFolds));

%% Step 8: ROC curves (using full resubstitution for visualization)
figure('Name', 'ROC Curves', 'Position', [100 550 550 450]);
hold on;
colors = lines(nClassifiers);

mdls = {
    fitcsvm(X, Y, 'KernelFunction', 'rbf', 'Standardize', false)
    fitcensemble(X, Y, 'Method', 'Bag', 'NumLearningCycles', 100)
    fitcknn(X, Y, 'NumNeighbors', 5)
    fitctree(X, Y, 'MinLeafSize', 5)
};
mdls{1} = fitPosterior(mdls{1});

for c = 1:nClassifiers
    [~, sc] = predict(mdls{c}, X);
    [rocX, rocY, ~, aucFull] = perfcurve(Y, sc(:, 2), positiveClass);
    plot(rocX, rocY, 'Color', colors(c, :), 'LineWidth', 2, ...
        'DisplayName', sprintf('%s (AUC=%.3f)', classifierNames{c}, aucFull));
end

plot([0 1], [0 1], 'k--', 'LineWidth', 1, 'DisplayName', 'Random');
hold off;
xlabel('False Positive Rate');
ylabel('True Positive Rate');
title('ROC Curve Comparison');
legend('Location', 'southeast');
grid on;

%% Step 9: Per-fold accuracy trace
figure('Name', 'Per-Fold Accuracy', 'Position', [700 550 500 350]);
plot(1:kFolds, metrics.Accuracy, '-o', 'LineWidth', 1.5);
xlabel('Fold');
ylabel('Accuracy');
title('Per-Fold Accuracy Across Classifiers');
legend(classifierNames, 'Location', 'best');
grid on;
xlim([0.5 kFolds + 0.5]);

%% Step 10: Summary — best classifier
meanAcc = mean(metrics.Accuracy, 1);
[bestAcc, bestC] = max(meanAcc);
fprintf('\nBest classifier: %s (mean accuracy: %.2f%%)\n', ...
    classifierNames{bestC}, bestAcc * 100);
