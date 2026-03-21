# MATLAB Statistics and Machine Learning Toolbox - Knowledge Index

This index provides quick access to knowledge cards and template scripts for biomedical data analysis.

## Task-to-Resource Mapping

| Task | Primary Resource | Knowledge Card |
|------|-----------------|----------------|
| Build a diagnostic classifier | `scripts/template_svm_classification.m` | `cards/classification.md` |
| Build a Random Forest | `scripts/template_random_forest_ensemble.m` | `cards/classification.md` |
| Predict patient outcomes (regression) | `scripts/template_glm_regression.m` | `cards/regression.md` |
| Analyze survival / time-to-event data | `scripts/template_cox_survival_analysis.m` | `cards/survival-analysis.md` |
| Discover biomarkers / feature selection | `cards/biomedical.md` | `cards/dimensionality-reduction.md` |
| Compare treatment groups (hypothesis test) | `scripts/template_hypothesis_testing.m` | `cards/hypothesis-testing.md` |
| Cluster patients into subtypes | `scripts/template_kmeans_patient_clustering.m` | `cards/clustering.md` |
| Fit distributions to clinical data | `scripts/template_distribution_fitting.m` | `cards/distributions.md` |
| Reduce dimensions (genomics, etc.) | `scripts/template_pca_feature_reduction.m` | `cards/dimensionality-reduction.md` |
| Optimize hyperparameters | `scripts/template_bayesopt_hyperparameter.m` | `cards/bayesian.md` |
| Interpret a model (SHAP/LIME) | `scripts/template_shapley_interpretability.m` | `cards/bayesian.md` |
| Handle missing clinical data | `scripts/template_missing_data_handling.m` | `cards/biomedical.md` |
| Cross-validate properly | `scripts/template_cross_validation_pipeline.m` | `cards/biomedical.md` |

## Knowledge Cards

### Primary — Biomedical Domain Value
- **[Survival Analysis](cards/survival-analysis.md)** — Kaplan-Meier, Cox proportional hazards, coxphfit (domain-specific, `logrank` does NOT exist)
- **[Biomedical Applications](cards/biomedical.md)** — Diagnostic classifiers, biomarker discovery, class imbalance, nested CV
- **[Bayesian Methods](cards/bayesian.md)** — bayesopt patterns, MCMC sampling, Bayesian model comparison

### Supplementary — Biomedical-Focused Patterns Only
- **[Classification](cards/classification.md)** — Clinical algorithm selection, class imbalance, data leakage prevention
- **[Regression](cards/regression.md)** — Odds ratios, GPR uncertainty, LASSO biomarker selection
- **[Clustering](cards/clustering.md)** — Patient subtyping, soft phenotyping with GMM
- **[Dimensionality Reduction](cards/dimensionality-reduction.md)** — p >> n patterns, biomarker consensus selection
- **[Hypothesis Testing](cards/hypothesis-testing.md)** — Clinical trial analysis, FDR correction, effect sizes
- **[Distributions](cards/distributions.md)** — Clinical measurement fitting, reference intervals, censored fitting
- **[Deep Learning Integration](cards/deep-learning.md)** — fitcnet/fitrnet vs Deep Learning Toolbox decision guide

## Template Scripts (scripts/)

12 ready-to-use MATLAB scripts in the `scripts/` directory. Start with these before writing from scratch:

| Script | Use Case |
|--------|----------|
| `template_svm_classification.m` | SVM with RBF kernel, standardization, optimization |
| `template_random_forest_ensemble.m` | Random Forest with feature importance |
| `template_cox_survival_analysis.m` | Kaplan-Meier + Cox regression |
| `template_bayesopt_hyperparameter.m` | Bayesian hyperparameter optimization |
| `template_hypothesis_testing.m` | T-test, ANOVA, nonparametric with effect sizes |
| `template_kmeans_patient_clustering.m` | Patient subtyping with optimal k |
| `template_distribution_fitting.m` | Multi-distribution fitting with AIC/BIC |
| `template_pca_feature_reduction.m` | PCA for high-dimensional biodata |
| `template_shapley_interpretability.m` | SHAP values for model explanation |
| `template_missing_data_handling.m` | Missing data strategies |
| `template_glm_regression.m` | GLM with odds ratios |
| `template_cross_validation_pipeline.m` | Nested CV pipeline |
