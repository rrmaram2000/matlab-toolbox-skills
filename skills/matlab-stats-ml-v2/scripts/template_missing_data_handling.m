%% Template: Missing Data Handling and Imputation for Clinical Data
% Detect, visualize, and impute missing values in clinical datasets.
% Uses fillmissing with 'knn' (NOT knnimpute — requires Bioinformatics
% Toolbox). Compares multiple imputation strategies and evaluates impact.
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
responseVar = '';       % TODO: Name of response variable (protected from imputation eval)
kNeighbors = 5;        % TODO: Number of neighbors for KNN imputation
movWindow = 5;         % TODO: Window size for moving average imputation

%% Step 1: Load data
data = readtable(dataPath);

% Identify numeric columns for analysis
numericVars = varfun(@isnumeric, data, 'OutputFormat', 'uniform');
numericNames = data.Properties.VariableNames(numericVars);
XRaw = table2array(data(:, numericVars));

fprintf('Dataset: %d observations, %d variables (%d numeric)\n', ...
    height(data), width(data), numel(numericNames));

%% Step 2: Missing data detection and summary
missingMask = ismissing(data);
totalMissing = sum(missingMask(:));
totalCells = numel(missingMask);

fprintf('\n--- Missing Data Summary ---\n');
fprintf('Total missing: %d / %d (%.2f%%)\n', ...
    totalMissing, totalCells, 100 * totalMissing / totalCells);

% Per-variable missing counts
fprintf('\n%-25s  Missing    Pct      Complete\n', 'Variable');
fprintf('%s\n', repmat('-', 1, 60));

for v = 1:numel(numericNames)
    nMiss = sum(isnan(XRaw(:, v)));
    pctMiss = 100 * nMiss / size(XRaw, 1);
    fprintf('%-25s  %-9d  %5.1f%%   %d\n', ...
        numericNames{v}, nMiss, pctMiss, size(XRaw, 1) - nMiss);
end

% Per-row missing counts
rowMissing = sum(isnan(XRaw), 2);
fprintf('\nRows with any missing: %d (%.1f%%)\n', ...
    sum(rowMissing > 0), 100 * mean(rowMissing > 0));
fprintf('Complete cases: %d\n', sum(rowMissing == 0));

%% Step 3: Missing data visualization
figure('Name', 'Missing Data Pattern', 'Position', [100 100 700 500]);

subplot(2, 2, 1);
bar(sum(isnan(XRaw)), 'FaceColor', [0.85 0.3 0.3]);
xticks(1:numel(numericNames));
xticklabels(numericNames);
xtickangle(45);
ylabel('Missing Count');
title('Missing Values per Variable');
grid on;

subplot(2, 2, 2);
histogram(rowMissing, 'FaceColor', [0.3 0.5 0.8]);
xlabel('Number of Missing Values per Row');
ylabel('Frequency');
title('Missing Values per Observation');
grid on;

subplot(2, 2, [3 4]);
imagesc(isnan(XRaw));
colormap([1 1 1; 0.85 0.3 0.3]);
xticks(1:numel(numericNames));
xticklabels(numericNames);
xtickangle(45);
ylabel('Observation');
title('Missing Data Pattern (red = missing)');
colorbar('Ticks', [0.25 0.75], 'TickLabels', {'Present', 'Missing'});

sgtitle('Missing Data Assessment');

%% Step 4: MCAR test (Little's test approximation)
% Compare means of observed data when another variable is missing vs not
fprintf('\n--- MCAR Assessment ---\n');
fprintf('Comparing distributions: observed when others are missing vs not\n');

nVars = numel(numericNames);
mcarFlags = true(1, nVars);

for v = 1:nVars
    otherMissing = any(isnan(XRaw(:, setdiff(1:nVars, v))), 2);
    observed = XRaw(~isnan(XRaw(:, v)), v);
    g1 = observed(otherMissing(~isnan(XRaw(:, v))));
    g2 = observed(~otherMissing(~isnan(XRaw(:, v))));

    if numel(g1) > 1 && numel(g2) > 1
        [~, p] = ttest2(g1, g2);
        if p < 0.05
            mcarFlags(v) = false;
            fprintf('%-25s  p=%.4f  (may NOT be MCAR)\n', numericNames{v}, p);
        end
    end
end

if all(mcarFlags)
    fprintf('All variables consistent with MCAR assumption\n');
end

%% Step 5: Imputation Method 1 — KNN
% NOTE: Use fillmissing(X, 'knn') — NOT knnimpute (requires Bioinformatics Toolbox)
XKnn = fillmissing(XRaw, 'knn', kNeighbors);
fprintf('\n--- KNN Imputation (k=%d) ---\n', kNeighbors);
fprintf('Remaining missing after KNN: %d\n', sum(isnan(XKnn(:))));

%% Step 6: Imputation Method 2 — Linear interpolation
XLinear = fillmissing(XRaw, 'linear');
fprintf('\n--- Linear Interpolation ---\n');
fprintf('Remaining missing: %d\n', sum(isnan(XLinear(:))));

%% Step 7: Imputation Method 3 — Moving mean
XMovMean = fillmissing(XRaw, 'movmean', movWindow);
fprintf('\n--- Moving Mean (window=%d) ---\n', movWindow);
fprintf('Remaining missing: %d\n', sum(isnan(XMovMean(:))));

%% Step 8: Imputation Method 4 — Column median
XMedian = fillmissing(XRaw, 'constant', 0);
for v = 1:size(XRaw, 2)
    medVal = median(XRaw(:, v), 'omitnan');
    XMedian(isnan(XRaw(:, v)), v) = medVal;
end
fprintf('\n--- Median Imputation ---\n');
fprintf('Remaining missing: %d\n', sum(isnan(XMedian(:))));

%% Step 9: Compare imputation methods — distribution preservation
figure('Name', 'Imputation Comparison', 'Position', [100 550 900 400]);

% Pick a variable with missing values for visualization
varWithMissing = find(any(isnan(XRaw)), 1);
if ~isempty(varWithMissing)
    vName = numericNames{varWithMissing};
    origData = XRaw(~isnan(XRaw(:, varWithMissing)), varWithMissing);

    subplot(1, 4, 1);
    histogram(origData, 20, 'FaceColor', [0.7 0.7 0.7]);
    title('Original (complete)'); xlabel(vName); grid on;

    subplot(1, 4, 2);
    histogram(XKnn(:, varWithMissing), 20, 'FaceColor', [0.3 0.5 0.8]);
    title('KNN Imputed'); xlabel(vName); grid on;

    subplot(1, 4, 3);
    histogram(XLinear(:, varWithMissing), 20, 'FaceColor', [0.3 0.7 0.4]);
    title('Linear Interp.'); xlabel(vName); grid on;

    subplot(1, 4, 4);
    histogram(XMedian(:, varWithMissing), 20, 'FaceColor', [0.8 0.5 0.3]);
    title('Median Imputed'); xlabel(vName); grid on;

    sgtitle(sprintf('Imputation Comparison — %s', vName));
end

%% Step 10: Evaluate imputation impact on downstream classification
if ~isempty(responseVar)
    Y = data.(responseVar);
    respIdx = strcmp(data.Properties.VariableNames, responseVar);
    numericNoResp = numericVars & ~respIdx;

    methods = {'Complete Cases', 'KNN', 'Linear', 'Median'};
    datasets = {XRaw, XKnn, XLinear, XMedian};
    accResults = zeros(1, 4);

    fprintf('\n--- Imputation Impact on Classification ---\n');
    for m = 1:4
        Xm = datasets{m};
        % Remove any remaining NaN rows
        validRows = ~any(isnan(Xm), 2) & ~ismissing(Y);
        if sum(validRows) < 10
            accResults(m) = NaN;
            continue;
        end
        mdl = fitcsvm(Xm(validRows, :), Y(validRows), ...
            'KernelFunction', 'rbf', 'Standardize', true);
        cvMdl = crossval(mdl, 'KFold', min(5, sum(validRows)));
        accResults(m) = 1 - kfoldLoss(cvMdl);
        fprintf('%-18s  N=%d  Accuracy=%.2f%%\n', ...
            methods{m}, sum(validRows), accResults(m) * 100);
    end
end

%% Step 11: Summary and recommendation
fprintf('\n--- Recommendation ---\n');
fprintf('For clinical data with arbitrary missing patterns:\n');
fprintf('  Primary:   fillmissing(X, ''knn'', k)  — preserves local structure\n');
fprintf('  Simple:    fillmissing(X, ''linear'')   — for ordered/time-series data\n');
fprintf('  Baseline:  Median imputation            — for heavily missing columns\n');
fprintf('  Avoid:     knnimpute (requires Bioinformatics Toolbox)\n');
