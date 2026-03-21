%% Template: Random Forest Ensemble for Biomarker Prediction
% Build random forest and boosted tree ensembles for biomarker-based
% outcome prediction. Includes feature importance, OOB error estimation,
% and comparison between bagging and boosting strategies.
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
nTrees = 200;          % TODO: Number of trees in ensemble
minLeafSize = 5;       % TODO: Minimum leaf size for trees
kFolds = 5;            % TODO: Number of cross-validation folds

%% Step 1: Load and prepare data
data = readtable(dataPath);

Y = data.(responseVar);
predictorNames = setdiff(data.Properties.VariableNames, {responseVar});
X = data(:, predictorNames);
X = table2array(X);

fprintf('Dataset: %d samples, %d features\n', size(X, 1), size(X, 2));

%% Step 2: Train random forest (bagged ensemble)
treeTemplate = templateTree('MinLeafSize', minLeafSize);

rfModel = fitcensemble(X, Y, ...
    'Method', 'Bag', ...
    'NumLearningCycles', nTrees, ...
    'Learners', treeTemplate);

fprintf('Random forest trained with %d trees\n', nTrees);

%% Step 3: Out-of-bag error estimation
oobErr = oobLoss(rfModel);
fprintf('OOB classification error: %.4f (accuracy: %.2f%%)\n', ...
    oobErr, (1 - oobErr) * 100);

% Plot OOB error vs number of trees
figure('Name', 'OOB Error Convergence', 'Position', [100 100 550 400]);
oobErrorTrace = oobLoss(rfModel, 'Mode', 'cumulative');
plot(oobErrorTrace, 'b-', 'LineWidth', 1.5);
xlabel('Number of Trees');
ylabel('OOB Classification Error');
title('Random Forest OOB Error Convergence');
grid on;

%% Step 4: Feature importance
imp = predictorImportance(rfModel);

[sortedImp, sortIdx] = sort(imp, 'descend');
topN = min(15, numel(sortedImp));

figure('Name', 'Feature Importance', 'Position', [700 100 550 400]);
barh(sortedImp(topN:-1:1));
yticks(1:topN);
yticklabels(predictorNames(sortIdx(topN:-1:1)));
xlabel('Predictor Importance');
title('Top Biomarker Importance (Random Forest)');
grid on;

fprintf('\n--- Top %d Features ---\n', topN);
for i = 1:topN
    fprintf('%2d. %-25s  Importance: %.4f\n', i, ...
        predictorNames{sortIdx(i)}, sortedImp(i));
end

%% Step 5: Cross-validation of random forest
cvRF = crossval(rfModel, 'KFold', kFolds);
rfCVLoss = kfoldLoss(cvRF);
fprintf('\nRandom Forest %d-fold CV accuracy: %.2f%%\n', kFolds, (1 - rfCVLoss) * 100);

%% Step 6: Train boosted tree ensemble for comparison
boostModel = fitcensemble(X, Y, ...
    'Method', 'AdaBoostM1', ...
    'NumLearningCycles', nTrees, ...
    'Learners', treeTemplate, ...
    'LearnRate', 0.1);

cvBoost = crossval(boostModel, 'KFold', kFolds);
boostCVLoss = kfoldLoss(cvBoost);
fprintf('Boosted Trees %d-fold CV accuracy: %.2f%%\n', kFolds, (1 - boostCVLoss) * 100);

%% Step 7: Compare ensemble methods
fprintf('\n--- Ensemble Comparison ---\n');
fprintf('%-20s CV Accuracy\n', 'Method');
fprintf('%-20s %.2f%%\n', 'Random Forest (Bag)', (1 - rfCVLoss) * 100);
fprintf('%-20s %.2f%%\n', 'AdaBoost', (1 - boostCVLoss) * 100);

%% Step 8: Predict on new data (template)
% newData = [];  % TODO: New patient biomarker data (same features as X)
% [label, score] = predict(rfModel, newData);
% fprintf('Predicted class: %s (score: %.3f)\n', string(label), max(score));

%% Step 9: Confusion matrix on training data
predictions = predict(rfModel, X);

figure('Name', 'RF Confusion Matrix', 'Position', [100 550 450 400]);
confusionchart(Y, predictions, ...
    'Title', 'Random Forest — Resubstitution', ...
    'RowSummary', 'row-normalized', ...
    'ColumnSummary', 'column-normalized');
