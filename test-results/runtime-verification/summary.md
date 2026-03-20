# Runtime Verification Summary

**Date:** 2026-03-19
**MATLAB Version:** R2025b (25.2)
**Platform:** macOS Darwin 25.3.0

## Overview

All assertions from the MATLAB Toolbox Skills knowledge base were verified by executing actual MATLAB commands — not by reading code or trusting documentation alone. Each assertion was tested with real function calls that either succeeded or produced the expected error.

## Results

| Category | Assertions | Verified | Pass Rate |
|---|---|---|---|
| Function Existence (Type A) | 30 | 30 | 100% |
| Parameter Validation (Type B) | 25 | 25 | 100% |
| Default Values (Type C) | 8 | 8 | 100% |
| **Total** | **63** | **63** | **100%** |

## Key Findings

### Confirmed Removals/Absence (functions that DON'T exist)
- `trainMaskRCNNObjectDetector` — NOT FOUND (use `maskrcnn` instead)
- `shearletTransform` — NOT FOUND (use `shearletSystem` + `sheart2`/`isheart2`)
- `modwt2` / `imodwt2` — NOT FOUND (MODWT is 1D only)
- `logrank` — NOT FOUND (use `coxphfit` for survival analysis)
- `knnimpute` — NOT FOUND (use `fillmissing(X, 'knn')`)
- `labelvolshow` — REMOVED with explicit error message (use `volshow` with `OverlayData`)

### Confirmed Deprecations (still exist but not recommended)
- `trainNetwork` → use `trainnet`
- `unetLayers` → use `unet`
- `unet3dLayers` → use `unet3d`
- `deeplabv3plusLayers` → use `deeplabv3plus`
- `classificationLayer` → use `trainnet` with loss function

### Confirmed API Signatures
- `dldwt` returns exactly 2 outputs `[A, D]` — D is a single 3D dlarray, NOT a cell
- `wdenoise2` valid methods: SURE, Bayes, Minimax, UniversalThreshold, FDR (NOT BlockJS)
- `negloglik(pd)` is a function call, NOT a `.NegLogLikelihood` property
- `intrinsicToWorld(R, I, J, K)` returns 3 separate arrays `[X, Y, Z]`
- `segmentObjectsFromEmbeddings` requires `imageSize` as 3rd positional argument

### Confirmed Defaults
- `imgaussfilt` default padding: `'replicate'`
- `imfilter` default padding: `0` (zero-padding — causes dark borders!)
- `wdenoise2` default method: `'Bayes'`, default wavelet: `'bior4.4'`
- `dldwt` default wavelet: `'haar'`, default padding: `'reflection'`
- `unet` default `NumFirstEncoderFilters`: `64`

## Installed Toolboxes

| Toolbox | Version |
|---|---|
| Computer Vision Toolbox | 25.2 (R2025b) |
| Deep Learning Toolbox | 25.2 (R2025b) |
| Image Processing Toolbox | 25.2 (R2025b) |
| Medical Imaging Toolbox | 25.2 (R2025b) |
| Statistics and Machine Learning Toolbox | 25.2 (R2025b) |
| Wavelet Toolbox | 25.2 (R2025b) |

## Reproduction

All commands can be re-run in MATLAB R2025b with the listed toolboxes installed. See the JSON files in this directory for exact commands and outputs.
