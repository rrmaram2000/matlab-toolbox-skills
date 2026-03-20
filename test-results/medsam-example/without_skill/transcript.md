# Transcript: MedSAM Tumor Segmentation (Without Skill)

**Date:** 2026-03-20
**Model:** Claude Opus 4.6 (1M context)
**Context:** No skill files or knowledge cards available. General MATLAB knowledge only.

## Prompt

> How do I use MedSAM to segment a tumor from a CT volume in MATLAB? I have a NIfTI file with the CT scan. I want to interactively mark a few points on the tumor in one slice, then propagate the segmentation to the full 3D volume. Show me the complete MATLAB R2025b code.

## Approach

The assistant wrote the code from general knowledge of MATLAB R2025b APIs. Key design decisions:

1. **NIfTI loading** via `niftiread`/`niftiinfo` (standard Medical Imaging Toolbox).
2. **CT windowing** using `mat2clim` for soft-tissue window normalization.
3. **Interactive point selection** using `ginput`, then deriving a bounding box from the points.
4. **MedSAM inference** using `medicalSAM`, `imageEmbeddings`, and `segmentObjectsFromEmbeddings`.
5. **3D propagation** via slice-by-slice bounding box propagation (forward and backward from seed slice).
6. **Post-processing** with morphological operations and largest-component extraction.
7. **Visualization** with `volshow` using `OverlayData` (R2025b API).

## Potential Issues / Uncertainties

Without access to verified skill documentation, several API details are uncertain:

- **`medicalSAM` constructor**: The exact function name and calling syntax may differ. It could be `medicalSegmentAnythingModel` or require a model name argument.
- **`imageEmbeddings` function**: The exact function for computing SAM embeddings may have a different name or signature in R2025b.
- **`segmentObjectsFromEmbeddings` parameters**: The BoundingBox parameter format (whether it uses `[x,y,w,h]` or `[x1,y1,x2,y2]`) is uncertain. The `imageSize` parameter may be required as a positional argument vs. name-value pair.
- **`mat2clim` function**: This function may not exist in MATLAB. The correct approach might be `rescale(V, 'InputMin', minHU, 'InputMax', maxHU)` or manual normalization.
- **`sliceViewer` function**: May need to be `sliceViewer(Vwin)` or `orthosliceViewer(Vwin)` depending on the toolbox version.
- **MedSAM input format**: Whether MedSAM expects uint8 RGB, single-precision RGB, or has specific preprocessing requirements is not verified.
- **`volshow` OverlayData syntax**: The exact name-value argument syntax for overlay visualization in R2025b needs verification.

## Output

Single MATLAB script: `medsam_tumor_segmentation.m`
