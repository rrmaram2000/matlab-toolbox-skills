# MATLAB Wavelet Toolbox - Knowledge Index

## Quick Navigation

| Task | Knowledge Card |
|------|----------------|
| **Mathematical Theory** | `mathematical-foundations.md` |
| Basic 2D decomposition | `cards/2d-transforms.md` |
| Multi-level analysis | `cards/2d-transforms.md` |
| **Custom wavelet design** | `cards/custom-wavelets.md` |
| Lifting scheme | `cards/custom-wavelets.md` |
| **Learning wavelets from data** | `cards/custom-wavelets.md` |
| Deep learning integration | `cards/deep-learning.md` |
| Neural network layers | `cards/deep-learning.md` |
| **Denoise images** | `cards/denoising.md` |
| **MRI/CT/ultrasound** | `cards/medical-imaging.md` |
| Noise models | `cards/medical-imaging.md` |
| Image fusion | `cards/medical-imaging.md` |
| Feature extraction | `cards/medical-imaging.md` |
| Edge detection (oriented) | `cards/dual-tree.md` |
| Curvilinear features | `cards/shearlets.md` |
| Filter coefficients | `cards/filters.md` |

## Card Summaries

### mathematical-foundations.md (~200 lines)
Rigorous theory: MRA axioms, Daubechies construction, spectral factorization, perfect reconstruction conditions, vanishing moments, regularity, Sobolev/Hölder exponents, admissibility condition, 2D extensions.

### cards/custom-wavelets.md (~350 lines)
**Your top priority**: Lifting scheme mathematics, polyphase representation, lifting factorization theorem, predict/update operators, CDF 9/7 construction, **learning wavelets from data**, differentiable lifting, constraint enforcement (PR, vanishing moments, regularity), deep learning integration, learnable wavelet layers.

### cards/medical-imaging.md (~380 lines)
Modality-specific guidance with proper noise models:
- **MRI**: Rician noise, bias correction
- **CT**: Poisson + electronic noise, Anscombe transform
- **Ultrasound**: Multiplicative speckle, log-domain processing
- **X-ray**: Quantum noise

Plus: threshold selection theory (SURE, BayesShrink), multi-modal fusion (MRI+CT, PET+CT), feature extraction for classification, quality metrics, GPU acceleration.

### cards/deep-learning.md (~150 lines)
Neural network integration: `cwtLayer`, `modwtLayer`, `dldwt`/`dlidwt` (R2025a+), custom wavelet layers, GPU acceleration, wavelet preprocessing for CNNs, learnable filters.

### cards/2d-transforms.md (~100 lines)
Standard 2D DWT workflow: `dwt2`, `wavedec2`, `swt2`, `lwt2`, coefficient extraction, boundary handling, common pitfalls.

### cards/denoising.md (~120 lines)
Wavelet denoising: `wdenoise2`, threshold selection methods (Universal, SURE, Bayes), soft/hard thresholding, level-dependent thresholds, quality metrics.

### cards/dual-tree.md (~120 lines)
6-orientation directional analysis: `dualtree2`, near shift-invariance, accessing directional subbands, edge detection by orientation, selective enhancement.

### cards/shearlets.md (~100 lines)
Curvilinear features: `shearletSystem`, optimal for vessels/fibers, anisotropic scaling, comparison with wavelets.

### cards/filters.md (~100 lines)
Filter coefficients: `wfilters`, `orthfilt`, `biorfilt`, perfect reconstruction verification, filter properties, visualization.

## Total Knowledge Base

| Component | Lines | Focus |
|-----------|-------|-------|
| SKILL.md | ~120 | Quick reference, entry point |
| mathematical-foundations.md | ~200 | Rigorous theory |
| custom-wavelets.md | ~350 | Learnable wavelets (priority) |
| medical-imaging.md | ~380 | Clinical applications |
| deep-learning.md | ~150 | DL integration |
| 2d-transforms.md | ~100 | Core transforms |
| denoising.md | ~120 | Noise removal |
| dual-tree.md | ~120 | Directional analysis |
| shearlets.md | ~100 | Curvilinear features |
| filters.md | ~100 | Filter bank theory |
| **Total** | **~1,740** | Curated, rigorous content |

## Function Quick Reference

| Category | Key Functions |
|----------|---------------|
| **2D DWT** | `dwt2`, `idwt2`, `wavedec2`, `waverec2` |
| **Shift-invariant** | `swt2`, `iswt2` (Note: MODWT is 1D only: `modwt`, `imodwt`) |
| **Lifting** | `lwt2`, `ilwt2`, `liftingScheme`, `addlift`, `liftingStep` |
| **Directional** | `dualtree2`, `idualtree2`, `shearletSystem` |
| **Denoising** | `wdenoise2`, `wthresh`, `thselect` |
| **Filters** | `wfilters`, `orthfilt`, `biorfilt`, `liftfilt` |
| **Deep Learning** | `cwtLayer`, `modwtLayer`, `dldwt`, `dlidwt` |
| **Utilities** | `wmaxlev`, `waveinfo`, `wavefun`, `wavemngr` |
