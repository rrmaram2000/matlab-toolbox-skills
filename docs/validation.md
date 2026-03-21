# Validation Methodology

How we tested these skills against MATLAB R2025b.

## Blind A/B Evaluation

Each skill was tested using **17 real-world prompts** in a blind comparison:

1. The same prompt was given to Claude twice — once with the skill loaded, once without
2. The evaluator did not know which output had the skill
3. Each output was graded on **correctness** (API accuracy, runtime viability) and **domain depth** (clinical best practices, production readiness)

### Grading Criteria

| Dimension | What It Measures |
|:----------|:-----------------|
| API correctness | Do all functions exist in R2025b? Are signatures right? |
| Runtime viability | Would this code execute without errors? |
| Domain depth | Does it follow clinical/scientific best practices? |
| Completeness | Full workflow or missing critical steps? |

## Runtime Verification

Every API claim in the skills was tested against a live MATLAB R2025b installation:

- **Function existence** — `which('functionName')` for every function referenced in knowledge cards
- **Parameter validation** — verified function signatures, required arguments, default values
- **Default values** — confirmed defaults match documentation (e.g., `unet` uses 64 filters, not 32)

Results are stored in `test-results/runtime-verification/`:
- `function-existence.json` — 100+ functions verified
- `parameter-validation.json` — signature checks
- `default-values.json` — default parameter confirmation

## Key Findings

### Hallucinations Caught

8 hallucinated functions across the 5 tested examples — all confirmed non-existent in R2025b:

| Hallucinated API | Correct API | Toolbox |
|:-----------------|:------------|:--------|
| `medicalSAM` | `medicalSegmentAnythingModel` | Medical Imaging |
| `imageEmbeddings` | `extractEmbeddings` | Medical Imaging |
| `mat2clim` | `mat2gray` | Medical Imaging |
| `trainMaskRCNNObjectDetector` | `maskrcnn` + `trainMaskRCNN` | Deep Learning |
| `modwt2` / `imodwt2` | `wavedec2` / `waverec2` | Wavelet |
| `knnimpute` | `fillmissing(X, 'knn')` | Stats-ML |
| `logrank` | `coxphfit` | Stats-ML |
| `pd.NegLogLikelihood` | `negloglik(pd)` | Stats-ML |

### Domain Depth Improvements

Even when the base model gets the API right, skills add methodology that domain experts expect:

- **Wavelet fusion**: Multi-level `wavedec2` with separate fusion rules per coefficient type vs single-level `dwt2` with naive averaging
- **Stain normalization**: Full Macenko algorithm (OD-space, PCA, percentile angles, stain deconvolution) vs histogram matching
- **Survival analysis**: Hazard ratio CIs, proportional hazards check, number-at-risk tables vs basic Cox output
- **MRI filtering**: Rician noise model (physically correct) vs Gaussian noise (wrong for MRI)

## Data

Raw evaluation data is available in `test-results/`:
- `blind-comparison/` — benchmark results and per-prompt JSON grades
- `runtime-verification/` — MATLAB R2025b API verification proofs
- `methodology.md` — detailed evaluation protocol
- 5 tested example directories with full with-skill and without-skill scripts
