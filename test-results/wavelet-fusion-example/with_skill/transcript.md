# MRI + CT Wavelet Image Fusion — With Skill

## Prompt
"Fuse an MRI and CT image using wavelet-based fusion with proper coefficient-level rules: mean for approximation, max-absolute for details. Check decomposition level limits. Include quality metrics."

## Skill Consultation
The agent consulted:
- `matlab-wavelet-toolbox-v2/SKILL.md` — Transform selection decision tree
- `matlab-wavelet-toolbox-v2/knowledge/cards/image-fusion.md` — Fusion rules
- `matlab-wavelet-toolbox-v2/scripts/template_image_fusion.m` — Reference template

## Key API Decisions (Guided by Skill)
1. **`wmaxlev`** — checks maximum decomposition level before decomposing (prevents empty coefficients)
2. **`wavedec2` / `waverec2`** — multi-level decomposition (not single-level `dwt2`)
3. **`detcoef2('all', C, S, lev)`** — extracts detail subbands per level for separate fusion rules
4. **`im2double`** instead of `double()` — correct normalization to [0,1]
5. **Separate fusion rules**: mean for approximation, max-absolute for details
6. **Regional energy-based** alternative using local energy comparison

## What the Skill Prevented
- Did NOT use `modwt2` / `imodwt2` (do not exist — MODWT is 1D only)
- Did NOT use `double()` which gives [0,255] instead of [0,1]
- Did NOT average all coefficients equally (loses detail from both modalities)

## Output
- 180-line pipeline with two fusion strategies
- Quality metrics: mutual information, spatial frequency, SSIM
- Proper multi-level decomposition with per-subband fusion
