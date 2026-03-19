---
name: matlab-image-processing-toolbox
description: "MATLAB Image Processing Toolbox. Functions - imgaussfilt, medfilt2, wiener2, imfilter, graythresh, imbinarize, multithresh, watershed, activecontour, strel, imopen, imclose, imerode, imdilate, bwareaopen, imfill, regionprops, bwconncomp, bwlabel, edge, im2double, im2uint8, mat2gray, adapthisteq, imadjust, blockproc. Tasks - remove noise from an image, filter a noisy image, smooth an image, enhance contrast, threshold an image, segment objects, separate touching objects, clean up a binary mask, fill holes in mask, remove small objects, count cells or particles, measure region properties like area and centroid, detect edges, convert image data types, preprocess images before deep learning, apply morphological operations, extract texture features, process large images in blocks. Domains - MRI preprocessing, CT windowing, X-ray enhancement, microscopy, histology, cell counting, stain normalization, fluorescence imaging, binary mask cleanup, image segmentation pipeline, satellite imagery, industrial inspection, document processing, agriculture, general-purpose image analysis, remote sensing, surface defect detection."
---

# MATLAB Image Processing Toolbox

Expert skill for medical image analysis using MATLAB's Image Processing Toolbox (IPT R2025a+). Focuses on medical imaging patterns, domain-specific pipelines, and non-obvious gotchas that go beyond standard IPT knowledge.

## When to Use This Skill

- Medical imaging pipelines: MRI, CT/X-ray, microscopy, histology
- Modality-specific denoising (Rician for MRI, speckle for ultrasound)
- Multi-tissue segmentation with domain-specific thresholds
- Cell counting, fluorescence quantification, stain normalization
- DL segmentation post-processing with IPT morphological cleanup
- Data type gotchas causing silent errors in medical image processing

## Read Before Coding

| Task | Read This | Template Script |
|------|-----------|-----------------|
| MRI preprocessing | `knowledge/cards/medical-mri.md` | `scripts/template_mri_preprocessing.m` |
| Cell counting | `knowledge/cards/medical-microscopy.md` | `scripts/template_cell_counting.m` |
| CT windowing | `knowledge/cards/medical-mri.md` | `scripts/template_ct_windowing.m` |
| Fluorescence quantification | `knowledge/cards/medical-microscopy.md` | `scripts/template_fluorescence_quantification.m` |
| Histology stain normalization | `knowledge/cards/medical-microscopy.md` | `scripts/template_histology_stain_normalization.m` |
| Tissue thresholding | `knowledge/cards/segmentation-thresholding.md` | `scripts/template_adaptive_thresholding.m` |
| Watershed for touching cells | `knowledge/cards/medical-microscopy.md` | `scripts/template_watershed_segmentation.m` |
| Morphological mask cleanup | `knowledge/cards/morphology-binary.md` | `scripts/template_morphological_cleanup.m` |
| DL segmentation + IPT | `knowledge/cards/deep-learning-segmentation.md` | — |
| Data type gotchas | `knowledge/cards/data-types.md` | — |
| Modality-specific denoising | `knowledge/cards/filtering-denoising.md` | — |
| Advanced regionprops | `knowledge/cards/feature-regions.md` | — |
| Large image processing | — | `scripts/template_large_image_blockproc.m` |
| Edge detection pipeline | — | `scripts/template_edge_detection_pipeline.m` |

## Critical Rules

### Rule 1: `imfilter` Zero-Pads by Default (Creates Dark Borders)

```matlab
% imfilter defaults to zero-padding — dark border artifacts!
bad = imfilter(I, h);              % Dark borders
good = imfilter(I, h, 'replicate'); % Fix

% imgaussfilt defaults to 'replicate' — safe as-is
filtered = imgaussfilt(I, 2);  % Already correct
```

### Rule 2: `graythresh` Returns [0,1], Not Pixel Values

```matlab
level = graythresh(img_uint8);  % Returns 0.45, NOT 115

% Use imbinarize instead (handles automatically)
bw = imbinarize(img_uint8);
```

### Rule 3: `double()` vs `im2double()` — Silent Disaster

```matlab
bad = double(img_uint8);     % Still [0,255], NOT [0,1]!
good = im2double(img_uint8); % Correctly scales to [0,1]
```

### Rule 4: SE Radius Must Be Smaller Than Features You Keep

```matlab
% SE radius ≈ half the feature size you want to AFFECT
se = strel('disk', 5);  % Removes features ~10px diameter
cleaned = imopen(bw, se);

% If SE radius > feature radius, features disappear!
```

### Rule 5: `blockproc` BorderSize Must Match Filter Radius

```matlab
fun = @(block) imgaussfilt(block.data, 2);
result = blockproc(huge_image, [512 512], fun, ...
    'BorderSize', [6 6], ...      % 3*sigma for Gaussian
    'TrimBorder', true, ...
    'UseParallel', true);
```

### Rule 6: DICOM Normalization — Use `mat2gray`, Not `im2double`

```matlab
% im2double assumes standard uint16 range; DICOM data may differ
img_norm = mat2gray(double(dicomread('scan.dcm')));
```

## Template Scripts

Ready-to-use medical imaging pipelines in `scripts/`:

| Script | Purpose |
|--------|---------|
| `template_mri_preprocessing.m` | MRI bias correction, denoising, brain extraction |
| `template_ct_windowing.m` | CT Hounsfield unit windowing for different tissues |
| `template_cell_counting.m` | Automated cell detection and counting pipeline |
| `template_fluorescence_quantification.m` | Multi-channel fluorescence analysis |
| `template_histology_stain_normalization.m` | H&E color deconvolution and normalization |
| `template_adaptive_thresholding.m` | Adaptive thresholding with sensitivity tuning |
| `template_watershed_segmentation.m` | Marker-controlled watershed for touching objects |
| `template_morphological_cleanup.m` | Standard binary mask cleanup pipeline |
| `template_large_image_blockproc.m` | Block processing for large images |
| `template_edge_detection_pipeline.m` | Multi-method edge detection comparison |

## Knowledge Cards

**Medical Imaging (primary value):**
- `knowledge/cards/medical-mri.md` — MRI preprocessing, tissue segmentation, volumetry
- `knowledge/cards/medical-microscopy.md` — Cell counting, fluorescence, H&E histology

**Medical-Specific Patterns:**
- `knowledge/cards/filtering-denoising.md` — Modality-specific denoising gotchas
- `knowledge/cards/segmentation-thresholding.md` — Tissue segmentation thresholding
- `knowledge/cards/morphology-binary.md` — Medical cleanup recipes
- `knowledge/cards/feature-regions.md` — Advanced regionprops for medical measurement

**Integration:**
- `knowledge/cards/deep-learning-segmentation.md` — DL + IPT post-processing patterns
- `knowledge/cards/data-types.md` — Type conversion gotchas for medical formats

## Cross-Toolbox Integration

For wavelet-based image processing (multiresolution denoising, fusion), see: **matlab-wavelet-toolbox** skill.

```matlab
% Example: Wavelet + IPT fusion for MRI denoising
denoised = wdenoise2(mri, 'DenoisingMethod', 'Bayes');  % Wavelet
cleaned = imopen(denoised, strel('disk', 2));           % IPT morphology
enhanced = adapthisteq(cleaned);                        % IPT contrast
```

---
*Source: MathWorks Image Processing Toolbox Documentation (R2025a)*
