# Clustering

Clustering groups similar observations without predefined labels. This card covers k-means, hierarchical, Gaussian mixture models, density-based, and spectral clustering with biomedical applications.

## Algorithm Selection Guide

```
What kind of clusters?
├── Spherical, similar size → kmeans
├── Unknown number of clusters
│   ├── Density-based → dbscan (also handles noise)
│   └── Hierarchical → linkage + cluster (inspect dendrogram)
├── Soft assignments (probabilities) → fitgmdist (GMM)
├── Arbitrary shapes → dbscan or spectralcluster
├── Need hierarchy/tree structure → linkage
├── Graph/network data → spectralcluster
└── Very large datasets → kmeans with 'OnlinePhase' or mini-batch
```

## K-Means Clustering

### Basic K-Means

```matlab
% Simple k-means
k = 3;
[idx, C, sumd, D] = kmeans(X, k);

% idx: cluster assignments (1 to k)
% C: cluster centroids (k × p)
% sumd: within-cluster sum of distances
% D: distances to all centroids (n × k)

% Robust initialization with multiple replicates
[idx, C, sumd] = kmeans(X, k, ...
    'Replicates', 10, ...           % Run 10 times, keep best
    'MaxIter', 1000, ...            % Maximum iterations
    'Display', 'final');            % Show convergence info
```

### Determining Optimal k

```matlab
% Elbow method
maxK = 10;
totalWithinSS = zeros(maxK, 1);
for k = 1:maxK
    [~, ~, sumd] = kmeans(X, k, 'Replicates', 5);
    totalWithinSS(k) = sum(sumd);
end

figure;
plot(1:maxK, totalWithinSS, 'bo-', 'LineWidth', 2);
xlabel('Number of clusters (k)');
ylabel('Total within-cluster sum of squares');
title('Elbow Method');

% Silhouette analysis
eva = evalclusters(X, 'kmeans', 'silhouette', 'KList', 2:10);
fprintf('Optimal k by silhouette: %d\n', eva.OptimalK);
plot(eva);

% Gap statistic
eva = evalclusters(X, 'kmeans', 'gap', 'KList', 2:10);
fprintf('Optimal k by gap: %d\n', eva.OptimalK);

% Calinski-Harabasz criterion
eva = evalclusters(X, 'kmeans', 'CalinskiHarabasz', 'KList', 2:10);
fprintf('Optimal k by CH: %d\n', eva.OptimalK);
```

### K-Means++ Initialization

```matlab
% K-means++ (default since R2014a)
[idx, C] = kmeans(X, k, 'Start', 'plus');

% Custom initialization
initialCentroids = X(randperm(size(X,1), k), :);
[idx, C] = kmeans(X, k, 'Start', initialCentroids);
```

### Silhouette Validation

```matlab
[idx, C] = kmeans(X, k, 'Replicates', 10);

% Compute silhouette values
s = silhouette(X, idx);

% Plot silhouette diagram
figure;
silhouette(X, idx);
title(sprintf('Silhouette Plot (Mean = %.3f)', mean(s)));

% Interpretation
fprintf('Mean silhouette: %.3f\n', mean(s));
fprintf('Min silhouette: %.3f\n', min(s));
% > 0.7: strong structure
% 0.5-0.7: reasonable structure
% 0.25-0.5: weak structure
% < 0.25: no structure or wrong k
```

## Hierarchical Clustering

### Agglomerative Clustering

```matlab
% Compute pairwise distances
D = pdist(X);  % Condensed distance matrix

% Linkage methods
Z_single = linkage(D, 'single');     % Minimum distance (chaining)
Z_complete = linkage(D, 'complete'); % Maximum distance
Z_average = linkage(D, 'average');   % UPGMA
Z_ward = linkage(D, 'ward');         % Ward's method (recommended)
Z_centroid = linkage(D, 'centroid'); % Centroid method

% From raw data with specific distance
Z = linkage(X, 'ward', 'euclidean');
```

### Dendrogram Visualization

```matlab
Z = linkage(X, 'ward');

figure;
[H, T, outperm] = dendrogram(Z, 0);  % Show all leaves
xlabel('Sample'); ylabel('Distance');
title('Hierarchical Clustering Dendrogram');

% Truncated dendrogram for large datasets
figure;
dendrogram(Z, 30);  % Show only 30 leaves

% Color clusters
figure;
dendrogram(Z, 0, 'ColorThreshold', 'default');
```

### Cutting the Dendrogram

```matlab
Z = linkage(X, 'ward');

% Cut by number of clusters
k = 4;
idx = cluster(Z, 'MaxClust', k);

% Cut by distance threshold
cutoff = 2.5;
idx = cluster(Z, 'Cutoff', cutoff, 'Criterion', 'distance');

% Inconsistency-based cutting
idx = cluster(Z, 'Cutoff', 1.2, 'Criterion', 'inconsistent');
```

### Cophenetic Correlation

```matlab
% Measure how well dendrogram preserves distances
Z = linkage(X, 'ward');
c = cophenet(Z, pdist(X));
fprintf('Cophenetic correlation: %.3f\n', c);
% > 0.75 is good; higher means dendrogram preserves original distances well
```

## Gaussian Mixture Models

### Fitting GMM

```matlab
k = 3;

% Basic GMM
GMModel = fitgmdist(X, k);

% With options
GMModel = fitgmdist(X, k, ...
    'CovarianceType', 'full', ...       % 'full', 'diagonal', 'isotropic'
    'SharedCovariance', false, ...       % Each component has own covariance
    'RegularizationValue', 0.01, ...    % Prevent singular covariance
    'Replicates', 5, ...                % Multiple starts
    'Options', statset('MaxIter', 500));

% Display results
fprintf('Converged: %s\n', string(GMModel.Converged));
fprintf('Negative log-likelihood: %.2f\n', GMModel.NegativeLogLikelihood);
fprintf('AIC: %.2f, BIC: %.2f\n', GMModel.AIC, GMModel.BIC);
```

### Soft and Hard Clustering

```matlab
% Hard clustering (most likely cluster)
idx = cluster(GMModel, X);

% Soft clustering (posterior probabilities)
P = posterior(GMModel, X);  % n × k matrix of probabilities

% Visualize uncertainty
figure;
gscatter(X(:,1), X(:,2), idx);
hold on;
% Plot points with uncertain assignments
uncertain = max(P, [], 2) < 0.7;
scatter(X(uncertain,1), X(uncertain,2), 100, 'ko', 'LineWidth', 2);
legend([cellstr(num2str((1:k)')); 'Uncertain']);
```

### Model Selection for GMM

```matlab
% Compare models with different k and covariance types
kList = 1:6;
covTypes = {'full', 'diagonal'};
results = table();

for cov = covTypes
    for k = kList
        GMModel = fitgmdist(X, k, ...
            'CovarianceType', cov{1}, ...
            'RegularizationValue', 0.01, ...
            'Replicates', 3);

        results = [results; table(k, cov, GMModel.AIC, GMModel.BIC, ...
            'VariableNames', {'k', 'CovType', 'AIC', 'BIC'})];
    end
end

disp(results);
[~, bestIdx] = min(results.BIC);
fprintf('Best model: k=%d, CovType=%s (by BIC)\n', ...
    results.k(bestIdx), results.CovType{bestIdx});
```

## DBSCAN (Density-Based)

### Basic DBSCAN

```matlab
% DBSCAN parameters
epsilon = 0.5;  % Neighborhood radius
minPts = 5;     % Minimum points in neighborhood

idx = dbscan(X, epsilon, minPts);

% idx = -1 indicates noise/outliers
numClusters = max(idx);
numNoise = sum(idx == -1);
fprintf('Found %d clusters, %d noise points\n', numClusters, numNoise);

% Visualize
figure;
gscatter(X(:,1), X(:,2), idx);
title('DBSCAN Clustering');
```

### Choosing Epsilon (k-Distance Graph)

```matlab
minPts = 5;
knnDist = pdist2(X, X, 'euclidean', 'Smallest', minPts);
sortedDist = sort(knnDist(minPts,:));

figure;
plot(sortedDist);
xlabel('Points sorted by distance');
ylabel(sprintf('%d-nearest neighbor distance', minPts));
title('k-Distance Graph (find knee for epsilon)');
grid on;

% The "elbow" in this plot suggests epsilon
```

## Spectral Clustering

```matlab
k = 3;

% Basic spectral clustering
idx = spectralcluster(X, k);

% With options
idx = spectralcluster(X, k, ...
    'Distance', 'euclidean', ...    % 'euclidean', 'cosine', etc.
    'SimilarityGraph', 'knn', ...   % 'knn' or 'epsilon'
    'KNearestNeighbors', 10);

% From similarity matrix
S = exp(-pdist2(X, X).^2 / (2 * sigma^2));  % RBF similarity
idx = spectralcluster(S, k, 'SimilarityGraph', 'precomputed');
```

## Cluster Validation

### Internal Validation Metrics

```matlab
% Silhouette coefficient
s = silhouette(X, idx);
meanSil = mean(s);

% Davies-Bouldin index (lower is better)
db = evalclusters(X, idx, 'DaviesBouldin');
dbIndex = db.CriterionValues;

% Calinski-Harabasz index (higher is better)
ch = evalclusters(X, idx, 'CalinskiHarabasz');
chIndex = ch.CriterionValues;

fprintf('Mean Silhouette: %.3f\n', meanSil);
fprintf('Davies-Bouldin: %.3f\n', dbIndex);
fprintf('Calinski-Harabasz: %.3f\n', chIndex);
```

### External Validation (with Ground Truth)

```matlab
% Rand index
RI = rand_index(trueLabels, idx);  % Custom function

% Adjusted Rand index
ARI = adjusted_rand_index(trueLabels, idx);  % Custom function

% Normalized Mutual Information
NMI = normalized_mutual_info(trueLabels, idx);  % Custom function

% Using built-in (requires Computing Toolbox)
% [~, ~, ~, RI] = confusionmat(trueLabels, idx);
```

## Cluster Visualization

### 2D/3D Scatter Plots

```matlab
% 2D
figure;
gscatter(X(:,1), X(:,2), idx);
hold on;
plot(C(:,1), C(:,2), 'kx', 'MarkerSize', 15, 'LineWidth', 3);
legend([cellstr(num2str((1:k)')); 'Centroids']);
title('K-Means Clustering');

% 3D
figure;
scatter3(X(:,1), X(:,2), X(:,3), 36, idx, 'filled');
colorbar;
title('3D Clustering');
```

### t-SNE Visualization

```matlab
% Reduce to 2D with t-SNE
Y = tsne(X, 'NumDimensions', 2, 'Perplexity', 30);

figure;
gscatter(Y(:,1), Y(:,2), idx);
title('t-SNE Visualization of Clusters');
```

### Parallel Coordinates

```matlab
figure;
parallelcoords(X, 'Group', idx, 'Labels', varNames);
title('Parallel Coordinates by Cluster');
```

## Biomedical Clustering Example

```matlab
%% Patient Subtyping from Clinical Variables

% 1. Load data
data = readtable('patient_data.csv');
X = data{:, {'Age', 'BMI', 'SystolicBP', 'DiastolicBP', 'Cholesterol', ...
    'Glucose', 'HbA1c'}};
varNames = data.Properties.VariableNames(2:end);

% 2. Standardize features
X_std = zscore(X);

% 3. Determine optimal k
figure;
eva_sil = evalclusters(X_std, 'kmeans', 'silhouette', 'KList', 2:8);
eva_gap = evalclusters(X_std, 'kmeans', 'gap', 'KList', 2:8);

subplot(1,2,1);
plot(eva_sil);
title('Silhouette');

subplot(1,2,2);
plot(eva_gap);
title('Gap Statistic');

k = eva_sil.OptimalK;
fprintf('Optimal k: %d (by silhouette)\n', k);

% 4. Cluster with k-means
[idx, C] = kmeans(X_std, k, 'Replicates', 20);

% 5. Characterize clusters
clusterStats = grpstats(data(:, 2:end), idx, {'mean', 'std'});
disp(clusterStats);

% 6. Visualize with t-SNE
Y = tsne(X_std, 'NumDimensions', 2);
figure;
gscatter(Y(:,1), Y(:,2), idx);
title('Patient Subtypes (t-SNE)');

% 7. Compare clusters on key variables
figure;
boxplot(data.HbA1c, idx);
xlabel('Cluster'); ylabel('HbA1c');
title('HbA1c by Patient Subtype');
[p, ~, stats] = kruskalwallis(data.HbA1c, idx);
fprintf('HbA1c differs by cluster: p = %.4f\n', p);

% 8. Hierarchical validation
figure;
Z = linkage(X_std, 'ward');
[~, ~, outperm] = dendrogram(Z, 0);
title('Hierarchical Clustering Dendrogram');

% 9. Silhouette by cluster
figure;
silhouette(X_std, idx);
title(sprintf('Silhouette (Mean = %.3f)', mean(silhouette(X_std, idx))));
```

## Common Pitfalls

### Pitfall 1: Forgetting to Standardize

```matlab
% WRONG: Features on different scales
X = [age, income];  % age: 20-80, income: 20000-200000
[idx, C] = kmeans(X, 3);  % Income dominates!

% CORRECT: Standardize first
X_std = zscore(X);
[idx, C] = kmeans(X_std, 3);
```

### Pitfall 2: Using Wrong k

```matlab
% WRONG: Guessing k
[idx, C] = kmeans(X, 5);  % Why 5?

% CORRECT: Use validation metrics
eva = evalclusters(X, 'kmeans', 'silhouette', 'KList', 2:10);
k = eva.OptimalK;
[idx, C] = kmeans(X, k, 'Replicates', 10);
```

### Pitfall 3: Ignoring Cluster Shape

```matlab
% WRONG: K-means on non-spherical clusters
% (k-means assumes spherical clusters)

% CORRECT: Use DBSCAN or spectral clustering for arbitrary shapes
idx = dbscan(X, epsilon, minPts);
% or
idx = spectralcluster(X, k);
```

### Pitfall 4: Single Random Start

```matlab
% WRONG: Single initialization (may find local minimum)
[idx, C] = kmeans(X, k);

% CORRECT: Multiple replicates
[idx, C] = kmeans(X, k, 'Replicates', 20);
```

## Function Quick Reference

| Function | Purpose | Key Parameters |
|----------|---------|----------------|
| `kmeans` | K-means clustering | Replicates, MaxIter, Start |
| `linkage` | Hierarchical linkage | Method ('ward', 'average', etc.) |
| `cluster` | Cut dendrogram | MaxClust, Cutoff |
| `dendrogram` | Visualize hierarchy | ColorThreshold |
| `fitgmdist` | Gaussian Mixture Model | CovarianceType, Replicates |
| `dbscan` | Density-based clustering | epsilon, minPts |
| `spectralcluster` | Spectral clustering | SimilarityGraph |
| `evalclusters` | Optimal k selection | Criterion ('silhouette', 'gap', etc.) |
| `silhouette` | Cluster validation | — |
| `pdist` | Pairwise distances | Distance metric |
| `pdist2` | Pairwise distances (two sets) | Distance metric |

---

*Source: MathWorks Statistics and Machine Learning Toolbox Documentation (R2025a)*
