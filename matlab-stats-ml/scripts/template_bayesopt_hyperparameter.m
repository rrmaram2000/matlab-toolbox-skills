%% Template: Bayesian Hyperparameter Optimization for Classifiers
% Use bayesopt to automatically tune SVM and ensemble model parameters.
% Defines optimizable variable ranges, custom objective functions with
% cross-validated loss, and visualizes the optimization process.
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
kFolds = 5;            % TODO: Number of CV folds for objective function
maxEvals = 30;         % TODO: Maximum number of bayesopt evaluations

%% Step 1: Load and prepare data
data = readtable(dataPath);

Y = data.(responseVar);
predictorNames = setdiff(data.Properties.VariableNames, {responseVar});
X = table2array(data(:, predictorNames));

% Standardize
[X, mu, sigma] = zscore(X);

fprintf('Dataset: %d samples, %d features\n', size(X, 1), size(X, 2));
fprintf('Bayesian optimization: up to %d evaluations\n', maxEvals);

%% Step 2: Define optimizable variables for SVM
svmVars = [
    optimizableVariable('BoxConstraint', [1e-3, 1e3], 'Transform', 'log')
    optimizableVariable('KernelScale',   [1e-3, 1e3], 'Transform', 'log')
    optimizableVariable('KernelFunction', {'linear', 'rbf', 'polynomial'})
];

%% Step 3: Custom objective function for SVM
svmObjective = @(params) svmCVLoss(params, X, Y, kFolds);

function loss = svmCVLoss(params, X, Y, kFolds)
    mdl = fitcsvm(X, Y, ...
        'BoxConstraint', params.BoxConstraint, ...
        'KernelScale', params.KernelScale, ...
        'KernelFunction', char(params.KernelFunction), ...
        'Standardize', false);
    cvMdl = crossval(mdl, 'KFold', kFolds);
    loss = kfoldLoss(cvMdl);
end

%% Step 4: Run Bayesian optimization for SVM
fprintf('\n--- Optimizing SVM ---\n');
svmResults = bayesopt(svmObjective, svmVars, ...
    'MaxObjectiveEvaluations', maxEvals, ...
    'AcquisitionFunctionName', 'expected-improvement-plus', ...
    'Verbose', 1, ...
    'PlotFcn', {@plotObjectiveModel, @plotMinObjective});

% Best SVM parameters
bestSVM = bestPoint(svmResults);
fprintf('\nBest SVM parameters:\n');
disp(bestSVM);
fprintf('Best CV loss: %.4f (accuracy: %.2f%%)\n', ...
    svmResults.MinObjective, (1 - svmResults.MinObjective) * 100);

%% Step 5: Train final SVM with best parameters
finalSVM = fitcsvm(X, Y, ...
    'BoxConstraint', bestSVM.BoxConstraint, ...
    'KernelScale', bestSVM.KernelScale, ...
    'KernelFunction', char(bestSVM.KernelFunction), ...
    'Standardize', false);

fprintf('Final SVM trained with %d support vectors\n', sum(finalSVM.IsSupportVector));

%% Step 6: Define optimizable variables for ensemble
ensVars = [
    optimizableVariable('NumLearningCycles', [50, 500], 'Type', 'integer')
    optimizableVariable('LearnRate', [0.001, 1], 'Transform', 'log')
    optimizableVariable('MinLeafSize', [1, 50], 'Type', 'integer')
    optimizableVariable('Method', {'Bag', 'AdaBoostM1'})
];

%% Step 7: Custom objective function for ensemble
ensObjective = @(params) ensembleCVLoss(params, X, Y, kFolds);

function loss = ensembleCVLoss(params, X, Y, kFolds)
    treeTempl = templateTree('MinLeafSize', params.MinLeafSize);
    if strcmp(char(params.Method), 'Bag')
        mdl = fitcensemble(X, Y, ...
            'Method', 'Bag', ...
            'NumLearningCycles', params.NumLearningCycles, ...
            'Learners', treeTempl);
    else
        mdl = fitcensemble(X, Y, ...
            'Method', char(params.Method), ...
            'NumLearningCycles', params.NumLearningCycles, ...
            'Learners', treeTempl, ...
            'LearnRate', params.LearnRate);
    end
    cvMdl = crossval(mdl, 'KFold', kFolds);
    loss = kfoldLoss(cvMdl);
end

%% Step 8: Run Bayesian optimization for ensemble
fprintf('\n--- Optimizing Ensemble ---\n');
ensResults = bayesopt(ensObjective, ensVars, ...
    'MaxObjectiveEvaluations', maxEvals, ...
    'AcquisitionFunctionName', 'expected-improvement-plus', ...
    'Verbose', 1, ...
    'PlotFcn', {@plotMinObjective});

bestEns = bestPoint(ensResults);
fprintf('\nBest Ensemble parameters:\n');
disp(bestEns);
fprintf('Best CV loss: %.4f (accuracy: %.2f%%)\n', ...
    ensResults.MinObjective, (1 - ensResults.MinObjective) * 100);

%% Step 9: Compare optimized models
fprintf('\n--- Comparison of Optimized Models ---\n');
fprintf('%-20s  CV Loss    Accuracy\n', 'Model');
fprintf('%-20s  %.4f     %.2f%%\n', 'SVM', ...
    svmResults.MinObjective, (1 - svmResults.MinObjective) * 100);
fprintf('%-20s  %.4f     %.2f%%\n', 'Ensemble', ...
    ensResults.MinObjective, (1 - ensResults.MinObjective) * 100);

%% Step 10: Optimization trace comparison
figure('Name', 'Optimization Trace', 'Position', [100 100 600 400]);
hold on;
plot(1:height(svmResults.ObjectiveTrace), ...
    cummin(svmResults.ObjectiveTrace), 'b-', 'LineWidth', 2);
plot(1:height(ensResults.ObjectiveTrace), ...
    cummin(ensResults.ObjectiveTrace), 'r-', 'LineWidth', 2);
hold off;
xlabel('Evaluation Number');
ylabel('Best Objective (CV Loss)');
title('Bayesian Optimization Convergence');
legend('SVM', 'Ensemble', 'Location', 'northeast');
grid on;
