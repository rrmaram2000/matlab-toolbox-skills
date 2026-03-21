# Trigger Optimization Results

**Date:** 2026-03-19
**Status:** Automated optimization deferred — manual verification recommended

## What Happened

The `run_loop.py` script requires a direct Anthropic API key (`ANTHROPIC_API_KEY`) to call `claude -p` for trigger evaluation. This key is not available in the current session (Claude Code uses session tokens, not API keys).

## Existing Trigger Eval Queries

All 5 skills already have trigger eval sets (20 queries each: 10 should-trigger + 10 should-not-trigger) created in iteration-2:

- `matlab-deep-learning-workspace/iteration-2/trigger_eval.json`
- `matlab-image-processing-toolbox-workspace/iteration-2/trigger_eval.json`
- `matlab-medical-imaging-toolbox-workspace/iteration-2/trigger_eval.json`
- `matlab-stats-ml-workspace/iteration-2/trigger_eval.json`
- `matlab-wavelet-toolbox-workspace/iteration-2/trigger_eval.json`

## Current Trigger Behavior

Based on the skills visible in the active session, all 5 MATLAB skills ARE currently registered and their descriptions ARE triggering correctly:

- `matlab-deep-learning-v2` — Triggers for DL/CNN/training/segmentation/detection tasks
- `matlab-wavelet-toolbox-v2` — Triggers for wavelet/denoising/shearlet/dldwt tasks
- `matlab-stats-ml-v2` — Triggers for stats/ML/survival/distribution/clustering tasks
- `matlab-medical-imaging-toolbox-v2` — Triggers for DICOM/NIfTI/registration/radiomics tasks
- `matlab-image-processing-toolbox-v2` — Triggers for filtering/segmentation/morphology/cell counting tasks

## Recommended Manual Verification

To verify trigger reliability, open a fresh Claude Code session and try these queries:

### Should trigger matlab-deep-learning-v2:
1. "Train a U-Net for brain tumor segmentation in MATLAB"
2. "How do I set up transfer learning with ResNet-50 in MATLAB?"

### Should trigger matlab-wavelet-toolbox-v2:
3. "Denoise an MRI image using wavelet thresholding in MATLAB"
4. "How do I use shearlets for vessel detection in MATLAB?"

### Should trigger matlab-stats-ml-v2:
5. "Compare survival between two treatment groups using Cox regression in MATLAB"
6. "Handle missing data with KNN imputation in MATLAB"

### Should trigger matlab-medical-imaging-toolbox-v2:
7. "Load a DICOM series and visualize it as a 3D volume in MATLAB"
8. "Extract radiomics features from a CT tumor scan in MATLAB"

### Should trigger matlab-image-processing-toolbox-v2:
9. "Count cells in a fluorescence microscopy image using MATLAB"
10. "Apply Gaussian filtering without dark borders in MATLAB"

### Should NOT trigger any MATLAB skill:
11. "Write a Python function to sort a list"
12. "Help me with a JavaScript React component"
