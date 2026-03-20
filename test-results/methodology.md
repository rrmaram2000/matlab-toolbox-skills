# Validation Methodology

**Date:** 2026-03-19
**MATLAB Version:** R2025b (25.2)
**Model:** Claude Opus 4.6 (1M context)

## Overview

This document describes the three-phase validation methodology used to evaluate the MATLAB Toolbox Skills. The goal was to produce verifiable, transparent evidence that the open-source community can trust and reproduce.

## Phase 1: Runtime Verification (63 assertions)

**Method:** Execute actual MATLAB commands via `mcp__matlab__evaluate_matlab_code` to verify every API assertion in the skill knowledge base.

**Three assertion categories:**

### Type A: Function Existence (30 assertions)
For each function mentioned in the skills, run `which('functionName')` to verify it exists (or doesn't exist) in MATLAB R2025b. This proves:
- Modern APIs exist: `trainnet`, `unet`, `unet3d`, `deeplabv3plus`, `maskrcnn`, `sheart2`, `dldwt`, `coxphfit`, `fillmissing`, `radiomics`, `volshow`
- Non-existent functions that Claude might hallucinate: `logrank`, `knnimpute`, `shearletTransform`, `modwt2`, `imodwt2`, `trainMaskRCNNObjectDetector`
- Removed functions: `labelvolshow` (throws explicit removal error)
- Deprecated functions: `trainNetwork`, `unetLayers`, `classificationLayer` (still exist but with warnings)

### Type B: Parameter Validation (25 assertions)
Run actual function calls with correct vs incorrect parameters:
- `wdenoise2(x, 'DenoisingMethod', 'FDR')` succeeds; `wdenoise2(x, 'DenoisingMethod', 'BlockJS')` errors
- `[A, D] = dldwt(x)` works (2 outputs); `[A, H, V, D] = dldwt(x)` errors (too many outputs)
- `negloglik(pd)` returns scalar; `pd.NegLogLikelihood` errors (no such property)
- `volshow(V, OverlayData=labels)` works; `labelvolshow(labels)` errors (removed)
- `radiomics(data, roi)` object creation followed by `intensityFeatures(R)` works
- `intrinsicToWorld(R, I, J, K)` returns 3 separate arrays `[X, Y, Z]`

### Type C: Default Values (8 assertions)
Verify default parameter values using `help` output and empirical testing:
- `imgaussfilt` defaults to `'replicate'` padding (confirmed by comparing outputs)
- `imfilter` defaults to zero-padding (confirmed: dark borders at image edges)
- `wdenoise2` defaults to `'Bayes'` method
- `dldwt` defaults to `'haar'` wavelet

**Evidence:** All MATLAB outputs saved as structured JSON in `runtime-verification/`.

## Phase 2: Blind A/B Comparison (16 eval prompts × 2 = 32 runs)

**Method:** For each eval prompt, two independent agents generate MATLAB code:
1. **With-skill agent:** Reads SKILL.md and knowledge cards before coding
2. **Without-skill (baseline) agent:** Same prompt, no skill access

**Blind comparison protocol:**
- Outputs randomly assigned as "A" and "B" (even eval_ids: with_skill=A; odd: with_skill=B)
- Blind comparator judges purely on output quality without knowing which had the skill
- Rubric-based scoring: Content (correctness, completeness, accuracy) and Structure (organization, formatting, usability)
- Assertions checked programmatically against both outputs

**16 eval prompts across 5 skills:**

| Skill | Evals | Key Assertions |
|-------|-------|----------------|
| Deep Learning (4) | U-Net, Transfer Learning, Custom Training, 3D Volumetric | `unet()` not `unetLayers()`, `trainnet` not `trainNetwork`, no `classificationLayer` |
| Wavelet (3) | MRI Denoising, Shearlets, dldwt | No `BlockJS`, `sheart2` not `shearletTransform`, 2-output `dldwt` |
| Stats-ML (3) | Survival, Distribution Fitting, Missing Data | No `logrank`, `negloglik()` not `.NegLogLikelihood`, `fillmissing` not `knnimpute` |
| Medical Imaging (3) | Volume Viz, Radiomics, Coordinates | `volshow` not `labelvolshow`, radiomics object API, `intrinsicToWorld` 3 outputs |
| Image Processing (3) | Filter Padding, Cell Counting, Block Processing | `imgaussfilt`/`imfilter` padding difference, `watershed`, `blockproc` |

## Phase 3: Trigger Optimization

**Method:** Use the skill-creator's description optimization workflow to test whether skills activate when users ask relevant MATLAB questions. Uses 20 eval queries per skill (10 should-trigger + 10 should-not-trigger).

## Installed Toolboxes

| Toolbox | Version |
|---------|---------|
| Computer Vision Toolbox | 25.2 (R2025b) |
| Deep Learning Toolbox | 25.2 (R2025b) |
| Image Processing Toolbox | 25.2 (R2025b) |
| Medical Imaging Toolbox | 25.2 (R2025b) |
| Statistics and Machine Learning Toolbox | 25.2 (R2025b) |
| Wavelet Toolbox | 25.2 (R2025b) |

## Reproduction

1. **Runtime verification:** Re-run the MATLAB commands in `runtime-verification/*.json` on any R2025b installation with the listed toolboxes
2. **A/B comparison:** Re-run the eval prompts from `*-workspace/evals/evals.json` with and without skill access
3. **Grading:** Apply the string-matching assertions to the output code files
