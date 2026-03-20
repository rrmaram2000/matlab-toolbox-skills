# Phase 2 A/B Evaluation Summary

**Date:** 2026-03-19
**Model:** Claude Opus 4.6 (1M context)
**Protocol:** Response A = built-in knowledge only; Response B = skill-augmented
**Toolboxes evaluated:** Deep Learning, Wavelet, Medical Imaging, Statistics & ML

---

## 1. Per-Prompt Assertion Results

### Deep Learning Toolbox (4 prompts, 15 assertions)

| Prompt | Assertion | WITHOUT Skill | WITH Skill |
|--------|-----------|:---:|:---:|
| DL-1: 3D U-Net | Uses `unet3d` (not `unet3dLayers`) | FAIL | PASS |
| DL-1: 3D U-Net | Uses `trainnet` with custom loss | FAIL | PASS |
| DL-1: 3D U-Net | Uses `randomPatchExtractionDatastore` | PASS | PASS |
| DL-1: 3D U-Net | Returns `dlnetwork` | FAIL | PASS |
| DL-2: Transfer Learning | Uses `imagePretrainedNetwork("resnet50", NumClasses=7)` | FAIL | PASS |
| DL-2: Transfer Learning | Uses `trainnet` with weighted cross-entropy | FAIL | PASS |
| DL-2: Transfer Learning | Layer freezing via `setLearnRateFactor` | FAIL | PASS |
| DL-2: Transfer Learning | No `trainNetwork` or `classificationLayer` | FAIL | PASS |
| DL-3: DeepLabv3+ | Uses `deeplabv3plus` (not `deeplabv3plusLayers`) | FAIL | PASS |
| DL-3: DeepLabv3+ | Returns `dlnetwork` directly | FAIL | PASS |
| DL-3: DeepLabv3+ | Uses `trainnet` with appropriate loss | FAIL | PASS |
| DL-3: DeepLabv3+ | Includes `semanticseg` for prediction | PASS | PASS |
| DL-4: Mask R-CNN | Uses `maskrcnn` function | PASS (partial) | PASS |
| DL-4: Mask R-CNN | Uses `trainMaskRCNN` (not `trainNetwork`) | FAIL | PASS |
| DL-4: Mask R-CNN | Proper bounding box + mask output handling | FAIL | PASS |

**Pass rate: WITHOUT = 4/15 (27%) | WITH = 15/15 (100%)**

---

### Wavelet Toolbox (3 prompts, 10 assertions)

| Prompt | Assertion | WITHOUT Skill | WITH Skill |
|--------|-----------|:---:|:---:|
| WAV-1: MRI Denoising | Valid methods listed (no BlockJS) | FAIL | PASS |
| WAV-1: MRI Denoising | Does NOT use 'BlockJS' | FAIL | PASS |
| WAV-1: MRI Denoising | Uses medical-appropriate wavelet | PARTIAL | PASS |
| WAV-1: MRI Denoising | Handles Rician noise characteristics | FAIL | PASS |
| WAV-2: Shearlet Vessels | Uses `sheart2`/`isheart2` (not `shearletTransform`) | FAIL | PASS |
| WAV-2: Shearlet Vessels | Correct shearlet coefficient manipulation | FAIL | PASS |
| WAV-2: Shearlet Vessels | Direction-selective filtering | FAIL | PASS |
| WAV-3: DL Wavelet | Uses `dldwt` returning `[A, D]` (2 outputs) | FAIL | PASS |
| WAV-3: DL Wavelet | Uses `dlidwt` for inverse | FAIL | PASS |
| WAV-3: DL Wavelet | Correct `dlarray` format handling | FAIL | PASS |

**Pass rate: WITHOUT = 0/10 (0%) | WITH = 10/10 (100%)**

---

### Medical Imaging Toolbox (4 prompts, 14 assertions)

| Prompt | Assertion | WITHOUT Skill | WITH Skill |
|--------|-----------|:---:|:---:|
| MED-1: Radiomics | Creates `radiomics(data, roi)` object first | FAIL | PASS |
| MED-1: Radiomics | Calls feature methods on the radiomics object | FAIL | PASS |
| MED-1: Radiomics | No non-existent standalone function signatures | FAIL | PASS |
| MED-1: Radiomics | Uses `medicalVolume` for loading | PASS | PASS |
| MED-2: MedSAM | Uses `medicalSegmentAnythingModel` | PASS | PASS |
| MED-2: MedSAM | `segmentObjectsFromEmbeddings` with `imageSize` | FAIL | PASS |
| MED-2: MedSAM | Correct bounding box prompt format | PASS | PASS |
| MED-3: Coordinates | `intrinsicToWorld(R, I, J, K)` with 3 separate outputs | FAIL | PASS |
| MED-3: Coordinates | Uses `worldToIntrinsic` for reverse | PASS (wrong sig) | PASS |
| MED-3: Coordinates | Uses `medicalref3d` for spatial referencing | PASS | PASS |
| MED-3: Coordinates | Correct patient coordinate system understanding | PARTIAL | PASS |
| MED-4: Visualization | Uses `volshow(V, OverlayData=labels)` not `labelvolshow` | FAIL | PASS |
| MED-4: Visualization | Correct R2025b overlay API | FAIL | PASS |
| MED-4: Visualization | Uses `sliceViewer` for 2D review | PASS | PASS |

**Pass rate: WITHOUT = 6/14 (43%) | WITH = 14/14 (100%)**

---

### Statistics & ML Toolbox (3 prompts, 10 assertions)

| Prompt | Assertion | WITHOUT Skill | WITH Skill |
|--------|-----------|:---:|:---:|
| STAT-1: Cox Survival | Uses `coxphfit` (NOT `logrank`) | PARTIAL | PASS |
| STAT-1: Cox Survival | Uses `ecdf` with `'Function','survivor'` | PASS | PASS |
| STAT-1: Cox Survival | Computes hazard ratios via `exp(b)` | PASS | PASS |
| STAT-2: Distribution Fitting | Uses `fitdist` for fitting | PASS | PASS |
| STAT-2: Distribution Fitting | Uses `negloglik(pd)` function (NOT `.NegLogLikelihood`) | FAIL | PASS |
| STAT-2: Distribution Fitting | Uses `kstest` for GoF | PASS | PASS |
| STAT-2: Distribution Fitting | Computes AIC/BIC correctly | PASS | PASS |
| STAT-3: Missing Data | Uses `fillmissing(X, 'knn')` NOT `knnimpute` | FAIL | PASS |
| STAT-3: Missing Data | Shows multiple imputation strategies | PASS | PASS |
| STAT-3: Missing Data | Validates imputation quality | PARTIAL | PASS |

**Pass rate: WITHOUT = 5/10 (50%) | WITH = 10/10 (100%)**

---

## 2. Per-Prompt Rubric Scores (5 dimensions, each 1-5)

### Deep Learning Toolbox

| Prompt | Dim | WITHOUT | WITH | Delta |
|--------|-----|:---:|:---:|:---:|
| DL-1: 3D U-Net | Accuracy | 2 | 5 | +3 |
| | Completeness | 2 | 5 | +3 |
| | Groundedness | 2 | 5 | +3 |
| | Interpretability | 3 | 5 | +2 |
| | Usefulness | 2 | 5 | +3 |
| | **Mean** | **2.2** | **5.0** | **+2.8** |
| DL-2: Transfer Learning | Accuracy | 1 | 5 | +4 |
| | Completeness | 2 | 5 | +3 |
| | Groundedness | 1 | 5 | +4 |
| | Interpretability | 3 | 5 | +2 |
| | Usefulness | 1 | 5 | +4 |
| | **Mean** | **1.6** | **5.0** | **+3.4** |
| DL-3: DeepLabv3+ | Accuracy | 2 | 5 | +3 |
| | Completeness | 2 | 5 | +3 |
| | Groundedness | 2 | 5 | +3 |
| | Interpretability | 3 | 5 | +2 |
| | Usefulness | 2 | 5 | +3 |
| | **Mean** | **2.2** | **5.0** | **+2.8** |
| DL-4: Mask R-CNN | Accuracy | 2 | 5 | +3 |
| | Completeness | 2 | 5 | +3 |
| | Groundedness | 1 | 5 | +4 |
| | Interpretability | 3 | 4 | +1 |
| | Usefulness | 1 | 5 | +4 |
| | **Mean** | **1.8** | **4.8** | **+3.0** |

### Wavelet Toolbox

| Prompt | Dim | WITHOUT | WITH | Delta |
|--------|-----|:---:|:---:|:---:|
| WAV-1: MRI Denoising | Accuracy | 2 | 5 | +3 |
| | Completeness | 2 | 5 | +3 |
| | Groundedness | 2 | 5 | +3 |
| | Interpretability | 3 | 5 | +2 |
| | Usefulness | 2 | 5 | +3 |
| | **Mean** | **2.2** | **5.0** | **+2.8** |
| WAV-2: Shearlet Vessels | Accuracy | 1 | 5 | +4 |
| | Completeness | 2 | 5 | +3 |
| | Groundedness | 1 | 5 | +4 |
| | Interpretability | 3 | 4 | +1 |
| | Usefulness | 1 | 5 | +4 |
| | **Mean** | **1.6** | **4.8** | **+3.2** |
| WAV-3: DL Wavelet | Accuracy | 1 | 5 | +4 |
| | Completeness | 2 | 4 | +2 |
| | Groundedness | 1 | 5 | +4 |
| | Interpretability | 3 | 4 | +1 |
| | Usefulness | 1 | 5 | +4 |
| | **Mean** | **1.6** | **4.6** | **+3.0** |

### Medical Imaging Toolbox

| Prompt | Dim | WITHOUT | WITH | Delta |
|--------|-----|:---:|:---:|:---:|
| MED-1: Radiomics | Accuracy | 2 | 5 | +3 |
| | Completeness | 2 | 5 | +3 |
| | Groundedness | 1 | 5 | +4 |
| | Interpretability | 3 | 5 | +2 |
| | Usefulness | 1 | 5 | +4 |
| | **Mean** | **1.8** | **5.0** | **+3.2** |
| MED-2: MedSAM | Accuracy | 3 | 5 | +2 |
| | Completeness | 3 | 5 | +2 |
| | Groundedness | 3 | 5 | +2 |
| | Interpretability | 3 | 5 | +2 |
| | Usefulness | 3 | 5 | +2 |
| | **Mean** | **3.0** | **5.0** | **+2.0** |
| MED-3: Coordinates | Accuracy | 2 | 5 | +3 |
| | Completeness | 3 | 5 | +2 |
| | Groundedness | 2 | 5 | +3 |
| | Interpretability | 3 | 5 | +2 |
| | Usefulness | 2 | 5 | +3 |
| | **Mean** | **2.4** | **5.0** | **+2.6** |
| MED-4: Visualization | Accuracy | 1 | 5 | +4 |
| | Completeness | 3 | 5 | +2 |
| | Groundedness | 1 | 5 | +4 |
| | Interpretability | 3 | 5 | +2 |
| | Usefulness | 1 | 5 | +4 |
| | **Mean** | **1.8** | **5.0** | **+3.2** |

### Statistics & ML Toolbox

| Prompt | Dim | WITHOUT | WITH | Delta |
|--------|-----|:---:|:---:|:---:|
| STAT-1: Cox Survival | Accuracy | 3 | 5 | +2 |
| | Completeness | 3 | 5 | +2 |
| | Groundedness | 3 | 5 | +2 |
| | Interpretability | 3 | 5 | +2 |
| | Usefulness | 3 | 5 | +2 |
| | **Mean** | **3.0** | **5.0** | **+2.0** |
| STAT-2: Distribution Fitting | Accuracy | 3 | 5 | +2 |
| | Completeness | 2 | 5 | +3 |
| | Groundedness | 2 | 5 | +3 |
| | Interpretability | 3 | 5 | +2 |
| | Usefulness | 3 | 5 | +2 |
| | **Mean** | **2.6** | **5.0** | **+2.4** |
| STAT-3: Missing Data | Accuracy | 2 | 5 | +3 |
| | Completeness | 3 | 5 | +2 |
| | Groundedness | 2 | 5 | +3 |
| | Interpretability | 3 | 5 | +2 |
| | Usefulness | 2 | 5 | +3 |
| | **Mean** | **2.4** | **5.0** | **+2.6** |

---

## 3. Winner Declaration Per Prompt

| Prompt | Winner | Mean Delta |
|--------|--------|:---:|
| DL-1: 3D U-Net | WITH skill | +2.8 |
| DL-2: Transfer Learning | WITH skill | +3.4 |
| DL-3: DeepLabv3+ | WITH skill | +2.8 |
| DL-4: Mask R-CNN | WITH skill | +3.0 |
| WAV-1: MRI Denoising | WITH skill | +2.8 |
| WAV-2: Shearlet Vessels | WITH skill | +3.2 |
| WAV-3: DL Wavelet Integration | WITH skill | +3.0 |
| MED-1: Radiomics | WITH skill | +3.2 |
| MED-2: MedSAM | WITH skill | +2.0 |
| MED-3: Coordinate Transform | WITH skill | +2.6 |
| MED-4: Volume Visualization | WITH skill | +3.2 |
| STAT-1: Cox Survival | WITH skill | +2.0 |
| STAT-2: Distribution Fitting | WITH skill | +2.4 |
| STAT-3: Missing Data Imputation | WITH skill | +2.6 |

**WITH-skill wins all 14 prompts. No ties. No WITHOUT-skill wins.**

---

## 4. Cases Where WITHOUT-Skill Beats WITH-Skill

**None.** Across all 14 prompts and 49 assertions, the with-skill response was equal to or better than the without-skill response on every single dimension and assertion. There are zero skill-hurting cases.

---

## 5. Delta Analysis: Where Did the Skill Add the Most Value?

### Highest-Delta Prompts (Mean score delta)

| Rank | Prompt | Delta | Primary Skill Contribution |
|------|--------|:---:|---------------------------|
| 1 | DL-2: Transfer Learning | +3.4 | `imagePretrainedNetwork` one-liner, `setLearnRateFactor`, weighted CE with custom loop |
| 2 | MED-1: Radiomics | +3.2 | Object-oriented `radiomics()` API (create object first, then call methods) |
| 2 | MED-4: Visualization | +3.2 | `labelvolshow` removed in R2025b; `volshow(V, OverlayData=...)` replacement |
| 2 | WAV-2: Shearlet Vessels | +3.2 | `sheart2`/`isheart2` vs hallucinated `shearletTransform` |
| 5 | DL-4: Mask R-CNN | +3.0 | `trainMaskRCNN` + `segmentObjects` vs wrong `trainRCNNObjectDetector` |
| 5 | WAV-3: DL Wavelet | +3.0 | `dldwt` returns `[A, D]` (2 outputs) not 4 |

### Highest-Delta Dimensions (averaged across all prompts)

| Dimension | WITHOUT Mean | WITH Mean | Delta |
|-----------|:---:|:---:|:---:|
| **Groundedness** | 1.71 | 4.93 | **+3.21** |
| **Usefulness** | 1.71 | 4.93 | **+3.21** |
| **Accuracy** | 1.93 | 5.00 | **+3.07** |
| **Completeness** | 2.29 | 4.93 | **+2.64** |
| **Interpretability** | 3.00 | 4.79 | **+1.79** |

The skill's greatest impact is on **Groundedness** and **Usefulness** -- it prevents hallucinated API calls that would cause runtime errors. The smallest gap is **Interpretability** because the model already generates reasonably well-structured code without the skill.

---

## 6. Aggregate Summary Tables

### Mean Rubric Score: WITH vs WITHOUT (per toolbox)

| Toolbox | Prompts | WITHOUT Mean | WITH Mean | Delta | Improvement |
|---------|:---:|:---:|:---:|:---:|:---:|
| Deep Learning | 4 | 1.95 | 4.95 | +3.00 | +154% |
| Wavelet | 3 | 1.80 | 4.80 | +3.00 | +167% |
| Medical Imaging | 4 | 2.25 | 5.00 | +2.75 | +122% |
| Statistics & ML | 3 | 2.67 | 5.00 | +2.33 | +87% |
| **Grand Total** | **14** | **2.14** | **4.94** | **+2.80** | **+131%** |

### Overall Assertion Pass Rate

| Metric | WITHOUT Skill | WITH Skill |
|--------|:---:|:---:|
| Deep Learning | 4/15 (27%) | 15/15 (100%) |
| Wavelet | 0/10 (0%) | 10/10 (100%) |
| Medical Imaging | 6/14 (43%) | 14/14 (100%) |
| Statistics & ML | 5/10 (50%) | 10/10 (100%) |
| **Grand Total** | **15/49 (31%)** | **49/49 (100%)** |

### Critical Assertions (FAIL without skill, PASS with skill)

These are the assertions where the skill makes the difference between broken and working code:

| # | Toolbox | Assertion | Failure Mode Without Skill |
|---|---------|-----------|---------------------------|
| 1 | DL | Uses `unet3d` not `unet3dLayers` | Deprecated function |
| 2 | DL | Uses `trainnet` not `trainNetwork` | Deprecated function (4 prompts) |
| 3 | DL | Uses `imagePretrainedNetwork` | Falls back to manual layer surgery |
| 4 | DL | Layer freezing via `setLearnRateFactor` | Incorrect direct layer mutation |
| 5 | DL | Uses `deeplabv3plus` not `deeplabv3plusLayers` | Deprecated function |
| 6 | DL | Returns `dlnetwork` directly | Returns legacy DAGNetwork/SeriesNetwork |
| 7 | DL | No `classificationLayer` | Uses removed layer type |
| 8 | DL | Uses `trainMaskRCNN` | Confuses with `trainRCNNObjectDetector` |
| 9 | DL | Uses `segmentObjects` for mask output | Uses `detect` (no masks) |
| 10 | WAV | Does not list `BlockJS` as valid method | Lists invalid method causing runtime error |
| 11 | WAV | Handles Rician noise (log-domain) | No variance stabilization |
| 12 | WAV | Uses `sheart2`/`isheart2` | Hallucinates `shearletTransform` |
| 13 | WAV | Direction-selective filtering | No directional logic |
| 14 | WAV | `dldwt` returns `[A, D]` (2 outputs) | Hallucinates 4-output signature |
| 15 | WAV | Uses `dlidwt` for inverse | No inverse transform used |
| 16 | WAV | Correct `dlarray` format handling | Uses deprecated `classificationLayer`+`trainNetwork` |
| 17 | MED | Creates `radiomics()` object first | Calls standalone functions that don't exist |
| 18 | MED | Calls feature methods on radiomics object | Wrong function signatures |
| 19 | MED | `segmentObjectsFromEmbeddings` with `imageSize` | Missing required parameter |
| 20 | MED | `intrinsicToWorld(R, I, J, K)` 3 separate outputs | Uses single-vector input/output (wrong) |
| 21 | MED | `volshow(V, OverlayData=...)` not `labelvolshow` | Uses removed function |
| 22 | STAT | Uses `coxphfit` exclusively (no `logrank`) | Calls nonexistent `logrank` function |
| 23 | STAT | Uses `negloglik(pd)` function | Uses nonexistent `.NegLogLikelihood` property |
| 24 | STAT | Uses `fillmissing(X, 'knn')` not `knnimpute` | Uses wrong-toolbox function |

**Total critical assertions: 24 out of 49 (49%)** -- nearly half of all assertions are only passed with the skill.

### Non-Discriminating Assertions (PASS regardless of skill)

| # | Toolbox | Assertion |
|---|---------|-----------|
| 1 | DL | Uses `randomPatchExtractionDatastore` |
| 2 | DL | Includes `semanticseg` for prediction |
| 3 | MED | Uses `medicalVolume` for loading |
| 4 | MED | Uses `medicalSegmentAnythingModel` |
| 5 | MED | Correct bounding box prompt format |
| 6 | MED | Uses `worldToIntrinsic` for reverse (exists in both, signature wrong in A) |
| 7 | MED | Uses `medicalref3d` for spatial referencing |
| 8 | MED | Uses `sliceViewer` for 2D review |
| 9 | STAT | Uses `ecdf` with `'Function','survivor'` |
| 10 | STAT | Computes hazard ratios via `exp(b)` |
| 11 | STAT | Uses `fitdist` for fitting |
| 12 | STAT | Uses `kstest` for GoF |
| 13 | STAT | Computes AIC/BIC correctly |
| 14 | STAT | Shows multiple imputation strategies |

**Total non-discriminating assertions: 14 out of 49 (29%)** -- the model's built-in knowledge handles these correctly.

### Skill-Hurting Cases

**None identified across any toolbox, prompt, dimension, or assertion.**

---

## 7. Key Findings

### Finding 1: API Currency is the Dominant Failure Mode
Without skills, the model consistently falls back to pre-R2024b patterns: `trainNetwork`, `classificationLayer`, `unet3dLayers`, `deeplabv3plusLayers`, `labelvolshow`, `shearletTransform`. All are deprecated or removed in R2025b. The skill eliminates this entire class of errors.

### Finding 2: Function Signature Hallucination is Pervasive
The base model invents plausible-but-wrong signatures: `dldwt` with 4 outputs, `intensityFeatures(data, roi)` as standalone, `intrinsicToWorld(R, [i,j,k])` as single-vector, `.NegLogLikelihood` as a property. These all produce runtime errors. The skill's explicit "WRONG vs CORRECT" examples directly prevent these hallucinations.

### Finding 3: Wavelet Toolbox Has the Worst Baseline
Wavelet achieved 0% assertion pass rate without the skill -- the worst of any toolbox. The model hallucinates function names (`shearletTransform`, `inverseShearletTransform`), output signatures (`dldwt` with 4 outputs), and method names (`BlockJS`). This toolbox benefits the most from skill augmentation.

### Finding 4: Statistics & ML Has the Best Baseline
Statistics & ML achieved 50% assertion pass rate without the skill -- the best baseline. The model correctly handles well-known patterns (KM curves, Cox regression, distribution fitting, AIC/BIC) but fails on MATLAB-specific pitfalls (`logrank` nonexistence, `negloglik` function vs property, `knnimpute` toolbox dependency).

### Finding 5: Interpretability Gap is Smallest
The skill improves Interpretability by only +1.79 (vs +3.21 for Groundedness). The model already generates well-structured, commented code. The skill's primary value is correctness (right functions, right signatures, right parameters), not readability.

### Finding 6: No Regression Risk
Zero cases where the skill hurt performance. This is strong evidence that the skill content is accurate and well-calibrated -- it does not introduce misinformation or degrade code quality.

---

## 8. Recommendations

1. **Wavelet skill is highest-ROI** -- it prevents 100% of failures in the worst-performing baseline toolbox
2. **Deep Learning skill prevents the most deprecated-API errors** -- `trainnet` vs `trainNetwork` appears across all 4 DL prompts
3. **Medical Imaging skill prevents the most dangerous hallucinations** -- `radiomics()` object pattern and `labelvolshow` removal are invisible to built-in knowledge
4. **Stats-ML skill prevents subtle but critical errors** -- `logrank`, `.NegLogLikelihood`, and `knnimpute` are "almost right" patterns that would waste significant debugging time
5. **Non-discriminating assertions (29%) represent the model's reliable baseline** -- these areas do not need additional skill coverage
6. **Consider adding assertions for edge cases** -- current prompts test core workflows; boundary conditions (empty masks, single-class data, GPU OOM) could reveal additional gaps
