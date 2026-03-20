# Clinical Trial Survival Analysis — Without Skill

## Prompt
"Write a complete clinical trial survival pipeline: use knnimpute for missing data, log-rank test to compare treatment groups, and compare parametric models using NegLogLikelihood."

## Three Hallucinations in One Script

### 1. `knnimpute` — NOT FOUND
```matlab
>> which('knnimpute')
'knnimpute' not found.
```
`knnimpute` requires the Bioinformatics Toolbox and is NOT available in the Statistics and Machine Learning Toolbox. The correct alternative is `fillmissing(X, 'knn')`.

### 2. `logrank` — NOT FOUND
```matlab
>> which('logrank')
'logrank' not found.
```
Despite being a standard statistical test, MATLAB does **not** have a `logrank` function. The equivalent is `coxphfit` with a single group covariate — the Wald test is equivalent to the log-rank test.

### 3. `pd.NegLogLikelihood` — Property Does NOT Exist
```matlab
>> pd = fitdist([1;2;3;4;5], 'Weibull');
>> pd.NegLogLikelihood
Error: Unrecognized method, property, or field 'NegLogLikelihood'
for class 'prob.WeibullDistribution'.
```
The correct API is the `negloglik(pd)` function, not a property on the distribution object.

## Verdict
**TRIPLE FAIL** — All three hallucinated APIs crash at runtime. The script cannot execute past Step 2 (`knnimpute`), and even if manually fixed, would crash again at Steps 4 (`logrank`) and 6 (`pd.NegLogLikelihood`). This is the most API-dense hallucination example in the collection.
