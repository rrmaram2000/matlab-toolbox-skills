# Dimensionality Reduction

Dimensionality reduction transforms high-dimensional data into a lower-dimensional representation while preserving important structure. Essential for visualization, noise reduction, and overcoming the curse of dimensionality.

## Method Selection Guide

```
What's your goal?
├── Linear projection, variance preservation → pca
├── 2D/3D visualization of clusters → tsne
├── Large-scale visualization → umap (via File Exchange)
├── Discover latent factors → factoran
├── Non-negative components → nnmf
├── Supervised feature selection → fscnca, fscmrmr
├── Sparse representation → sparsefilt
├── Kernel-based nonlinear → kpca (custom implementation)
└── Large datasets → pca with 'Algorithm','eig' or randomized
```

## Principal Component Analysis (PCA)

PCA finds orthogonal directions of maximum variance. The most widely used linear dimensionality reduction method.

### Basic PCA

```matlab
% Load example data
load fisheriris
X = meas;  % 150 samples × 4 features

% Perform PCA (data centered by default)
[coeff, score, latent, tsquared, explained, mu] = pca(X);

% coeff: Principal component coefficients (loadings)
% score: Principal component scores (transformed data)
% latent: Eigenvalues (variance of each PC)
% explained: Percentage of variance explained
% mu: Estimated mean

fprintf('Variance explained by each PC:\n');
for i = 1:length(explained)
    fprintf('  PC%d: %.2f%%\n', i, explained(i));
end
fprintf('Total variance (first 2 PCs): %.2f%%\n', sum(explained(1:2)));
```

### Choosing Number of Components

```matlab
% Method 1: Cumulative variance threshold
threshold = 95;  % Explain 95% of variance
cumVar = cumsum(explained);
numPC = find(cumVar >= threshold, 1);
fprintf('PCs needed for %d%% variance: %d\n', threshold, numPC);

% Method 2: Kaiser criterion (eigenvalue > 1 for standardized data)
[~, ~, latent_std] = pca(zscore(X));  % Standardize first
numPC_kaiser = sum(latent_std > 1);
fprintf('PCs by Kaiser criterion: %d\n', numPC_kaiser);

% Method 3: Scree plot (elbow method)
figure;
subplot(1,2,1);
pareto(explained);
xlabel('Principal Component');
ylabel('Variance Explained (%)');
title('Scree Plot');

subplot(1,2,2);
plot(cumVar, 'b-o', 'LineWidth', 2);
hold on;
yline(threshold, 'r--', sprintf('%d%%', threshold));
xlabel('Number of Components');
ylabel('Cumulative Variance (%)');
title('Cumulative Variance');
grid on;
```

### Visualizing PCA Results

```matlab
% Biplot: Shows both scores and loadings
figure;
biplot(coeff(:,1:2), 'Scores', score(:,1:2), ...
    'VarLabels', {'Sepal Length', 'Sepal Width', 'Petal Length', 'Petal Width'});
title('PCA Biplot');

% Scatter plot of first two PCs
figure;
gscatter(score(:,1), score(:,2), species);
xlabel(sprintf('PC1 (%.1f%%)', explained(1)));
ylabel(sprintf('PC2 (%.1f%%)', explained(2)));
title('PCA Score Plot');
grid on;
```

### Interpreting Loadings

```matlab
% Display loading matrix
varNames = {'Sepal.L', 'Sepal.W', 'Petal.L', 'Petal.W'};
T = array2table(coeff, 'RowNames', varNames, ...
    'VariableNames', {'PC1', 'PC2', 'PC3', 'PC4'});
disp('Principal Component Loadings:');
disp(T);

% Variables with high absolute loadings contribute most to that PC
[~, maxIdx] = max(abs(coeff(:,1)));
fprintf('Variable most correlated with PC1: %s\n', varNames{maxIdx});

% Correlation between original variables and PCs
correlation = corr(X, score);
fprintf('\nCorrelation between variables and PC1:\n');
for i = 1:length(varNames)
    fprintf('  %s: %.3f\n', varNames{i}, correlation(i,1));
end
```

### PCA for Large Datasets

```matlab
% For large datasets, use economy-size computation
[coeff, score, latent] = pca(X, 'Economy', true);

% Or use the eigenvalue decomposition algorithm (faster for n >> p)
[coeff, score, latent] = pca(X, 'Algorithm', 'eig');

% For very large datasets, use randomized PCA
% Only compute first k components
k = 10;
[coeff, score, latent] = pca(X, 'NumComponents', k, ...
    'Algorithm', 'randomized');  % Faster approximation
```

### Handling Missing Data

```matlab
% PCA with missing values (uses ALS algorithm)
X_missing = X;
X_missing(rand(size(X)) < 0.1) = NaN;  % 10% missing

[coeff, score, latent, tsquared, explained] = pca(X_missing, ...
    'Algorithm', 'als', ...
    'NumComponents', 3);

fprintf('PCA completed despite %.1f%% missing values\n', ...
    100 * sum(isnan(X_missing(:))) / numel(X_missing));
```

### Projecting New Data

```matlab
% Fit PCA on training data
[coeff, ~, ~, ~, ~, mu] = pca(X_train, 'Centered', true);

% Project new data onto PC space
X_new_centered = X_new - mu;
score_new = X_new_centered * coeff;

% Use only first k components
k = 2;
score_new_reduced = X_new_centered * coeff(:, 1:k);
```

## t-SNE (t-Distributed Stochastic Neighbor Embedding)

Non-linear method optimized for 2D/3D visualization. Preserves local structure and cluster separation.

### Basic t-SNE

```matlab
% t-SNE for visualization
rng(42);  % For reproducibility
Y = tsne(X, 'NumDimensions', 2);

% Plot with group labels
figure;
gscatter(Y(:,1), Y(:,2), species);
xlabel('t-SNE 1');
ylabel('t-SNE 2');
title('t-SNE Visualization');
```

### Tuning t-SNE Parameters

```matlab
% Perplexity: Balance between local and global structure
% Typical range: 5-50, larger for bigger datasets
perplexities = [5, 15, 30, 50];

figure;
for i = 1:length(perplexities)
    rng(42);
    Y = tsne(X, 'Perplexity', perplexities(i));

    subplot(2, 2, i);
    gscatter(Y(:,1), Y(:,2), species);
    title(sprintf('Perplexity = %d', perplexities(i)));
    axis equal;
end
sgtitle('Effect of Perplexity on t-SNE');
```

### t-SNE with PCA Pre-Reduction

```matlab
% For high-dimensional data, reduce with PCA first
% This speeds up t-SNE and can improve results

% Pre-reduce to 50 dimensions with PCA
Y = tsne(X, ...
    'NumPCAComponents', 50, ...  % PCA pre-reduction
    'Perplexity', 30, ...
    'LearnRate', 500, ...        % Learning rate (default 500)
    'Exaggeration', 4, ...       % Early exaggeration
    'NumIterations', 1000);      % Max iterations

figure;
gscatter(Y(:,1), Y(:,2), labels);
title('t-SNE with PCA Pre-reduction');
```

### 3D t-SNE

```matlab
% 3D t-SNE for interactive exploration
Y3 = tsne(X, 'NumDimensions', 3, 'Perplexity', 30);

figure;
scatter3(Y3(:,1), Y3(:,2), Y3(:,3), 50, categorical(species), 'filled');
xlabel('t-SNE 1');
ylabel('t-SNE 2');
zlabel('t-SNE 3');
title('3D t-SNE');
rotate3d on;
```

### t-SNE Best Practices

```matlab
% 1. Standardize data before t-SNE
X_std = zscore(X);
Y = tsne(X_std, 'Perplexity', 30);

% 2. Run multiple times (results can vary)
numRuns = 5;
kl_divergences = zeros(numRuns, 1);

for run = 1:numRuns
    rng(run);
    [Y, kl] = tsne(X_std, 'Perplexity', 30);
    kl_divergences(run) = kl;
    fprintf('Run %d: KL divergence = %.4f\n', run, kl);
end

% 3. Choose run with lowest KL divergence
[~, bestRun] = min(kl_divergences);
rng(bestRun);
Y_best = tsne(X_std, 'Perplexity', 30);
```

## Factor Analysis

Factor analysis identifies latent factors that explain correlations among observed variables.

### Exploratory Factor Analysis

```matlab
% Determine number of factors
% Use parallel analysis or eigenvalue > 1 rule

% Fit factor model with k factors
k = 2;
[Lambda, Psi, T, stats, F] = factoran(X, k, 'Rotate', 'varimax');

% Lambda: Factor loadings
% Psi: Specific variances (uniquenesses)
% T: Rotation matrix
% F: Factor scores

fprintf('Factor Analysis Results:\n');
fprintf('Chi-square: %.2f, df: %d, p: %.4f\n', ...
    stats.chisq, stats.dfe, stats.p);

% Display loadings
T_loadings = array2table(Lambda, 'RowNames', varNames, ...
    'VariableNames', {'Factor1', 'Factor2'});
disp('Rotated Factor Loadings:');
disp(T_loadings);
```

### Rotation Methods

```matlab
% Varimax: Orthogonal rotation, maximizes variance of squared loadings
[Lambda_varimax, ~, ~, ~, F] = factoran(X, 2, 'Rotate', 'varimax');

% Promax: Oblique rotation, allows correlated factors
[Lambda_promax, ~, ~, ~, F] = factoran(X, 2, 'Rotate', 'promax');

% Compare rotations
figure;
subplot(1,2,1);
biplot(Lambda_varimax, 'VarLabels', varNames);
title('Varimax Rotation');

subplot(1,2,2);
biplot(Lambda_promax, 'VarLabels', varNames);
title('Promax Rotation');
```

### Communalities and Uniquenesses

```matlab
% Communality: Proportion of variance explained by factors
communality = sum(Lambda.^2, 2);

% Uniqueness: Variance not explained by factors
uniqueness = Psi;

fprintf('Variable Analysis:\n');
for i = 1:length(varNames)
    fprintf('  %s: Communality=%.3f, Uniqueness=%.3f\n', ...
        varNames{i}, communality(i), uniqueness(i));
end

% Variables with low communality may not fit factor model well
if any(communality < 0.3)
    warning('Some variables have low communality (<0.3)');
end
```

## Non-Negative Matrix Factorization (NMF)

NMF factorizes non-negative data into non-negative factors. Useful for interpretable decompositions.

### Basic NMF

```matlab
% Ensure data is non-negative
X_nn = max(X, 0);

% Factorize: X ≈ W × H
k = 2;  % Number of components
[W, H] = nnmf(X_nn, k);

% W: n × k basis matrix (how samples combine components)
% H: k × p coefficient matrix (component patterns)

fprintf('Reconstruction error: %.4f\n', norm(X_nn - W*H, 'fro'));

% Visualize components
figure;
bar(H');
xlabel('Features');
ylabel('Component Value');
legend('Component 1', 'Component 2');
title('NMF Components');
```

### NMF with Different Algorithms

```matlab
% Algorithm options: als (default), mult
[W_als, H_als] = nnmf(X_nn, k, 'Algorithm', 'als');  % Alternating least squares
[W_mult, H_mult] = nnmf(X_nn, k, 'Algorithm', 'mult');  % Multiplicative update

% Add sparsity constraint
[W_sparse, H_sparse] = nnmf(X_nn, k, ...
    'Algorithm', 'mult', ...
    'H0', rand(k, size(X_nn, 2)), ...
    'W0', rand(size(X_nn, 1), k), ...
    'Options', statset('MaxIter', 200));
```

## Feature Selection Methods

Feature selection identifies the most relevant features for a prediction task.

### Filter Methods: mRMR and NCA

```matlab
% Load classification data
load fisheriris
X = meas;
Y = species;

% Minimum Redundancy Maximum Relevance (mRMR)
idx_mrmr = fscmrmr(X, Y);
fprintf('mRMR feature ranking: %s\n', mat2str(idx_mrmr));

% Neighborhood Component Analysis (NCA) - supervised
mdl_nca = fscnca(X, Y, 'Standardize', true);

% Feature weights from NCA
figure;
bar(mdl_nca.FeatureWeights);
xlabel('Feature Index');
ylabel('Feature Weight');
title('NCA Feature Weights');

% Select features with weight > threshold
threshold = 0.1;
selectedFeatures = find(mdl_nca.FeatureWeights > threshold);
fprintf('Selected features (NCA): %s\n', mat2str(selectedFeatures));
```

### Sequential Feature Selection

```matlab
% Sequential forward selection with cross-validation
fun = @(Xtrain, Ytrain, Xtest, Ytest) ...
    sum(predict(fitcknn(Xtrain, Ytrain), Xtest) ~= Ytest);

cv = cvpartition(Y, 'KFold', 5);
[fs, history] = sequentialfs(fun, X, Y, 'cv', cv);

fprintf('Selected features (SFS): %s\n', mat2str(find(fs)));

% Plot feature selection history
figure;
plot(history.Crit, 'b-o', 'LineWidth', 2);
xlabel('Number of Features');
ylabel('CV Error');
title('Sequential Feature Selection');
grid on;
```

### Lasso for Feature Selection

```matlab
% Lasso regression selects features via L1 penalty
y = double(categorical(Y) == 'setosa');  % Binary target

% Fit Lasso with cross-validation
[B, FitInfo] = lasso(X, y, 'CV', 10);

% Use lambda at minimum MSE
lambda_min = FitInfo.LambdaMinMSE;
coef_min = B(:, FitInfo.IndexMinMSE);

% Or use 1SE rule (more regularized)
lambda_1se = FitInfo.Lambda1SE;
coef_1se = B(:, FitInfo.Index1SE);

% Selected features are those with non-zero coefficients
selectedVars_1se = find(coef_1se ~= 0);
fprintf('Features selected by Lasso (1SE): %s\n', mat2str(selectedVars_1se));

% Visualize Lasso path
figure;
lassoPlot(B, FitInfo, 'PlotType', 'CV');
```

### Compare Feature Selection Methods

```matlab
function compareFeatureSelection(X, Y, varNames)
    % Compare multiple feature selection methods

    fprintf('=== Feature Selection Comparison ===\n\n');

    % 1. mRMR
    idx_mrmr = fscmrmr(X, Y);

    % 2. NCA
    mdl_nca = fscnca(X, Y, 'Standardize', true);
    [~, idx_nca] = sort(mdl_nca.FeatureWeights, 'descend');

    % 3. Chi-square (for categorical)
    idx_chi2 = fscchi2(X, Y);

    % 4. ANOVA F-test
    % Note: fscmrmr handles continuous features well

    % Display rankings
    T = table(idx_mrmr', idx_nca', idx_chi2', ...
        'VariableNames', {'mRMR', 'NCA', 'Chi2'}, ...
        'RowNames', cellstr("Rank " + string(1:size(X,2))'));
    disp(T);

    % Agreement between methods
    top3_mrmr = idx_mrmr(1:3);
    top3_nca = idx_nca(1:3);
    overlap = length(intersect(top3_mrmr, top3_nca));
    fprintf('\nTop-3 overlap (mRMR vs NCA): %d/3\n', overlap);
end

% Usage
compareFeatureSelection(X, Y, varNames);
```

## Sparse Filtering

Sparse filtering learns a sparse representation of the data.

```matlab
% Sparse filtering for feature learning
numFeatures = 10;  % Number of sparse features to learn

% Create sparse filter model
spFilter = sparsefilt(X', numFeatures, ...  % Note: transpose for column-wise samples
    'IterationLimit', 200, ...
    'Standardize', true);

% Transform data
X_sparse = transform(spFilter, X');
X_sparse = X_sparse';  % Back to row-wise samples

fprintf('Sparse features learned: %d\n', numFeatures);
fprintf('Sparsity ratio: %.2f%%\n', 100 * sum(X_sparse(:) == 0) / numel(X_sparse));
```

## Custom Kernel PCA

Kernel PCA extends PCA to nonlinear dimensionality reduction.

```matlab
function [Z, eigVecs, eigVals] = kernelPCA(X, k, kernelType, params)
    % Kernel PCA implementation
    % X: n × p data matrix
    % k: number of components
    % kernelType: 'rbf', 'poly', 'linear'
    % params: kernel parameters

    n = size(X, 1);

    % Compute kernel matrix
    switch kernelType
        case 'rbf'
            sigma = params.sigma;
            D = pdist2(X, X);
            K = exp(-D.^2 / (2 * sigma^2));
        case 'poly'
            d = params.degree;
            c = params.c;
            K = (X * X' + c).^d;
        case 'linear'
            K = X * X';
    end

    % Center kernel matrix
    oneN = ones(n, n) / n;
    K_centered = K - oneN * K - K * oneN + oneN * K * oneN;

    % Eigendecomposition
    [eigVecs, eigVals] = eig(K_centered);
    eigVals = diag(eigVals);

    % Sort by eigenvalue (descending)
    [eigVals, idx] = sort(eigVals, 'descend');
    eigVecs = eigVecs(:, idx);

    % Project onto top k eigenvectors
    Z = K_centered * eigVecs(:, 1:k);

    % Normalize
    for i = 1:k
        Z(:, i) = Z(:, i) / sqrt(eigVals(i));
    end
end

% Usage: RBF Kernel PCA
params.sigma = 1.0;
[Z_kpca, eigVecs, eigVals] = kernelPCA(X, 2, 'rbf', params);

figure;
gscatter(Z_kpca(:,1), Z_kpca(:,2), species);
xlabel('Kernel PC1');
ylabel('Kernel PC2');
title('Kernel PCA (RBF kernel)');
```

## Comparison of Methods

| Method | Linear | Preserves | Best For | Computational |
|--------|--------|-----------|----------|---------------|
| PCA | Yes | Global variance | Preprocessing, noise reduction | O(np²) |
| t-SNE | No | Local structure | 2D/3D visualization | O(n²) |
| Factor Analysis | Yes | Correlation structure | Latent variable discovery | O(np²) |
| NMF | Yes | Non-negativity | Interpretable parts | O(npk) |
| Kernel PCA | No | Kernel similarity | Nonlinear patterns | O(n³) |

## Best Practices

1. **Always standardize** data before PCA/Factor Analysis for comparable scales

2. **PCA vs t-SNE**:
   - Use PCA for preprocessing, noise reduction, linear relationships
   - Use t-SNE for visualization of clusters (don't interpret distances)

3. **Choosing components**:
   - PCA: Use cumulative variance ≥ 95% or scree plot elbow
   - t-SNE: Always use 2-3 dimensions (for visualization only)
   - Factor Analysis: Use parallel analysis or interpretability

4. **Validation**:
   - For supervised learning, evaluate with downstream task performance
   - For unsupervised, use reconstruction error or cluster quality

5. **Large datasets**:
   - Use randomized PCA or incremental PCA
   - For t-SNE, subsample or use approximations

## Common Pitfalls

| Pitfall | Solution |
|---------|----------|
| Interpreting t-SNE distances | t-SNE distorts global distances; only local structure meaningful |
| Using raw PCA scores as features | Keep enough components to explain sufficient variance |
| Factor Analysis with too few samples | Need n > 5p (5x more samples than variables) |
| NMF with negative data | Transform data to non-negative (shift, log, etc.) |
| Overfitting in feature selection | Use cross-validation within selection process |

## Biomedical Application Example

```matlab
function reduceDimForMedical(X, Y, varNames)
    % Dimensionality reduction pipeline for medical data

    fprintf('=== Medical Data Dimensionality Reduction ===\n');
    fprintf('Original dimensions: %d samples × %d features\n', size(X, 1), size(X, 2));

    % 1. Handle missing values
    X = fillmissing(X, 'knn', 5);  % KNN imputation

    % 2. Standardize
    X_std = zscore(X);

    % 3. PCA for preprocessing
    [coeff, score, ~, ~, explained] = pca(X_std);
    numPC = find(cumsum(explained) >= 95, 1);
    X_pca = score(:, 1:numPC);
    fprintf('PCA: Reduced to %d components (95%% variance)\n', numPC);

    % 4. Feature importance from PCA loadings
    pc1_loadings = abs(coeff(:, 1));
    [~, topFeatures] = sort(pc1_loadings, 'descend');
    fprintf('Top 5 features by PC1 loading:\n');
    for i = 1:min(5, length(varNames))
        fprintf('  %d. %s (%.3f)\n', i, varNames{topFeatures(i)}, ...
            pc1_loadings(topFeatures(i)));
    end

    % 5. t-SNE for visualization
    rng(42);
    Y_tsne = tsne(X_pca, 'Perplexity', 30);

    % 6. Plot
    figure;
    subplot(1,2,1);
    gscatter(score(:,1), score(:,2), Y);
    xlabel(sprintf('PC1 (%.1f%%)', explained(1)));
    ylabel(sprintf('PC2 (%.1f%%)', explained(2)));
    title('PCA');

    subplot(1,2,2);
    gscatter(Y_tsne(:,1), Y_tsne(:,2), Y);
    xlabel('t-SNE 1');
    ylabel('t-SNE 2');
    title('t-SNE (from PCA-reduced data)');

    sgtitle('Dimensionality Reduction for Medical Data');
end
```

---

*See also: classification.md for using reduced features in classifiers, clustering.md for unsupervised analysis*
