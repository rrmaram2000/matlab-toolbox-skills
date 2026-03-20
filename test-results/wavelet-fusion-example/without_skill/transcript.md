# MRI + CT Wavelet Image Fusion — Without Skill

## Prompt
"Fuse an MRI and CT image using wavelet-based fusion with proper coefficient-level rules: mean for approximation, max-absolute for details. Check decomposition level limits. Include quality metrics."

## Key Issues

### 1. Hallucinated Functions: `modwt2` / `imodwt2`
```matlab
>> which('modwt2')
'modwt2' not found.

>> which('imodwt2')
'imodwt2' not found.
```
MODWT (Maximal Overlap DWT) is **1D only** in MATLAB. There is no 2D variant. The correct multi-level 2D transform is `wavedec2`.

### 2. Single-Level Decomposition
Used `dwt2` (single level) instead of `wavedec2` (multi-level). Single-level decomposition captures much less multi-resolution information.

### 3. Naive Coefficient Averaging
Averaged ALL coefficients (approximation AND details) equally. This loses edge/detail information from both modalities — the whole point of wavelet fusion is to apply different rules to different coefficient types.

### 4. `double()` Instead of `im2double()`
`double(uint8_img)` gives [0,255], not [0,1]. This affects wavelet coefficient scaling and SSIM computation.

### 5. No `wmaxlev` Check
No verification that the decomposition level is valid for the image size.

## Verdict
**FAIL** — Two hallucinated functions (`modwt2`, `imodwt2`) crash the MODWT fusion path. The DWT path works but uses naive averaging (losing the primary benefit of wavelet fusion) and incorrect intensity scaling.
