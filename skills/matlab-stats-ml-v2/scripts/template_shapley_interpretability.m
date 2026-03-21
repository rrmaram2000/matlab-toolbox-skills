%% Template: SHAP Values for Model Interpretability
% Compute Shapley values to explain classifier predictions for individual
% patients. Uses the shapley function (R2021b+) for feature attribution,
% with force plots, summary visualization, and comparison to traditional
% predictorImportance.
% MATLAB R2025b | Statistics and Machine Learning Toolbox
%
% Usage:
%   1. Fill in all TODO sections with your data
%   2. Run section-by-section or as complete script
%
% Requirements:
%   - Statistics and Machine Learning Toolbox (R2021b+)

%% TODO: Configure your data and parameters
dataPath = '';          % TODO: Path to your dataset (CSV, MAT, etc.)
responseVar = '';       % TODO: Name of response/target variable
queryIdx = 1;          % TODO: Index of patient to explain (individual prediction)
nTopFeatures = 10;     % TODO: Number of top features to display

%% Step 1: Load and prepare data
data = readtable(dataPath);

Y = data.(responseVar);
predictorNames = setdiff(data.Properties.VariableNames, {responseVar});
XTable = data(:, predictorNames);
X = table2array(XTable);

fprintf('Dataset: %d samples, %d features\n', size(X, 1), size(X, 2));

%% Step 2: Train ensemble classifier (for SHAP and importance)
rfModel = fitcensemble(XTable, Y, ...
    'Method', 'Bag', ...
    'NumLearningCycles', 100, ...
    'Learners', templateTree('MinLeafSize', 5));

cvModel = crossval(rfModel, 'KFold', 5);
cvAcc = 1 - kfoldLoss(cvModel);
fprintf('Random Forest CV accuracy: %.2f%%\n', cvAcc * 100);

%% Step 3: Compute SHAP values using shapley
fprintf('\nComputing Shapley values for patient %d...\n', queryIdx);

queryPoint = XTable(queryIdx, :);
explainer = shapley(rfModel, XTable, 'QueryPoint', queryPoint);

fprintf('Prediction for patient %d: %s\n', queryIdx, ...
    string(predict(rfModel, queryPoint)));

%% Step 4: Display SHAP values
shapValues = explainer.ShapleyValues;
fprintf('\n--- SHAP Values (Patient %d) ---\n', queryIdx);
fprintf('%-25s  SHAP Value    Feature Value\n', 'Feature');
fprintf('%s\n', repmat('-', 1, 60));

% Sort by absolute SHAP value
[~, sortIdx] = sort(abs(shapValues.ShapleyValue), 'descend');
nShow = min(nTopFeatures, height(shapValues));

for i = 1:nShow
    idx = sortIdx(i);
    fname = string(shapValues.Properties.RowNames(idx));
    sval = shapValues.ShapleyValue(idx);
    fval = X(queryIdx, strcmp(predictorNames, fname));
    fprintf('%-25s  %+.4f        %.3f\n', fname, sval, fval);
end

%% Step 5: SHAP bar plot (force plot style)
figure('Name', 'SHAP Feature Contributions', 'Position', [100 100 650 450]);

topIdx = sortIdx(1:nShow);
topNames = shapValues.Properties.RowNames(topIdx);
topValues = shapValues.ShapleyValue(topIdx);

barColors = zeros(nShow, 3);
barColors(topValues > 0, :) = repmat([0.85 0.3 0.3], sum(topValues > 0), 1);
barColors(topValues <= 0, :) = repmat([0.3 0.5 0.85], sum(topValues <= 0), 1);

barh(nShow:-1:1, topValues);
hold on;
for i = 1:nShow
    barh(nShow - i + 1, topValues(i), 'FaceColor', barColors(i, :));
end
hold off;
yticks(1:nShow);
yticklabels(topNames(end:-1:1));
xlabel('SHAP Value (impact on prediction)');
title(sprintf('Feature Contributions — Patient %d', queryIdx));
xline(0, 'k-', 'LineWidth', 1);
grid on;

%% Step 6: Compute SHAP for multiple patients (global importance)
fprintf('\nComputing SHAP values across all patients...\n');

nSamples = min(50, size(X, 1));  % Limit for computation time
sampleIdx = randsample(size(X, 1), nSamples);
allSHAP = zeros(nSamples, numel(predictorNames));

for i = 1:nSamples
    qp = XTable(sampleIdx(i), :);
    exp_i = shapley(rfModel, XTable, 'QueryPoint', qp);
    allSHAP(i, :) = exp_i.ShapleyValues.ShapleyValue';

    if mod(i, 10) == 0
        fprintf('  Processed %d/%d patients\n', i, nSamples);
    end
end

%% Step 7: Global SHAP importance (mean absolute SHAP)
meanAbsSHAP = mean(abs(allSHAP), 1);
[sortedSHAP, globalSortIdx] = sort(meanAbsSHAP, 'descend');

figure('Name', 'Global SHAP Importance', 'Position', [100 550 600 400]);
nGlobal = min(nTopFeatures, numel(predictorNames));
barh(nGlobal:-1:1, sortedSHAP(1:nGlobal), 'FaceColor', [0.4 0.6 0.8]);
yticks(1:nGlobal);
yticklabels(predictorNames(globalSortIdx(nGlobal:-1:1)));
xlabel('Mean |SHAP Value|');
title('Global Feature Importance (SHAP)');
grid on;

%% Step 8: SHAP summary plot (beeswarm style)
figure('Name', 'SHAP Summary', 'Position', [750 100 600 450]);
topGlobalIdx = globalSortIdx(1:nGlobal);

for f = 1:nGlobal
    fIdx = topGlobalIdx(f);
    yPos = nGlobal - f + 1;
    fVals = X(sampleIdx, fIdx);
    fNorm = (fVals - min(fVals)) / max(range(fVals), eps);

    scatter(allSHAP(:, fIdx), ...
        yPos + 0.3 * (rand(nSamples, 1) - 0.5), ...
        20, fNorm, 'filled', 'MarkerFaceAlpha', 0.6);
end

colormap(flipud(cool));
cb = colorbar;
cb.Label.String = 'Feature Value (normalized)';
yticks(1:nGlobal);
yticklabels(predictorNames(topGlobalIdx(end:-1:1)));
xlabel('SHAP Value');
title('SHAP Summary Plot');
xline(0, 'k--');
grid on;

%% Step 9: Compare with traditional feature importance
imp = predictorImportance(rfModel);
[sortedImp, impSortIdx] = sort(imp, 'descend');

fprintf('\n--- Importance Comparison (Top %d) ---\n', nGlobal);
fprintf('%-5s  %-25s  SHAP     %-25s  Traditional\n', 'Rank', 'Feature (SHAP)', 'Feature (Traditional)');
fprintf('%s\n', repmat('-', 1, 90));

for i = 1:nGlobal
    fprintf('%-5d  %-25s  %.4f   %-25s  %.4f\n', i, ...
        predictorNames{globalSortIdx(i)}, sortedSHAP(i), ...
        predictorNames{impSortIdx(i)}, sortedImp(i));
end

%% Step 10: SHAP dependence plot for top feature
topFeature = globalSortIdx(1);

figure('Name', 'SHAP Dependence', 'Position', [750 550 500 400]);
scatter(X(sampleIdx, topFeature), allSHAP(:, topFeature), ...
    40, 'filled', 'MarkerFaceAlpha', 0.6);
xlabel(predictorNames{topFeature});
ylabel('SHAP Value');
title(sprintf('SHAP Dependence — %s', predictorNames{topFeature}));
grid on;
yline(0, 'k--');

lsline;
