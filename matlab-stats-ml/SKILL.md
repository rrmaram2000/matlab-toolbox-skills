---
name: matlab-stats-ml
description: MATLAB Statistics and Machine Learning Toolbox for classification (fitcsvm, fitctree, fitcensemble, fitcknn, fitcnb, fitcnet), regression (fitlm, fitglm, fitrgp, fitrensemble, lasso), clustering (kmeans, linkage, fitgmdist, dbscan), dimensionality reduction (pca, tsne, factoran), hypothesis testing (ttest, ttest2, anova1, anovan, ranksum, chi2gof), distributions (fitdist, makedist, mle), survival analysis (ecdf, coxphfit), and cross-validation (cvpartition, crossval, kfoldLoss). Use for statistical inference, machine learning model training, biomarker discovery, and clinical data analysis.
---

# MATLAB Statistics and Machine Learning Toolbox Skill

**Version:** R2025b | **Source:** Official MathWorks PDF Documentation (12,806 pages)

A comprehensive skill for the MATLAB Statistics and Machine Learning Toolbox, providing expert guidance on statistical analysis, machine learning algorithms, and data-driven modeling. This skill covers the complete toolbox capabilities from descriptive statistics to advanced deep learning integration.

## When to Use This Skill

### Primary Use Cases

Use this skill when you need to:

**Statistical Analysis:**
- Perform hypothesis testing (t-tests, ANOVA, chi-square, nonparametric tests)
- Fit probability distributions to data (40+ supported distributions)
- Compute descriptive statistics (mean, variance, quantiles, correlation)
- Conduct survival analysis (Kaplan-Meier, Cox regression)
- Design experiments (factorial, fractional factorial, response surface)

**Machine Learning - Classification:**
- Build classifiers (SVM, decision trees, random forests, ensemble methods)
- Train neural networks for classification tasks
- Perform multiclass classification using ECOC (error-correcting output codes)
- Optimize hyperparameters using Bayesian optimization
- Interpret models using LIME, Shapley values, and partial dependence plots

**Machine Learning - Regression:**
- Fit linear and nonlinear regression models
- Train Gaussian Process Regression (GPR) models
- Build ensemble regression models (boosting, bagging)
- Perform regularized regression (Lasso, Ridge, Elastic Net)
- Implement stepwise and robust regression

**Clustering and Dimensionality Reduction:**
- Cluster data using k-means, hierarchical, and Gaussian mixture models
- Perform principal component analysis (PCA) and factor analysis
- Apply t-SNE and UMAP for visualization
- Conduct discriminant analysis (linear, quadratic)

**Biomedical Applications:**
- Analyze clinical trial data and patient outcomes
- Discover biomarkers through feature selection
- Build diagnostic classification models
- Perform survival analysis for time-to-event data
- Implement incremental learning for streaming medical data

### Trigger Conditions

Activate this skill when encountering:
- Questions about MATLAB statistical functions (e.g., `fitlm`, `fitcsvm`, `kmeans`)
- Requests to fit probability distributions or perform hypothesis tests
- Machine learning model training and evaluation in MATLAB
- Cross-validation and model selection tasks
- Feature selection and dimensionality reduction
- Time series analysis and forecasting
- Bayesian inference and MCMC sampling

## Key Concepts

### Probability Distribution Framework

The toolbox provides three ways to work with distributions:

1. **Distribution Objects** - Created with `makedist` or `fitdist`:
   ```matlab
   pd = fitdist(data, 'Normal');       % Fit normal distribution
   pd = makedist('Weibull', 'a', 5);   % Create with parameters
   ```

2. **Distribution Fitter App** - Interactive GUI for distribution fitting:
   ```matlab
   distributionFitter  % Launch the app
   ```

3. **Distribution-Specific Functions** - Direct computation:
   ```matlab
   p = normcdf(x, mu, sigma);    % Normal CDF
   r = wblrnd(a, b, [100,1]);    % Weibull random numbers
   ```

### Machine Learning Model Framework

The toolbox uses a consistent object-oriented approach:

| Task | Training Function | Prediction Function |
|------|-------------------|---------------------|
| Binary Classification | `fitcsvm`, `fitctree` | `predict` |
| Multiclass Classification | `fitcecoc`, `fitcensemble` | `predict` |
| Regression | `fitlm`, `fitrensemble`, `fitrgp` | `predict` |
| Clustering | `fitgmdist`, `linkage` | `cluster` |

### Cross-Validation Patterns

```matlab
% K-Fold Cross-Validation
cv = cvpartition(y, 'KFold', 10);
Mdl = fitcsvm(X, y, 'CVPartition', cv);
loss = kfoldLoss(Mdl);

% Holdout Validation
cv = cvpartition(y, 'Holdout', 0.3);
Mdl = fitctree(X(training(cv),:), y(training(cv)));
accuracy = 1 - loss(Mdl, X(test(cv),:), y(test(cv)));
```

### Hyperparameter Optimization

```matlab
% Using Bayesian Optimization with fit functions
Mdl = fitcsvm(X, y, 'OptimizeHyperparameters', 'auto', ...
    'HyperparameterOptimizationOptions', struct('AcquisitionFunctionName', ...
    'expected-improvement-plus'));

% Using bayesopt directly
results = bayesopt(@objectiveFcn, hyperparameters, ...
    'MaxObjectiveEvaluations', 30);
```

## Quick Reference

### Descriptive Statistics

```matlab
% Central tendency and dispersion
m = mean(data);              % Arithmetic mean
med = median(data);          % Median
s = std(data);               % Standard deviation
v = var(data);               % Variance
iqr_val = iqr(data);         % Interquartile range

% Summary by group
stats = grpstats(data, groups, {'mean', 'std', 'sem'});

% Correlation and covariance
R = corrcoef(X);             % Correlation matrix
C = cov(X);                  % Covariance matrix
```

### Hypothesis Testing

```matlab
% Two-sample t-test
[h, p, ci, stats] = ttest2(sample1, sample2);

% One-way ANOVA
[p, tbl, stats] = anova1(data, groups);

% Multiple comparison (post-hoc)
[c, m, h, gnames] = multcompare(stats);

% Chi-square test for independence
[h, p, stats] = chi2gof(data);

% Nonparametric tests
p = ranksum(sample1, sample2);      % Wilcoxon rank sum
p = signrank(paired_diff);           % Signed rank test
p = kruskalwallis(data, groups);     % Kruskal-Wallis
```

### Classification Models

```matlab
% Support Vector Machine
Mdl = fitcsvm(X, y, 'KernelFunction', 'rbf', 'BoxConstraint', 1);

% Decision Tree
tree = fitctree(X, y, 'MaxNumSplits', 20);

% Random Forest (ensemble of trees)
forest = fitcensemble(X, y, 'Method', 'Bag', 'NumLearningCycles', 100);

% Gradient Boosting
boost = fitcensemble(X, y, 'Method', 'AdaBoostM1');

% k-Nearest Neighbors
knn = fitcknn(X, y, 'NumNeighbors', 5);

% Naive Bayes
nb = fitcnb(X, y, 'DistributionNames', 'kernel');

% Neural Network
nn = fitcnet(X, y, 'LayerSizes', [100 50], 'Activations', 'relu');
```

### Regression Models

```matlab
% Linear Regression
mdl = fitlm(X, y);                              % Simple linear
mdl = fitlm(tbl, 'y ~ x1 + x2 + x1:x2');       % With formula

% Generalized Linear Model
mdl = fitglm(X, y, 'Distribution', 'poisson', 'Link', 'log');

% Gaussian Process Regression
gpr = fitrgp(X, y, 'KernelFunction', 'squaredexponential');

% Support Vector Regression
svm = fitrsvm(X, y, 'KernelFunction', 'gaussian', 'Epsilon', 0.1);

% Ensemble Regression
ens = fitrensemble(X, y, 'Method', 'LSBoost', 'NumLearningCycles', 100);

% Regularized Regression (Lasso)
[B, FitInfo] = lasso(X, y, 'CV', 10);
idxLambda1SE = FitInfo.Index1SE;
coef = B(:, idxLambda1SE);
```

### Clustering

```matlab
% K-Means Clustering
[idx, C, sumd] = kmeans(X, k, 'Replicates', 10);

% Hierarchical Clustering
Z = linkage(X, 'ward');
idx = cluster(Z, 'MaxClust', k);
dendrogram(Z);

% Gaussian Mixture Model
gm = fitgmdist(X, k, 'RegularizationValue', 0.01);
idx = cluster(gm, X);
P = posterior(gm, X);

% DBSCAN
idx = dbscan(X, epsilon, minpts);

% Spectral Clustering
idx = spectralcluster(X, k);
```

### Dimensionality Reduction

```matlab
% Principal Component Analysis
[coeff, score, latent, tsquared, explained] = pca(X);
X_reduced = score(:, 1:numComponents);

% t-SNE for visualization
Y = tsne(X, 'NumDimensions', 2, 'Perplexity', 30);

% Factor Analysis
[Lambda, Psi, T, stats] = factoran(X, numFactors);

% Linear Discriminant Analysis
Mdl = fitcdiscr(X, y);
[W, LAMBDA] = eig(Mdl.BetweenSigma, Mdl.Sigma);
```

### Model Evaluation

```matlab
% Classification metrics
[label, score] = predict(Mdl, Xtest);
accuracy = sum(label == ytest) / length(ytest);
confMat = confusionmat(ytest, label);
confusionchart(ytest, label);

% ROC Curve and AUC
[Xroc, Yroc, T, AUC] = perfcurve(ytest, score(:,2), positiveClass);
plot(Xroc, Yroc);

% Regression metrics
ypred = predict(Mdl, Xtest);
mse = mean((ytest - ypred).^2);
rmse = sqrt(mse);
r2 = 1 - sum((ytest - ypred).^2) / sum((ytest - mean(ytest)).^2);

% Cross-validation loss
cvMdl = crossval(Mdl, 'KFold', 10);
cvLoss = kfoldLoss(cvMdl);
```

### Distribution Fitting

```matlab
% Fit distribution to data
pd = fitdist(data, 'Normal');
pd = fitdist(data, 'Weibull');
pd = fitdist(data, 'Gamma');

% Evaluate fit
x_vals = linspace(min(data), max(data), 100);
y_pdf = pdf(pd, x_vals);
y_cdf = cdf(pd, x_vals);

% Compare distributions using AIC/BIC
pdNormal = fitdist(data, 'Normal');
pdWeibull = fitdist(data, 'Weibull');
% Note: Use negloglik() function, not .NegLogLikelihood property
aic_normal = negloglik(pdNormal) * 2 + 2 * pdNormal.NumParameters;
aic_weibull = negloglik(pdWeibull) * 2 + 2 * pdWeibull.NumParameters;

% Maximum Likelihood Estimation
phat = mle(data, 'distribution', 'Normal');
[phat, pci] = mle(data, 'distribution', 'Weibull');
```

### Survival Analysis

```matlab
% Kaplan-Meier Estimator
[f, x, flo, fup] = ecdf(T, 'censoring', censored, 'function', 'survivor');

% Cox Proportional Hazards
[b, logl, H, stats] = coxphfit(X, T, 'Censoring', censored);

% Compare two groups using Cox model (logrank is not built-in)
T = [T1; T2];
cens = [c1; c2];
group = [zeros(length(T1),1); ones(length(T2),1)];
[b, ~, ~, stats] = coxphfit(group, T, 'Censoring', cens);
p = stats.p;  % p-value for group effect
```

### Bayesian Methods

```matlab
% Hamiltonian Monte Carlo Sampling
logpdf = @(theta) logLikelihood(theta, data) + logPrior(theta);
smp = hmcSampler(logpdf, startpoint, 'NumSteps', 50);
[samples, accept] = drawSamples(smp, 'NumSamples', 1000, 'Burnin', 500);

% Bayesian Linear Regression
% (using HMC for posterior sampling)
beta_samples = bayesLinearRegression(X, y, priorMean, priorCov);

% Slice Sampling
samples = slicesample(startpoint, numSamples, 'logpdf', logpdf);
```

## Toolbox Architecture

### Major Components

| Chapter | Topic | Key Functions |
|---------|-------|---------------|
| 1-3 | Data Organization & Descriptive Stats | `grpstats`, `tabulate`, `mean`, `std` |
| 4 | Statistical Visualization | `boxplot`, `ecdf`, `normplot`, `probplot` |
| 5 | Probability Distributions | `makedist`, `fitdist`, `pdf`, `cdf`, `random` |
| 6 | Gaussian Processes | `fitrgp`, `predict`, `compact` |
| 7 | Random Number Generation | `random`, `randn`, `rng`, `qrandstream` |
| 8-9 | Hypothesis Tests & ANOVA | `ttest`, `anova1`, `anovan`, `multcompare` |
| 10 | Bayesian Optimization | `bayesopt`, `optimizableVariable` |
| 11-12 | Regression Analysis | `fitlm`, `fitglm`, `stepwiselm`, `lasso` |
| 13-15 | Multivariate Methods | `pca`, `factoran`, `cmdscale`, `canoncorr` |
| 16-17 | Cluster Analysis | `kmeans`, `linkage`, `fitgmdist`, `dbscan` |
| 18 | Discriminant Analysis | `fitcdiscr`, `classify`, `mahal` |
| 19-22 | Ensemble Methods & Trees | `fitcensemble`, `fitrensemble`, `TreeBagger` |
| 23-24 | Classification/Regression Learner Apps | Interactive ML training |
| 25 | Support Vector Machines | `fitcsvm`, `fitrsvm`, `fitcecoc` |
| 26 | Fairness | Bias detection and mitigation |
| 27 | Interpretability | `shapley`, `lime`, `partialDependence` |
| 28 | Incremental Learning | `incrementalClassificationLinear`, `fit`, `updateMetrics` |
| 29 | Markov Models | `hmmestimate`, `hmmtrain`, `hmmviterbi` |
| 30-31 | Design of Experiments | `fullfact`, `fracfact`, `ccdesign`, `daugment` |
| 32 | Neural Networks | `fitcnet`, `fitrnet`, `featureLayer` |
| 33-36 | Specialized Topics | Survival, copulas, feature selection |

### Apps and Interactive Tools

| App | Purpose | Launch Command |
|-----|---------|----------------|
| **Classification Learner** | Train and compare classification models | `classificationLearner` |
| **Regression Learner** | Train and compare regression models | `regressionLearner` |
| **Distribution Fitter** | Fit distributions interactively | `distributionFitter` |
| **Statistics Live Editor Tasks** | Guided statistical analysis | Live Editor Tasks |

## Working with This Skill

### For Beginners

1. **Start with the Apps**: Use Classification Learner or Regression Learner for initial model exploration
2. **Learn the Object Pattern**: Most functions return model objects with `predict`, `loss`, and `compact` methods
3. **Use Tables**: Prefer MATLAB tables for data organization - they integrate well with formula syntax
4. **Validate Early**: Always split data or use cross-validation from the start

### For Intermediate Users

1. **Explore Hyperparameter Optimization**: Use `'OptimizeHyperparameters', 'auto'` to automate tuning
2. **Understand Model Diagnostics**: Learn to interpret residual plots, Cook's distance, and leverage
3. **Compare Multiple Models**: Use the learner apps to systematically compare model types
4. **Feature Engineering**: Combine domain knowledge with automated feature selection

### For Advanced Users

1. **Custom Kernels and Loss Functions**: Implement custom kernels for SVM or loss functions for ensembles
2. **Incremental Learning**: Use `incrementalClassificationLinear` for streaming data
3. **Model Interpretation**: Apply Shapley values and LIME for black-box model explanation
4. **Parallel Computing**: Enable parallel processing for cross-validation and hyperparameter search
5. **Code Generation**: Export models for deployment using MATLAB Compiler or Coder

### Biomedical Research Workflow

```matlab
%% 1. Load and explore clinical data
data = readtable('patient_data.csv');
summary(data);
grpstats(data, 'Diagnosis', {'mean', 'std'});

%% 2. Handle missing data
data = rmmissing(data);  % or use fillmissing(data, 'knn') for imputation

%% 3. Feature selection
[idx, scores] = fscmrmr(data(:, predictors), data.Diagnosis);
selectedFeatures = predictors(idx(1:10));

%% 4. Train classifier with cross-validation
cv = cvpartition(data.Diagnosis, 'KFold', 5);
Mdl = fitcensemble(data(:, selectedFeatures), data.Diagnosis, ...
    'Method', 'Bag', 'NumLearningCycles', 100, 'CVPartition', cv);

%% 5. Evaluate performance
cvLoss = kfoldLoss(Mdl);
[label, score] = kfoldPredict(Mdl);
[X, Y, T, AUC] = perfcurve(data.Diagnosis, score(:,2), 'Positive');

%% 6. Interpret model
Mdl_final = fitcensemble(data(:, selectedFeatures), data.Diagnosis, ...
    'Method', 'Bag', 'NumLearningCycles', 100);
explainer = shapley(Mdl_final, data(:, selectedFeatures));
plot(explainer);
```

## Reference Files

### Main Reference

- **`references/stats_ml_userguide.md`** - Complete Statistics and Machine Learning Toolbox User's Guide (R2025b)
  - Source: Official MathWorks PDF documentation
  - Coverage: 12,806 pages of comprehensive documentation
  - Content: All 36 chapters covering statistical methods, ML algorithms, and applications
  - Code Examples: 32,824 code blocks demonstrating practical usage

### Navigation Guide

The reference file is organized by chapter with the following structure:

| Chapters | Topics |
|----------|--------|
| 1-3 | Getting Started, Organizing Data, Descriptive Statistics |
| 4-7 | Visualization, Probability Distributions, Random Numbers |
| 8-12 | Hypothesis Tests, ANOVA, Bayesian Optimization, Regression |
| 13-18 | Multivariate Analysis, Clustering, Discriminant Analysis |
| 19-27 | Machine Learning (Ensembles, Trees, SVM, Interpretability) |
| 28-36 | Advanced Topics (Incremental Learning, DOE, Neural Networks, Survival) |

## Documentation Statistics

| Metric | Value |
|--------|-------|
| Total Pages | 12,806 |
| Code Blocks | 32,824 |
| Images/Diagrams | 3,921 |
| Average Code Quality | 8.5/10 |
| Valid Code Blocks | 32,054 |

**Note on Language Detection:** The automatic code language detection may show languages like "julia", "typescript", or "sql" for some MATLAB code blocks. This is because MATLAB syntax shares patterns with these languages. All code in this documentation is MATLAB code - use `matlab` syntax highlighting when copying examples.

## Common Patterns and Best Practices

### Data Preparation Checklist

```matlab
% 1. Check for missing values
sum(ismissing(data))

% 2. Check data types
varfun(@class, data)

% 3. Normalize/standardize features
X_norm = normalize(X);  % z-score normalization
X_scaled = rescale(X);  % min-max scaling to [0,1]

% 4. Handle categorical variables
X_encoded = dummyvar(categorical(X_cat));

% 5. Split data
cv = cvpartition(y, 'Holdout', 0.2);
X_train = X(training(cv), :);
X_test = X(test(cv), :);
```

### Model Selection Workflow

```matlab
% Compare multiple models using cross-validation
models = {'Tree', 'SVM', 'Ensemble', 'KNN'};
cvLosses = zeros(length(models), 1);

cv = cvpartition(y, 'KFold', 10);

cvLosses(1) = kfoldLoss(crossval(fitctree(X, y), 'CVPartition', cv));
cvLosses(2) = kfoldLoss(crossval(fitcsvm(X, y), 'CVPartition', cv));
cvLosses(3) = kfoldLoss(crossval(fitcensemble(X, y), 'CVPartition', cv));
cvLosses(4) = kfoldLoss(crossval(fitcknn(X, y), 'CVPartition', cv));

bar(categorical(models), cvLosses);
ylabel('Cross-Validation Loss');
```

### Memory-Efficient Training for Large Datasets

```matlab
% Use tall arrays for out-of-memory data
ds = datastore('large_data/*.csv');
tt = tall(ds);

% Fit models that support tall arrays
Mdl = fitclinear(tt(:, predictors), tt.Response);

% Or use incremental learning
Mdl = incrementalClassificationLinear('Solver', 'sgd');
for chunk = 1:numChunks
    [X_chunk, y_chunk] = getNextChunk();
    Mdl = fit(Mdl, X_chunk, y_chunk);
end
```

## See Also (Cross-Toolbox Skills)

- **matlab-image-processing-toolbox** - For image-based feature extraction
- **matlab-deep-learning** - For deep neural networks (CNN, U-Net, YOLO)
- **matlab-wavelet-toolbox** - For multiresolution feature extraction
- **matlab-medical-imaging-toolbox** - For medical data I/O and radiomics
- **matlab-performance-optimizer** - For optimizing model training speed

---

**Generated by Skill Seeker** | PDF Documentation Scraper | MATLAB Statistics and Machine Learning Toolbox R2025b

*This skill synthesizes knowledge from the official MathWorks documentation to provide expert guidance on statistical analysis and machine learning in MATLAB.*
