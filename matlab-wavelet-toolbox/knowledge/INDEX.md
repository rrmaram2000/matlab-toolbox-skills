# MATLAB Wavelet Toolbox - Knowledge Index

## Quick Navigation

| Task | Knowledge Card |
|------|----------------|
| **Mathematical Theory** (MRA, Daubechies, PR) | `mathematical-foundations.md` |
| **Custom wavelet design** / learning from data | `cards/custom-wavelets.md` |
| **MRI/CT/ultrasound** / noise models / fusion | `cards/medical-imaging.md` |
| Choosing which wavelet for your image type | `cards/filters.md` |
| When to use which 2D transform | `cards/2d-transforms.md` |
| Denoising method selection & recipes | `cards/denoising.md` |
| Directional edge detection guidance | `cards/dual-tree.md` |
| Curvilinear features (vessels/fibers) | `cards/shearlets.md` |
| Deep learning + wavelet integration patterns | `cards/deep-learning.md` |

## Primary Unique Content (read first)

### mathematical-foundations.md (~240 lines)
**Unique theoretical content not in model's training data.** MRA axioms, Daubechies construction via spectral factorization, perfect reconstruction conditions (alias cancellation + no distortion), vanishing moments, regularity (Sobolev/Holder exponents), biorthogonal theory, admissibility condition, 2D extensions (separable vs non-separable), uncertainty principle.

### cards/custom-wavelets.md
Lifting scheme theory (Sweldens 1996), when to design custom wavelets vs use standard ones, learning wavelets from data (optimization framework, constraint enforcement for PR/vanishing moments/regularity), verification checklist.

### cards/medical-imaging.md
Modality-specific noise models and complete processing pipelines:
- **MRI**: Rician noise, bias correction
- **CT**: Poisson + electronic noise, Anscombe transform
- **Ultrasound**: Multiplicative speckle, log-domain processing
- **X-ray**: Quantum noise
- Plus: threshold selection theory (SURE, BayesShrink), multi-modal fusion (MRI+CT, PET+CT), feature extraction, quality metrics

## Decision Guidance Cards

Cards trimmed to focus on **when-to-use** guidance (the model already knows the API):
- **2d-transforms.md**: Which transform for which goal, practical guidance, pitfalls
- **denoising.md**: Method selection by scenario, medical recipes, gotchas
- **dual-tree.md**: When dual-tree beats DWT/shearlets, directional subband map, application patterns
- **shearlets.md**: When shearlets beat wavelets (curvature theory), medical application patterns
- **filters.md**: Wavelet selection guide for medical imaging by clinical task
- **deep-learning.md**: Integration patterns (preprocessing, dldwt, cwtLayer), best practices

## Template Scripts (scripts/)

Ready-to-use `.m` files -- read and adapt:

| Template | Use Case |
|----------|----------|
| `template_mri_denoising.m` | MRI Rician noise removal |
| `template_ct_denoising.m` | CT Poisson noise with Anscombe |
| `template_ultrasound_speckle.m` | Ultrasound speckle (log-domain) |
| `template_multiresolution_analysis.m` | Standard wavedec2 decomposition |
| `template_dual_tree_directional.m` | Directional edge detection |
| `template_shearlet_curvilinear.m` | Vessel/fiber detection |
| `template_custom_lifting_wavelet.m` | Custom wavelet via liftingScheme |
| `template_deep_learning_wavelet.m` | Wavelet layers for DL (dldwt) |
| `template_image_fusion.m` | Multi-modal fusion (MRI+CT, PET+CT) |
| `template_wavelet_feature_extraction.m` | Energy/entropy features |
