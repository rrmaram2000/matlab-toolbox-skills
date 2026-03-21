# Shearlet Transform - Application Guidance

## When Shearlets Beat Wavelets

Shearlets are **optimal for curvilinear features** -- structures with smooth curvature:
- Blood vessels (angiography, retinal imaging)
- Nerve fibers (tractography)
- Tissue boundaries
- Any smooth curves in images

**Approximation theory**: Shearlet representation of curved edges achieves O(n^-2 (log n)^3) approximation error, vs O(n^-1) for standard wavelets. This is the theoretical reason to prefer shearlets for vessel/fiber analysis.

## Decision: Shearlets vs Dual-Tree vs DWT

| Feature Type | Best Transform | Why |
|--------------|----------------|-----|
| General purpose | `wavedec2` | Compact, fast |
| Oriented textures / straight edges | `dualtree2` | 6 fixed orientations |
| Curvilinear edges / vessels | `shearletSystem` | Anisotropic scaling, many directions |
| Compression | `wavedec2` | No redundancy |

**Trade-off**: Shearlets are slower and more complex than dual-tree. Use only when curvature handling matters.

## Medical Application Patterns

**Vessel enhancement** (angiography): Amplify fine-scale shearlet coefficients (scales 1-2) by 1.5-2x, then reconstruct. This selectively enhances curvilinear structures.

**Shearlet denoising**: Threshold each scale/direction independently using MAD noise estimation. Shearlets provide sparser representation of curved edges, so thresholding removes more noise while preserving vessels.

**Configuration tip**: For medical images, use `'TransformType', 'real'` (default) and 3-4 scales. The `'meyer'` directional filter (default) works well for most cases.
