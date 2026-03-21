%% Template: SVM Classification for Patient Diagnosis
% Train a Support Vector Machine to classify patients (e.g., disease vs
% healthy) using clinical features. Includes kernel tuning, cross-validation,
% ROC curve analysis, and confusion matrix visualization.
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
responseVar = '';       % TODO: Name of response/target variable (e.g., 'Diagnosis')
positiveClass = '';     % TODO: Positive class label (e.g., 'Disease' or 1)
kFolds = 5;            % TODO: Number of cross-validation folds
kernelFunction = 'rbf'; % TODO: 'linear', 'rbf', 'polynomial'

%% Step 1: Load and prepare data
% Load dataset — adjust the loader to match your file format
data = readtable(dataPath);

% Separate predictors and response
Y = data.(responseVar);
X = data(:, setdiff(data.Properties.VariableNames, {responseVar}));
X = table2array(X);

% Standardize features for SVM
[X, mu, sigma] = zscore(X);

fprintf('Dataset: %d samples, %d features\n', size(X, 1), size(X, 2));
fprintf('Class distribution:\n');
tabulate(Y);

%% Step 2: Train SVM classifier
svmModel = fitcsvm(X, Y, ...
    'KernelFunction', kernelFunction, ...
    'BoxConstraint', 1, ...
    'Standardize', false, ...  % Already standardized above
    'ClassNames', categories(categorical(Y)));

fprintf('Trained SVM with %s kernel\n', kernelFunction);
fprintf('Number of support vectors: %d\n', sum(svmModel.IsSupportVector));

%% Step 3: Cross-validation evaluation
cvModel = crossval(svmModel, 'KFold', kFolds);
cvLoss = kfoldLoss(cvModel);
cvAccuracy = 1 - cvLoss;

fprintf('\n--- %d-Fold Cross-Validation ---\n', kFolds);
fprintf('Accuracy: %.2f%%\n', cvAccuracy * 100);
fprintf('Error rate: %.4f\n', cvLoss);

%% Step 4: Generate predictions and scores for ROC
% Fit posterior probabilities via Platt scaling
svmModelScored = fitPosterior(svmModel);
[~, scores] = resubPredict(svmModelScored);

%% Step 5: ROC curve analysis
[rocX, rocY, rocT, auc] = perfcurve(Y, scores(:, 2), positiveClass);

figure('Name', 'ROC Curve', 'Position', [100 100 500 450]);
plot(rocX, rocY, 'b-', 'LineWidth', 2);
hold on;
plot([0 1], [0 1], 'k--', 'LineWidth', 1);
hold off;
xlabel('False Positive Rate');
ylabel('True Positive Rate');
title(sprintf('ROC Curve (AUC = %.3f)', auc));
legend('SVM Classifier', 'Random', 'Location', 'southeast');
grid on;

%% Step 6: Confusion matrix
predictions = resubPredict(svmModel);

figure('Name', 'Confusion Matrix', 'Position', [650 100 450 400]);
confusionchart(Y, predictions, ...
    'Title', 'SVM Classification Results', ...
    'RowSummary', 'row-normalized', ...
    'ColumnSummary', 'column-normalized');

%% Step 7: Compute detailed performance metrics
cm = confusionmat(Y, predictions);
TP = cm(2, 2); FP = cm(1, 2); FN = cm(2, 1); TN = cm(1, 1);

sensitivity = TP / (TP + FN);
specificity = TN / (TN + FP);
precision = TP / (TP + FP);
f1Score = 2 * (precision * sensitivity) / (precision + sensitivity);

fprintf('\n--- Performance Metrics ---\n');
fprintf('Sensitivity (Recall): %.3f\n', sensitivity);
fprintf('Specificity:          %.3f\n', specificity);
fprintf('Precision:            %.3f\n', precision);
fprintf('F1 Score:             %.3f\n', f1Score);
fprintf('AUC:                  %.3f\n', auc);

%% Step 8: Compare kernels (optional)
kernels = {'linear', 'rbf', 'polynomial'};
kernelAUC = zeros(1, numel(kernels));

for k = 1:numel(kernels)
    mdl = fitcsvm(X, Y, 'KernelFunction', kernels{k}, 'Standardize', false);
    mdl = fitPosterior(mdl);
    [~, sc] = resubPredict(mdl);
    [~, ~, ~, kernelAUC(k)] = perfcurve(Y, sc(:, 2), positiveClass);
end

fprintf('\n--- Kernel Comparison ---\n');
for k = 1:numel(kernels)
    fprintf('%-12s AUC = %.3f\n', kernels{k}, kernelAUC(k));
end
