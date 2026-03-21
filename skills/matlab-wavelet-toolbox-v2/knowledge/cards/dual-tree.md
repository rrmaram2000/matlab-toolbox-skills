# Dual-Tree Complex Wavelet Transform - Guidance

## When to Use Dual-Tree (vs DWT or Shearlets)

| Your Task | Best Choice | Why |
|-----------|-------------|-----|
| Standard analysis / compression | `wavedec2` | Compact, no redundancy |
| Oriented texture analysis | `dualtree2` | 6 orientations per scale |
| Edge detection by angle | `dualtree2` | ±15, ±45, ±75 degree selectivity |
| Denoising with edge preservation | `dualtree2` | Near shift-invariant |
| Curvilinear features (vessels) | `shearletSystem` | Better curvature handling |

**Trade-off**: Dual-tree is ~4x redundant and ~4x slower than DWT. Use only when directional selectivity or shift-invariance matters.

## Directional Subband Map

`d{level}(:,:,direction)` where direction indices are:
- 1,2: near-horizontal (±15 degrees)
- 3,4: diagonal (±45 degrees)
- 5,6: near-vertical (±75 degrees)

## Application Patterns

**Selective enhancement**: Amplify specific orientation subbands (e.g., multiply horizontal directions 1,2 by 1.5) then reconstruct.

**Directional denoising**: Threshold each direction/level independently using MAD noise estimation. This preserves edges better than isotropic wavelet denoising.

**Dominant orientation map**: Sum absolute coefficients across scales for each direction, then take argmax at each pixel to find the dominant edge orientation.
