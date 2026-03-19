---
name: matlab-wavelet-toolbox
description: "MATLAB Wavelet Toolbox. Functions - wavedec2, waverec2, dwt2, idwt2, swt2, lwt2, ilwt2, wdenoise2, dualtree2, idualtree2, shearletSystem, liftingScheme, liftingStep, addlift, wfilters, wmaxlev, dldwt, dlidwt, cwtLayer, appcoef2, detcoef2. Tasks - decompose an image into frequency bands, denoise a medical image using wavelets, remove noise from MRI or CT or ultrasound, extract texture features at multiple scales, design a custom wavelet, learn wavelets from data, detect edges and orientations, analyze directional structures like vessels or fibers, fuse multi-modal images, compress an image with wavelets, build wavelet layers for deep learning, choose the right wavelet for my image type, verify perfect reconstruction. Domains - MRI denoising, CT noise reduction, ultrasound speckle removal, Rician noise, Poisson noise, multiresolution analysis, image fusion, texture classification, vessel detection, fiber analysis, wavelet-based feature extraction, medical image preprocessing, audio analysis, vibration monitoring, seismic data processing, image compression, general signal and image processing, structural health monitoring."
---

# MATLAB Wavelet Toolbox Skill

Expert skill for 2D wavelet analysis in MATLAB. Focus areas: custom wavelet design via lifting schemes, medical image analysis (MRI/CT/ultrasound), and deep learning integration.

## Read Before Coding

**Open the relevant knowledge card before writing code:**

| Task | Knowledge File |
|------|----------------|
| **Mathematical foundations** (MRA, Daubechies, PR conditions) | `knowledge/mathematical-foundations.md` |
| **Custom wavelet design** / learning wavelets from data | `knowledge/cards/custom-wavelets.md` |
| MRI/CT/ultrasound processing | `knowledge/cards/medical-imaging.md` |
| Choosing which wavelet for your image type | `knowledge/cards/filters.md` |
| When to use which 2D transform | `knowledge/cards/2d-transforms.md` |
| Denoising method selection & recipes | `knowledge/cards/denoising.md` |
| Directional edge detection guidance | `knowledge/cards/dual-tree.md` |
| Curvilinear features (vessels/fibers) | `knowledge/cards/shearlets.md` |
| Deep learning + wavelet integration patterns | `knowledge/cards/deep-learning.md` |

## Critical Rules

1. **Check level limit**: `wmaxlev(size(img), wname)` before decomposition
2. **Match transform pairs**: dwt2/idwt2, wavedec2/waverec2, lwt2/ilwt2
3. **Boundary mode**: Use `'symmetric'` for medical images
4. **For custom wavelets**: Verify perfect reconstruction, vanishing moments

## Transform Selection

```
Analysis type?
├── Standard 2D decomposition
│   ├── Critically sampled → wavedec2/waverec2
│   └── Shift-invariant → swt2/iswt2 (MODWT is 1D only)
├── Directional analysis
│   ├── 6 orientations → dualtree2/idualtree2
│   └── Curvilinear (vessels) → shearletSystem
├── Custom wavelet design
│   └── Lifting scheme → liftingScheme + lwt2/ilwt2
└── Time-frequency (signals)
    └── CWT → cwt/icwt
```

## Wavelet Selection for Images

| Image Type | Wavelet | Rationale |
|------------|---------|-----------|
| Medical (MRI, CT) | db4-db8 | Good edge preservation |
| Smooth gradients | sym6-sym8 | Higher vanishing moments |
| Sharp edges | db2-db4 | Shorter filters |
| Compression | bior4.4, bior6.8 | Symmetric (linear phase) |

## Quick Patterns

### Multi-level Decomposition
```matlab
[C, S] = wavedec2(img, 4, 'db4');
cA = appcoef2(C, S, 'db4');           % Approximation
cH = detcoef2('h', C, S, 1);          % Horizontal detail, level 1
imgRec = waverec2(C, S, 'db4');
```

### Medical Image Denoising
```matlab
% MRI (Rician noise)
mriClean = wdenoise2(mri, 'DenoisingMethod', 'Bayes', ...
    'Wavelet', 'sym4', 'Level', 4);
% Valid methods: 'UniversalThreshold', 'Minimax', 'SURE', 'Bayes', 'FDR'

% Ultrasound (multiplicative speckle)
logUS = log(1 + double(us));
denoised = wdenoise2(logUS, 'DenoisingMethod', 'Bayes');
usClean = exp(denoised) - 1;
```

### Custom Wavelet via Lifting
```matlab
ls = liftingScheme('Wavelet', 'haar');
ls = addlift(ls, liftingStep('Type', 'predict', ...
    'Coefficients', [-0.5, 0.5], 'MaxOrder', 1));
ls = addlift(ls, liftingStep('Type', 'update', ...
    'Coefficients', [0.25, 0.25], 'MaxOrder', 0));
[LL, LH, HL, HH] = lwt2(img, liftingScheme=ls);
```

### Directional Analysis
```matlab
[a, d] = dualtree2(img, Level=3);
% d{level}(:,:,dir) for 6 directions: ±15°, ±45°, ±75°
```

### Deep Learning (R2025a+)
```matlab
x = dlarray(img, 'SSCB');
[A, D] = dldwt(x, Wavelet='db4');  % A=approx, D=detail (concatenated)
% For 2D: D(:,:,1,:)=H, D(:,:,2,:)=V, D(:,:,3,:)=D subbands
xRec = dlidwt(A, D, Wavelet='db4');  % Inverse transform
```

## Template Scripts

Ready-to-use `.m` files in `scripts/` -- read and adapt for your task:

| Template | Use Case |
|----------|----------|
| `template_mri_denoising.m` | MRI Rician noise removal pipeline |
| `template_ct_denoising.m` | CT Poisson noise with Anscombe transform |
| `template_ultrasound_speckle.m` | Ultrasound speckle reduction (log-domain) |
| `template_multiresolution_analysis.m` | Standard wavedec2 decomposition and visualization |
| `template_dual_tree_directional.m` | Directional edge detection with dualtree2 |
| `template_shearlet_curvilinear.m` | Vessel/fiber detection with shearlets |
| `template_custom_lifting_wavelet.m` | Custom wavelet design via liftingScheme |
| `template_deep_learning_wavelet.m` | Wavelet layers for deep learning (dldwt) |
| `template_image_fusion.m` | Multi-modal image fusion (MRI+CT, PET+CT) |
| `template_wavelet_feature_extraction.m` | Wavelet energy/entropy features for classification |

## Knowledge Base

Unique content not in the model's training data -- prioritize reading:

- **mathematical-foundations.md**: MRA theory, Daubechies construction, spectral factorization, perfect reconstruction, regularity, admissibility
- **custom-wavelets.md**: Lifting scheme theory, learnable wavelet constraints, verification
- **medical-imaging.md**: Noise models (Rician, Poisson, speckle), fusion rules, feature extraction

Knowledge cards provide **when-to-use guidance** and **decision frameworks** for choosing transforms, wavelets, and methods.

See `knowledge/INDEX.md` for full navigation.
