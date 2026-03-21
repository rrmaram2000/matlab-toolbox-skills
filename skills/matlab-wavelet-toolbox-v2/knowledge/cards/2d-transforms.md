# 2D Wavelet Transforms - When to Use Which

## Decision Guide

| Your Goal | Transform | Why |
|-----------|-----------|-----|
| Standard multi-scale analysis | `wavedec2`/`waverec2` | Critically sampled, compact |
| Denoising, shift-sensitive tasks | `swt2`/`iswt2` | Shift-invariant (redundant, same-size coefficients) |
| Custom or learned wavelets | `lwt2`/`ilwt2` | Lifting scheme, in-place computation |
| Oriented edge analysis | `dualtree2`/`idualtree2` | 6 orientations per scale |
| Curvilinear features | `shearletSystem` + `sheart2` | Anisotropic scaling |

**MODWT is 1D only** (`modwt`/`imodwt`) -- no 2D version exists.

## Practical Guidance

- **Level selection**: Always check `wmaxlev(size(img), wname)` before decomposition. Typical range is 3-5.
- **Boundary mode**: Use `'symmetric'` for medical images (avoids border artifacts). Default for `dwt2` is `'symmetric'`, but explicit is safer.
- **SWT vs DWT**: SWT output is same size as input (redundant). DWT output is downsampled. Do not mix them.
- **Coefficient bookkeeping**: `wavedec2` packs coefficients into a single vector `C` with bookkeeping matrix `S`. Use `appcoef2`, `detcoef2`, `wrcoef2` to extract specific subbands.

## Common Pitfalls

| Problem | Fix |
|---------|-----|
| "Level too high" error | Check `wmaxlev()` first |
| Reconstruction mismatch | Match transform pairs exactly (dwt2/idwt2, wavedec2/waverec2) |
| Border artifacts | Use `'symmetric'` boundary mode |
| Size confusion (SWT vs DWT) | SWT keeps original size; DWT downsamples |
