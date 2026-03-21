# Regression — Clinical Outcome Modeling

The model already knows `fitlm`, `fitglm`, `fitrgp`, `fitrensemble`, `fitrsvm`, `fitrnet`, `lasso`, `ridge`, `stepwiselm`, cross-validation, and regression metrics. This card covers only clinical-specific patterns.

## Clinical Regression Selection

```
Clinical outcome prediction?
├── Continuous outcome (blood pressure, lab value)
│   ├── Small dataset, interpretability needed → fitlm with formula
│   └── Complex nonlinear → fitrgp (gives uncertainty bounds!)
├── Binary outcome (disease yes/no)
│   ├── Odds ratios needed → fitglm('Distribution','binomial')
│   └── Just prediction → fitcsvm or fitcensemble
├── Count outcome (number of events, hospital visits)
│   └── fitglm('Distribution','poisson')
├── Positive continuous (costs, survival times)
│   └── fitglm('Distribution','gamma','Link','log')
├── Many correlated biomarkers
│   └── lasso or elasticnet (feature selection + prediction)
└── Need uncertainty for clinical decision
    └── fitrgp — provides prediction intervals
```

## Logistic Regression for Clinical Outcomes

The key clinical pattern: computing and reporting odds ratios with confidence intervals.

```matlab
% Logistic regression with odds ratios
mdl = fitglm(tbl, 'outcome ~ age + treatment + age:treatment', ...
    'Distribution', 'binomial');

% Odds ratios and CIs (the clinical reporting standard)
coef = mdl.Coefficients.Estimate;
se = mdl.Coefficients.SE;
OR = exp(coef);
CI_low = exp(coef - 1.96 * se);
CI_high = exp(coef + 1.96 * se);

% Forest plot-style reporting
varNames = mdl.CoefficientNames';
T = table(varNames, OR, CI_low, CI_high, mdl.Coefficients.pValue, ...
    'VariableNames', {'Variable', 'OddsRatio', 'CI_Lower', 'CI_Upper', 'pValue'});
disp(T);
```

## Gaussian Process Regression for Clinical Uncertainty

GPR is underused in clinical research but provides prediction intervals — critical for clinical decisions.

```matlab
% Predict patient outcome with uncertainty bounds
gprMdl = fitrgp(XTrain, yTrain, ...
    'KernelFunction', 'ardsquaredexponential', ...
    'Standardize', true);

[ypred, ysd, yint] = predict(gprMdl, XTest);
% ypred: point prediction
% ysd: standard deviation (uncertainty)
% yint: 95% prediction intervals

% Flag high-uncertainty predictions for clinical review
highUncertainty = ysd > threshold;
fprintf('%d/%d predictions flagged for clinical review\n', ...
    sum(highUncertainty), length(highUncertainty));
```

## LASSO for Biomarker Selection

```matlab
% Identify which biomarkers predict outcome
[B, FitInfo] = lasso(X, y, 'CV', 10);

% 1SE rule: most parsimonious model within 1 SE of minimum error
coef_1SE = B(:, FitInfo.Index1SE);
selectedBiomarkers = find(coef_1SE ~= 0);
fprintf('Selected %d/%d biomarkers\n', length(selectedBiomarkers), size(X,2));

% Predict using selected biomarkers
yhat = X(:, selectedBiomarkers) * coef_1SE(selectedBiomarkers) + ...
    FitInfo.Intercept(FitInfo.Index1SE);
```

## Multicollinearity Check (Common in Clinical Variables)

```matlab
% Clinical variables are often correlated (e.g., BMI, weight, waist circumference)
R = corrcoef(X);

% Variance Inflation Factor
mdl = fitlm(X, y);
VIF = diag(inv(corrcoef(X)));
% VIF > 10 = severe multicollinearity → use ridge/LASSO or remove variables
fprintf('Max VIF: %.1f\n', max(VIF));
```

---

*See also: scripts/template_glm_regression.m, scripts/template_distribution_fitting.m*
