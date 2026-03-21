# Clinical Trial Survival Analysis — With Skill

## Prompt
"Write a complete clinical trial survival pipeline: use knnimpute for missing data, log-rank test to compare treatment groups, and compare parametric models using NegLogLikelihood."

## Skill Consultation
The agent consulted:
- `matlab-stats-ml-v2/SKILL.md` — Critical Rules section
- `matlab-stats-ml-v2/knowledge/cards/survival-analysis.md` — Full survival analysis card

## Key API Decisions (Guided by Skill)
1. **`fillmissing(X, 'knn')`** instead of `knnimpute` — the latter requires Bioinformatics Toolbox
2. **`coxphfit`** with group covariate instead of `logrank()` — which does not exist in MATLAB
3. **`negloglik(pd)`** function instead of `pd.NegLogLikelihood` property — the property doesn't exist

## Three Traps Avoided
| Trap | Hallucinated | Correct |
|------|-------------|---------|
| KNN imputation | `knnimpute(X)` | `fillmissing(X, 'knn')` |
| Log-rank test | `logrank(...)` | `coxphfit(group, time, ...)` |
| Neg log-likelihood | `pd.NegLogLikelihood` | `negloglik(pd)` |

## Additional Clinical Depth
- Hazard ratio with 95% CI and clinical significance threshold (HR > 1.5)
- Proportional hazards assumption check via log-log plot
- Number-at-risk table at key timepoints
- Four parametric model comparison (Weibull, Exponential, Lognormal, Loglogistic)

## Output
- 210-line clinical-grade pipeline
- Kaplan-Meier with confidence intervals and censoring marks
- Complete Cox regression with interpretation
