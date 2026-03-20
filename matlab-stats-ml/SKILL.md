---
name: matlab-stats-ml
description: "MATLAB Statistics and Machine Learning Toolbox. Functions - fitcsvm, fitctree, fitcensemble, fitcknn, fitcnb, fitcnet, fitlm, fitglm, fitrgp, fitrensemble, lasso, kmeans, linkage, fitgmdist, dbscan, pca, tsne, factoran, ttest, ttest2, anova1, anovan, ranksum, chi2gof, fitdist, makedist, mle, ecdf, coxphfit, cvpartition, crossval, kfoldLoss, perfcurve, confusionchart, bayesopt, shapley, normalize, fillmissing. Tasks - run t-test or ANOVA, fit distributions, classify patients, train SVM or random forest, predict with regression, cluster data, reduce dimensions with PCA or t-SNE, cross-validate, compute ROC and AUC, select features, optimize hyperparameters, analyze survival data, plot Kaplan-Meier curves, handle missing data, interpret with SHAP or LIME. Domains - biomarker discovery, clinical trials, patient outcome prediction, diagnostic classification, gene expression, proteomics, epidemiology, survival analysis, treatment comparison, financial modeling, quality control, A/B testing, environmental monitoring, general statistical analysis, predictive maintenance, sensor data classification."
---

# MATLAB Statistics and Machine Learning Toolbox Skill

**Version:** R2025b | **Focus:** Biomedical-specific workflows and template scripts

This skill provides expert guidance for applying the Statistics and Machine Learning Toolbox to biomedical data analysis. The model already has strong knowledge of the toolbox API — this skill adds domain-specific workflows, clinical best practices, and ready-to-use template scripts.

## What Makes Biomedical Stats Different

Biomedical data analysis has unique challenges that generic ML tutorials do not address:

1. **Class imbalance is the norm** — Disease prevalence is often 1-10%. Always use cost-sensitive learning or resampling. Never report accuracy alone; use sensitivity, specificity, AUC, and likelihood ratios.

2. **p >> n is common** — Genomics/proteomics panels have thousands of features and hundreds of samples. Feature selection and dimensionality reduction are mandatory, not optional.

3. **Data leakage is catastrophic** — All preprocessing (normalization, feature selection, imputation) must happen within cross-validation folds. Leakage inflates performance and leads to clinical failures.

4. **Clinical interpretability matters** — Clinicians need odds ratios, hazard ratios, and feature importance — not just predictions. Use `fitglm` for odds ratios, `coxphfit` for hazard ratios, `shapley` for model explanation.

5. **Missing data is expected** — Use `fillmissing(X, 'knn')` for clinical imputation (requires Stats & ML Toolbox, not Bioinformatics Toolbox).

6. **Censored data requires special handling** — Survival analysis with `ecdf(..., 'Censoring', ...)` and `coxphfit` — not standard regression.

7. **Multiple testing correction is essential** — When testing many biomarkers, use Benjamini-Hochberg FDR, not just Bonferroni.

## Read Before Coding

| Task | Start Here |
|------|-----------|
| Build a diagnostic classifier | `scripts/template_svm_classification.m` or `scripts/template_random_forest_ensemble.m` |
| Analyze survival / time-to-event data | `scripts/template_cox_survival_analysis.m` + `cards/survival-analysis.md` |
| Discover biomarkers | `cards/biomedical.md` (consensus feature selection) |
| Optimize hyperparameters | `scripts/template_bayesopt_hyperparameter.m` + `cards/bayesian.md` |
| Compare treatment groups | `scripts/template_hypothesis_testing.m` + `cards/hypothesis-testing.md` |
| Cluster patients into subtypes | `scripts/template_kmeans_patient_clustering.m` |
| Fit distributions to clinical data | `scripts/template_distribution_fitting.m` |
| Reduce dimensions (genomics, etc.) | `scripts/template_pca_feature_reduction.m` |
| Interpret a black-box model | `scripts/template_shapley_interpretability.m` |
| Handle missing clinical data | `scripts/template_missing_data_handling.m` |
| Build a regression model | `scripts/template_glm_regression.m` |
| Cross-validate properly | `scripts/template_cross_validation_pipeline.m` |

## Template Scripts

The `scripts/` directory contains 12 ready-to-use MATLAB scripts covering the most common biomedical analysis workflows:

| Script | Purpose |
|--------|---------|
| `template_svm_classification.m` | SVM classifier with RBF kernel, standardization, optimization |
| `template_random_forest_ensemble.m` | Random Forest with feature importance and OOB error |
| `template_cox_survival_analysis.m` | Kaplan-Meier curves, Cox regression, hazard ratios |
| `template_bayesopt_hyperparameter.m` | Bayesian hyperparameter optimization with bayesopt |
| `template_hypothesis_testing.m` | T-test, ANOVA, nonparametric tests with effect sizes |
| `template_kmeans_patient_clustering.m` | Patient subtyping with optimal k selection |
| `template_distribution_fitting.m` | Multi-distribution fitting with AIC/BIC comparison |
| `template_pca_feature_reduction.m` | PCA pipeline for high-dimensional biodata |
| `template_shapley_interpretability.m` | SHAP values for model explanation |
| `template_missing_data_handling.m` | Missing data strategies (kNN, interpolation) |
| `template_glm_regression.m` | GLM with odds ratios and clinical reporting |
| `template_cross_validation_pipeline.m` | Nested CV for unbiased performance estimation |

## Biomedical Research Workflow

```matlab
%% Complete Biomedical Classification Pipeline
% 1. Load and explore clinical data
data = readtable('patient_data.csv');
summary(data);
grpstats(data, 'Diagnosis', {'mean', 'std'});

%% 2. Handle missing data
data = fillmissing(data, 'knn');  % kNN imputation (Stats & ML Toolbox)

%% 3. Feature selection (within training fold only!)
cv = cvpartition(data.Diagnosis, 'Holdout', 0.2, 'Stratify', true);
XTrain = data(training(cv), :);

[idx, scores] = fscmrmr(XTrain(:, predictors), XTrain.Diagnosis);
selectedFeatures = predictors(idx(1:10));

%% 4. Train classifier with cross-validation
Mdl = fitcensemble(XTrain(:, selectedFeatures), XTrain.Diagnosis, ...
    'Method', 'Bag', 'NumLearningCycles', 100, ...
    'OptimizeHyperparameters', 'auto', ...
    'HyperparameterOptimizationOptions', struct('ShowPlots', false));

%% 5. Evaluate on held-out test set
XTest = data(test(cv), :);
[label, score] = predict(Mdl, XTest(:, selectedFeatures));
[X, Y, T, AUC] = perfcurve(XTest.Diagnosis, score(:,2), 'Positive');

%% 6. Interpret model
explainer = shapley(Mdl, XTrain(:, selectedFeatures));
plot(explainer);
```

## Knowledge Cards

See `knowledge/INDEX.md` for the complete card index. Key cards:

- **`cards/survival-analysis.md`** — Kaplan-Meier, Cox regression, coxphfit patterns
- **`cards/biomedical.md`** — Diagnostic classifiers, biomarker discovery, class imbalance
- **`cards/bayesian.md`** — bayesopt, MCMC sampling, Bayesian model comparison

## See Also (Related MATLAB Toolboxes)

- **Deep Learning Toolbox** — For CNNs, U-Net, YOLO (`trainnet`, `unet`, `dlnetwork`)
- **Medical Imaging Toolbox** — For medical data I/O and radiomics (`medicalVolume`, `radiomics`)
- **Image Processing Toolbox** — For image-based feature extraction (`regionprops`, `imgaussfilt`)
- **Wavelet Toolbox** — For multiresolution feature extraction (`wavedec2`, `wdenoise2`)
