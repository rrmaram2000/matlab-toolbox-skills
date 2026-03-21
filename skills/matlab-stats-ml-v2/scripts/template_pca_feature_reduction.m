%% Template: PCA Feature Reduction for High-Dimensional Biomedical Data
% Perform Principal Component Analysis on high-dimensional data such as
% genomics, radiomics, or multi-modal clinical features. Includes scree
% plots, biplots, variance thresholds, and t-SNE comparison.
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
responseVar = '';       % TODO: Name of label/group variable (for coloring)
varianceThreshold = 95; % TODO: Cumulative variance % to retain (e.g., 95)
nComponentsPlot = 3;   % TODO: Number of PC components to visualize

%% Step 1: Load and prepare data
data = readtable(dataPath);

Y = data.(responseVar);
predictorNames = setdiff(data.Properties.VariableNames, {responseVar});
X = table2array(data(:, predictorNames));

% Handle any NaN values before PCA
if any(isnan(X), 'all')
    fprintf('Warning: %d missing values detected. Filling with column median.\n', ...
        sum(isnan(X), 'all'));
    X = fillmissing(X, 'movmedian', size(X, 1));
end

fprintf('Dataset: %d samples, %d features\n', size(X, 1), size(X, 2));

%% Step 2: Standardize features
[XStd, mu, sigma] = zscore(X);

%% Step 3: Perform PCA
[coeff, score, latent, ~, explained, mu_pca] = pca(XStd);

fprintf('\n--- PCA Results ---\n');
cumExplained = cumsum(explained);
nRetained = find(cumExplained >= varianceThreshold, 1, 'first');
fprintf('Components to explain %.0f%% variance: %d (of %d)\n', ...
    varianceThreshold, nRetained, size(X, 2));

%% Step 4: Scree plot
figure('Name', 'Scree Plot', 'Position', [100 100 600 400]);
nShow = min(20, numel(explained));

yyaxis left;
bar(1:nShow, explained(1:nShow), 'FaceColor', [0.3 0.5 0.9]);
ylabel('Variance Explained (%)');

yyaxis right;
plot(1:nShow, cumExplained(1:nShow), 'r-o', 'LineWidth', 2, 'MarkerSize', 6);
ylabel('Cumulative Variance (%)');
yline(varianceThreshold, 'k--', sprintf('%d%%', varianceThreshold), ...
    'LineWidth', 1.5, 'LabelHorizontalAlignment', 'left');

xlabel('Principal Component');
title('PCA Scree Plot');
grid on;

%% Step 5: 2D scatter in PC space
figure('Name', 'PCA Scatter', 'Position', [750 100 550 450]);
gscatter(score(:, 1), score(:, 2), Y);
xlabel(sprintf('PC1 (%.1f%%)', explained(1)));
ylabel(sprintf('PC2 (%.1f%%)', explained(2)));
title('Patient Distribution in PCA Space');
grid on;

%% Step 6: 3D PCA visualization (if >= 3 components)
if nComponentsPlot >= 3 && size(score, 2) >= 3
    figure('Name', 'PCA 3D', 'Position', [100 550 550 450]);
    groups = unique(Y);
    colors = lines(numel(groups));
    hold on;
    for g = 1:numel(groups)
        mask = (Y == groups(g)) | strcmp(string(Y), string(groups(g)));
        scatter3(score(mask, 1), score(mask, 2), score(mask, 3), ...
            30, colors(g, :), 'filled', 'MarkerFaceAlpha', 0.7);
    end
    hold off;
    xlabel(sprintf('PC1 (%.1f%%)', explained(1)));
    ylabel(sprintf('PC2 (%.1f%%)', explained(2)));
    zlabel(sprintf('PC3 (%.1f%%)', explained(3)));
    title('3D PCA Projection');
    legend(string(groups), 'Location', 'best');
    grid on; view(45, 30);
end

%% Step 7: Biplot of top features
figure('Name', 'PCA Biplot', 'Position', [700 550 550 450]);
topIdx = 1:min(10, numel(predictorNames));
biplot(coeff(topIdx, 1:2), ...
    'Scores', score(:, 1:2), ...
    'VarLabels', predictorNames(topIdx));
title('PCA Biplot (Top Features)');

%% Step 8: Project new data using retained components
% XNew = [];  % TODO: New data matrix (same features)
% XNewStd = (XNew - mu) ./ sigma;
% scoreNew = (XNewStd - mu_pca) * coeff(:, 1:nRetained);

fprintf('\n--- Projection Template ---\n');
fprintf('Retained components: %d\n', nRetained);
fprintf('Dimensionality reduction: %d -> %d (%.1fx)\n', ...
    size(X, 2), nRetained, size(X, 2) / nRetained);

%% Step 9: t-SNE comparison
fprintf('\nComputing t-SNE embedding...\n');
tsneResult = tsne(XStd, 'Perplexity', 30, 'NumDimensions', 2);

figure('Name', 't-SNE vs PCA', 'Position', [100 100 1100 400]);
subplot(1, 2, 1);
gscatter(score(:, 1), score(:, 2), Y);
xlabel('PC1'); ylabel('PC2');
title('PCA Projection'); grid on;

subplot(1, 2, 2);
gscatter(tsneResult(:, 1), tsneResult(:, 2), Y);
xlabel('t-SNE 1'); ylabel('t-SNE 2');
title('t-SNE Projection'); grid on;

sgtitle('PCA vs t-SNE Comparison');

%% Step 10: Top loading features per component
fprintf('\n--- Top Loadings per Component ---\n');
for pc = 1:min(3, size(coeff, 2))
    [~, loadIdx] = sort(abs(coeff(:, pc)), 'descend');
    fprintf('PC%d: ', pc);
    for j = 1:min(5, numel(loadIdx))
        fprintf('%s (%.3f)  ', predictorNames{loadIdx(j)}, coeff(loadIdx(j), pc));
    end
    fprintf('\n');
end
