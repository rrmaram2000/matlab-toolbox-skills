# Dimensionality Reduction — High-Dimensional Biodata

The model already knows `pca`, `tsne`, `factoran`, `nnmf`, `fscmrmr`, `fscnca`, `sequentialfs`, and `lasso` for feature selection. This card covers patterns specific to high-dimensional biomedical data (genomics, proteomics, imaging features).

## When p >> n (More Features Than Samples)

This is the defining challenge of biomedical data science — genomics panels with 20,000 genes and 200 patients.

```matlab
% Pipeline for high-dimensional biodata
fprintf('Data: %d samples x %d features\n', size(X, 1), size(X, 2));

% Step 1: Variance filter — remove near-zero-variance features
variances = var(X);
keepIdx = variances > prctile(variances, 25);  % Keep top 75%
X_filtered = X(:, keepIdx);

% Step 2: PCA to reduce to manageable dimensions
[coeff, score, ~, ~, explained] = pca(X_filtered);
numPC = find(cumsum(explained) >= 95, 1);
X_pca = score(:, 1:numPC);
fprintf('PCA: %d -> %d components (95%% variance)\n', size(X_filtered,2), numPC);

% Step 3: Use reduced features for downstream ML
Mdl = fitcensemble(X_pca, Y, 'Method', 'Bag', 'NumLearningCycles', 100);
```

## Feature Selection for Biomarker Discovery

When the goal is to identify which specific biomarkers matter (not just predict).

```matlab
% Consensus feature selection: combine multiple methods for robustness
% 1. mRMR
idx_mrmr = fscmrmr(X, Y);

% 2. LASSO
[B, FitInfo] = lasso(zscore(X), double(Y == 'positive'), 'CV', 5);
coef_abs = abs(B(:, FitInfo.Index1SE));
[~, idx_lasso] = sort(coef_abs, 'descend');

% 3. Random Forest importance
Mdl = fitcensemble(X, Y, 'Method', 'Bag', 'NumLearningCycles', 100);
imp = oobPermutedPredictorImportance(Mdl);
[~, idx_rf] = sort(imp, 'descend');

% Consensus: features appearing in top-20 of all three methods
top20 = 20;
consensus = intersect(intersect(idx_mrmr(1:top20), idx_lasso(1:top20)), idx_rf(1:top20));
fprintf('Consensus biomarkers: %d features\n', length(consensus));
```

## PCA for Medical Data — Practical Patterns

```matlab
% Handle missing values (common in clinical data)
X_imputed = fillmissing(X, 'knn', 5);

% Always standardize before PCA (different clinical measurement scales)
X_std = zscore(X_imputed);
[coeff, score, ~, ~, explained] = pca(X_std);

% Top features contributing to each PC (biological interpretation)
pc1_loadings = abs(coeff(:, 1));
[~, topFeatures] = sort(pc1_loadings, 'descend');
fprintf('Top 5 features driving PC1:\n');
for i = 1:5
    fprintf('  %s (loading: %.3f)\n', varNames{topFeatures(i)}, pc1_loadings(topFeatures(i)));
end

% For very large datasets (e.g., genomics)
[coeff, score, latent] = pca(X_std, 'NumComponents', 50, 'Algorithm', 'randomized');
```

## t-SNE for Visualizing Patient Populations

```matlab
% Best practice: PCA first, then t-SNE (faster, often better results)
[~, score_pca] = pca(zscore(X), 'NumComponents', min(50, size(X,2)));
Y_tsne = tsne(score_pca, 'Perplexity', 30);

figure;
gscatter(Y_tsne(:,1), Y_tsne(:,2), diagnosis);
title('Patient Population Structure');

% WARNING: t-SNE distances are NOT meaningful — only local structure is preserved
% Run multiple times with different seeds; choose lowest KL divergence
```

## NMF for Parts-Based Decomposition

Useful for non-negative data (e.g., gene expression, spectral data).

```matlab
X_nn = max(X, 0);  % Ensure non-negative
k = 5;  % Number of metagenes/components
[W, H] = nnmf(X_nn, k, 'Replicates', 10);
% W: patient-by-component scores (how much of each metagene)
% H: component-by-gene loadings (what genes define each metagene)
```

---

*See also: scripts/template_pca_feature_reduction.m, classification.md for using reduced features*
