%% Template: K-Means Patient Stratification and Clustering
% Cluster patients into subgroups using k-means, evaluate optimal k with
% silhouette analysis and evalclusters, and compare with hierarchical
% clustering. Visualize clusters in PCA-reduced space.
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
kRange = 2:8;          % TODO: Range of cluster numbers to evaluate
kFinal = 3;            % TODO: Final number of clusters (set after evaluation)
nReplicates = 10;      % TODO: Number of k-means replicates for stability
distanceMetric = 'sqeuclidean'; % TODO: 'sqeuclidean', 'cityblock', 'cosine'

%% Step 1: Load and prepare data
data = readtable(dataPath);

% Select numeric features only
numericVars = varfun(@isnumeric, data, 'OutputFormat', 'uniform');
X = table2array(data(:, numericVars));
featureNames = data.Properties.VariableNames(numericVars);

% Remove rows with NaN
nanRows = any(isnan(X), 2);
if any(nanRows)
    fprintf('Removing %d rows with missing values\n', sum(nanRows));
    X(nanRows, :) = [];
end

% Standardize features
[XStd, mu, sigma] = zscore(X);
fprintf('Dataset: %d samples, %d features\n', size(XStd, 1), size(XStd, 2));

%% Step 2: Determine optimal k using silhouette analysis
silScores = zeros(1, numel(kRange));

figure('Name', 'Silhouette Analysis', 'Position', [100 100 900 350]);
for i = 1:numel(kRange)
    k = kRange(i);
    [idx, ~] = kmeans(XStd, k, ...
        'Distance', distanceMetric, ...
        'Replicates', nReplicates, ...
        'MaxIter', 200);
    s = silhouette(XStd, idx, distanceMetric);
    silScores(i) = mean(s);
end

plot(kRange, silScores, 'bo-', 'LineWidth', 2, 'MarkerSize', 8);
xlabel('Number of Clusters (k)');
ylabel('Mean Silhouette Score');
title('Optimal k Selection — Silhouette Analysis');
grid on;

[bestSil, bestIdx] = max(silScores);
fprintf('Best k by silhouette: %d (score: %.3f)\n', kRange(bestIdx), bestSil);

%% Step 3: Evaluate with multiple criteria using evalclusters
evalSil = evalclusters(XStd, 'kmeans', 'silhouette', 'KList', kRange);
evalCH  = evalclusters(XStd, 'kmeans', 'CalinskiHarabasz', 'KList', kRange);
evalDB  = evalclusters(XStd, 'kmeans', 'DaviesBouldin', 'KList', kRange);

fprintf('\n--- Optimal k by Criterion ---\n');
fprintf('Silhouette:        k = %d\n', evalSil.OptimalK);
fprintf('Calinski-Harabasz: k = %d\n', evalCH.OptimalK);
fprintf('Davies-Bouldin:    k = %d\n', evalDB.OptimalK);

%% Step 4: Final k-means clustering
[clusterIdx, centroids, sumD] = kmeans(XStd, kFinal, ...
    'Distance', distanceMetric, ...
    'Replicates', nReplicates, ...
    'MaxIter', 300, ...
    'Display', 'final');

fprintf('\n--- K-Means (k=%d) Results ---\n', kFinal);
for c = 1:kFinal
    nMembers = sum(clusterIdx == c);
    fprintf('Cluster %d: %d patients (%.1f%%)\n', c, nMembers, ...
        100 * nMembers / numel(clusterIdx));
end

%% Step 5: Silhouette plot for final clustering
figure('Name', 'Silhouette Plot', 'Position', [100 500 500 400]);
silhouette(XStd, clusterIdx, distanceMetric);
title(sprintf('Silhouette Plot (k = %d)', kFinal));

%% Step 6: Visualize clusters in PCA space
[~, pcaScores] = pca(XStd);

figure('Name', 'Clusters in PCA Space', 'Position', [650 100 550 450]);
gscatter(pcaScores(:, 1), pcaScores(:, 2), clusterIdx, lines(kFinal), 'o', 8);
hold on;
% Project centroids into PCA space
[~, ~, ~, ~, ~, mu_pca] = pca(XStd);
centroidsPCA = (centroids - mu_pca) * (pcaScores \ XStd)';  % approximate
hold off;
xlabel('PC1'); ylabel('PC2');
title('Patient Clusters in PCA Space');
legend(arrayfun(@(c) sprintf('Cluster %d', c), 1:kFinal, 'UniformOutput', false));
grid on;

%% Step 7: Cluster summary statistics
fprintf('\n--- Cluster Feature Means (Original Scale) ---\n');
fprintf('%-20s', 'Feature');
for c = 1:kFinal
    fprintf('Cluster %-5d', c);
end
fprintf('\n');

for f = 1:min(10, numel(featureNames))
    fprintf('%-20s', featureNames{f});
    for c = 1:kFinal
        clusterMean = mean(X(clusterIdx == c, f));
        fprintf('%-13.3f', clusterMean);
    end
    fprintf('\n');
end

%% Step 8: Hierarchical clustering comparison
Z = linkage(XStd, 'ward', 'euclidean');

figure('Name', 'Dendrogram', 'Position', [650 500 550 400]);
dendrogram(Z, 30);
title('Hierarchical Clustering Dendrogram');
xlabel('Sample Index');
ylabel('Distance');

hierIdx = cluster(Z, 'MaxClust', kFinal);

% Agreement between k-means and hierarchical
agreement = sum(clusterIdx == hierIdx) / numel(clusterIdx);
fprintf('\nK-means vs Hierarchical cluster agreement: %.1f%%\n', agreement * 100);

%% Step 9: Elbow method (within-cluster sum of squares)
wcss = zeros(1, numel(kRange));
for i = 1:numel(kRange)
    [~, ~, sumd] = kmeans(XStd, kRange(i), ...
        'Replicates', nReplicates, 'Distance', distanceMetric);
    wcss(i) = sum(sumd);
end

figure('Name', 'Elbow Plot', 'Position', [100 100 500 350]);
plot(kRange, wcss, 'ro-', 'LineWidth', 2, 'MarkerSize', 8);
xlabel('Number of Clusters (k)');
ylabel('Total Within-Cluster Sum of Squares');
title('Elbow Method');
grid on;
