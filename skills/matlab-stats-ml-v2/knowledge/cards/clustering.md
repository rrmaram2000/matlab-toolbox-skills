# Clustering — Patient Stratification

The model already knows `kmeans`, `linkage`, `fitgmdist`, `dbscan`, `spectralcluster`, `silhouette`, and `evalclusters`. This card covers only patient stratification and biomedical-specific clustering patterns.

## Clinical Clustering Decision Guide

```
Patient subtyping goal?
├── Find disease subtypes (unknown structure)
│   ├── Start with → kmeans + evalclusters for optimal k
│   └── Validate with → linkage dendrogram (does hierarchy make sense clinically?)
├── Soft assignments (patient can be "between" subtypes)
│   └── fitgmdist — posterior probabilities show mixed phenotypes
├── Outlier detection (unusual patients)
│   └── dbscan — labels noise points as -1
├── Time-series patient trajectories
│   └── Standardize time points, then kmeans on trajectory features
└── Multi-omics integration
    └── Standardize each omics separately, concatenate, then cluster
```

## Patient Subtyping Workflow

```matlab
%% Patient Subtyping from Clinical Variables
data = readtable('patient_data.csv');
X = data{:, {'Age', 'BMI', 'SystolicBP', 'Cholesterol', 'HbA1c'}};
varNames = {'Age', 'BMI', 'SystolicBP', 'Cholesterol', 'HbA1c'};

% CRITICAL: Standardize — clinical variables have different scales
X_std = zscore(X);

% Determine optimal k using multiple criteria
eva_sil = evalclusters(X_std, 'kmeans', 'silhouette', 'KList', 2:8);
eva_gap = evalclusters(X_std, 'kmeans', 'gap', 'KList', 2:8);
k = eva_sil.OptimalK;

% Cluster with sufficient replicates
[idx, C] = kmeans(X_std, k, 'Replicates', 20);

% Characterize subtypes — clinically meaningful summary
clusterStats = grpstats(data, idx, {'mean', 'std'});
disp(clusterStats);

% Statistical validation: do subtypes differ on outcome?
[p, ~, stats] = kruskalwallis(data.OutcomeScore, idx);
fprintf('Subtypes differ on outcome: p = %.4f\n', p);
```

## GMM for Soft Patient Phenotyping

```matlab
% Gaussian Mixture: patients can partially belong to multiple subtypes
GMModel = fitgmdist(X_std, k, ...
    'CovarianceType', 'full', ...
    'RegularizationValue', 0.01, ...  % Prevents singular covariance
    'Replicates', 5);

P = posterior(GMModel, X_std);  % Probability of each subtype

% Identify "mixed phenotype" patients
uncertain = max(P, [], 2) < 0.7;
fprintf('%d/%d patients have mixed phenotype\n', sum(uncertain), length(uncertain));

% Select number of components via BIC (not AIC — avoids overfitting)
bic_values = zeros(6, 1);
for k_test = 1:6
    gm = fitgmdist(X_std, k_test, 'RegularizationValue', 0.01, 'Replicates', 3);
    bic_values(k_test) = gm.BIC;
end
[~, bestK] = min(bic_values);
```

## Visualizing Patient Clusters

```matlab
% t-SNE visualization of patient subtypes
Y = tsne(X_std, 'NumDimensions', 2, 'Perplexity', 30);
figure;
gscatter(Y(:,1), Y(:,2), idx);
title('Patient Subtypes (t-SNE)');

% Clinical variable comparison across subtypes
figure;
boxplot(data.HbA1c, idx);
xlabel('Cluster'); ylabel('HbA1c');
title('HbA1c by Patient Subtype');
```

## Common Pitfalls in Clinical Clustering

| Pitfall | Solution |
|---------|----------|
| Forgetting to standardize | Always `zscore(X)` — clinical variables have vastly different scales |
| Single random start | Use `'Replicates', 20` — k-means is sensitive to initialization |
| Cluster on raw + derived vars | Don't include both BMI and (weight, height) — redundancy biases clusters |
| No clinical validation | Always test if clusters differ on independent clinical outcomes |
| Too many clusters | Clinical subtypes should be actionable — 2-5 is typical |

---

*See also: scripts/template_kmeans_patient_clustering.m, dimensionality-reduction.md for PCA before clustering*
