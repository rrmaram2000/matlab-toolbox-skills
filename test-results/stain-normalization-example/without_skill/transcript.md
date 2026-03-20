# H&E Stain Normalization — Without Skill

## Prompt
"Implement Macenko stain normalization for H&E histology. Convert to OD space, mask background, estimate stain vectors via SVD with angle-based extraction, normalize concentrations, reconstruct."

## Key Issue: Wrong Algorithm
Despite the prompt explicitly requesting Macenko normalization with OD-space conversion and SVD-based stain vector estimation, the agent implemented:

1. **Histogram matching** (`imhistmatch`) — per-channel RGB histogram equalization
2. **Lab color space matching** — mean/std normalization in Lab space

Neither approach performs actual stain deconvolution.

## What's Missing
| Macenko Step | With Skill | Without Skill |
|---|---|---|
| OD-space conversion | `-log10(I/255 + eps)` | Not implemented |
| Background masking | OD threshold > 0.15 | Not implemented |
| PCA on tissue pixels | `pca(srcPixels)` | Not implemented |
| Angle-based stain vectors | `prctile(angles, 99)` | Not implemented |
| Stain separation | Matrix deconvolution | Not implemented |
| Concentration normalization | Percentile matching | Not implemented |
| Stain channel visualization | H and E channels shown | Not available |

## Why This Matters
Histogram matching shifts colors globally but doesn't separate the biological stains. For downstream computational pathology (e.g., nuclei detection, tissue classification), proper stain separation is essential because:
- Different stains bind to different tissue components (H=nuclei, E=cytoplasm)
- Color shifts between scanners/labs affect ML model performance
- Macenko normalization is the accepted standard in digital pathology

## Verdict
**DOMAIN DEPTH GAP** — The code runs without errors, but implements the wrong algorithm entirely. This demonstrates how skills provide domain-specific methodology knowledge beyond just API correctness.
