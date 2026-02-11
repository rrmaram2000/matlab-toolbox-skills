---
name: matlab-image-processing-toolbox
description: MATLAB Image Processing Toolbox. Functions: imgaussfilt, medfilt2, wiener2, imfilter, graythresh, imbinarize, multithresh, watershed, activecontour, strel, imopen, imclose, imerode, imdilate, bwareaopen, imfill, regionprops, bwconncomp, bwlabel, edge, im2double, im2uint8, mat2gray, adapthisteq, imadjust, blockproc. Tasks: remove noise from an image, filter a noisy image, smooth an image, enhance contrast, threshold an image, segment objects, separate touching objects, clean up a binary mask, fill holes in mask, remove small objects, count cells or particles, measure region properties like area and centroid, detect edges, convert image data types, preprocess images before deep learning, apply morphological operations, extract texture features, process large images in blocks. Domains: MRI preprocessing, CT windowing, X-ray enhancement, microscopy, histology, cell counting, stain normalization, fluorescence imaging, binary mask cleanup, image segmentation pipeline.
---

# MATLAB Image Processing Toolbox

Expert skill for medical image analysis using MATLAB's Image Processing Toolbox (IPT R2025a+).

## When to Use This Skill

- Image filtering, denoising, or enhancement in MATLAB
- Image segmentation (thresholding, watershed, active contours, deep learning)
- Morphological operations (erosion, dilation, opening, closing, reconstruction)
- Fourier/frequency domain filtering and transforms
- Image registration and geometric transformations
- Feature extraction (edges, regions, texture)
- Medical imaging: MRI, CT/X-ray, microscopy/histology
- Deep learning segmentation (semanticseg, U-Net, DeepLabv3+)
- Large image processing (blockproc) and GPU acceleration
- Data type handling and conversions

## Read Before Coding

| Task | Knowledge Card | Key Functions |
|------|----------------|---------------|
| Reduce noise | `filtering-denoising.md` | `imgaussfilt`, `medfilt2`, `wiener2` |
| Detect edges | — | `edge`, `imgradient`, `imgradientxy` |
| Clean binary masks | `morphology-binary.md` | `bwareaopen`, `imfill`, `imopen`, `imclose` |
| Select threshold | `segmentation-thresholding.md` | `graythresh`, `imbinarize`, `multithresh` |
| Separate touching objects | — | `watershed`, `bwdist`, `imhmin` |
| Measure regions | `feature-regions.md` | `regionprops`, `bwconncomp`, `bwlabel` |
| Register images | — | `imregister`, `imregtform`, `imwarp` |
| Process large images | — | `blockproc`, `gpuArray` |
| Segment with DL | `deep-learning-segmentation.md` | `semanticseg`, `unetLayers` |
| Convert data types | `data-types.md` | `im2double`, `im2uint8`, `mat2gray` |
| Process MRI | `medical-mri.md` | `dicomread`, `adapthisteq`, bias correction |
| Process CT/X-ray | — | HU windowing, bone segmentation |
| Count cells | `medical-microscopy.md` | Cell detection, stain normalization |

*Note: Rows with "—" indicate functions covered in SKILL.md quick patterns. Future knowledge cards may be added.*

## Critical Rules

### Rule 1: Data Type Handling

**The #1 source of errors.** Different types have different ranges:

| Type | Range | When to Use |
|------|-------|-------------|
| `uint8` | [0, 255] | Display, storage, most IPT functions |
| `uint16` | [0, 65535] | Medical images (DICOM), high dynamic range |
| `double` | [0, 1] normalized | Arithmetic operations, filtering |
| `logical` | 0 or 1 | Binary masks, segmentation results |

```matlab
% WRONG: Mixed types cause silent truncation
result = uint8_image + double_mask;  % Truncates!

% CORRECT: Explicit conversion
img = im2double(uint8_image);  % [0,255] → [0,1]
result = img + mask;
output = im2uint8(result);     % [0,1] → [0,255]
```

### Rule 2: Filter Normalization

```matlab
% LOWPASS: Coefficients must sum to 1 (preserves brightness)
h_avg = fspecial('average', 5);       % sum = 1
h_gauss = fspecial('gaussian', 5, 1); % sum ≈ 1

% HIGHPASS: Coefficients must sum to 0 (extracts changes)
h_laplacian = fspecial('laplacian');  % sum = 0
h_log = fspecial('log', 9, 1.5);      % sum = 0

% Verify before custom filters:
assert(abs(sum(h(:)) - 1) < 1e-6, 'Lowpass filter must sum to 1');
```

### Rule 3: Boundary Handling

```matlab
% For medical images: use 'replicate' to avoid edge artifacts
filtered = imfilter(img, h, 'replicate');

% Options: 'replicate' | 'symmetric' | 'circular' | numeric value
% Default is zero-padding which creates dark borders!
```

### Rule 4: Structuring Element Sizing

**SE radius ≈ half the feature size you want to affect.**

```matlab
% Remove noise blobs smaller than ~10 pixels diameter
se = strel('disk', 5);  % radius = 10/2 = 5
cleaned = imopen(bw, se);

% Fill holes up to ~20 pixels diameter
se = strel('disk', 10);
filled = imclose(bw, se);
```

### Rule 5: Threshold Output Range

`graythresh` returns normalized [0,1] regardless of input type:

```matlab
img_uint8 = imread('image.png');
level = graythresh(img_uint8);  % Returns 0.45, NOT 115

% For uint8 threshold value:
threshold_uint8 = level * 255;  % 0.45 * 255 = 115

% Better: use imbinarize (handles automatically)
bw = imbinarize(img_uint8);  % Internally uses graythresh
```

### Rule 6: Memory for Large Images

```matlab
% Use blockproc for images that don't fit in memory
% BorderSize MUST match filter radius to avoid tile artifacts

fun = @(block) imgaussfilt(block.data, 2);
result = blockproc(huge_image, [512 512], fun, ...
    'BorderSize', [6 6], ...      % 3*sigma for Gaussian
    'TrimBorder', true, ...
    'UseParallel', true);
```

## Quick Patterns

### Standard Preprocessing Pipeline

```matlab
function out = preprocess(img)
    img = im2double(img);                           % Normalize
    img = imgaussfilt(img, 1);                      % Denoise
    img = adapthisteq(img, 'ClipLimit', 0.02);      % Enhance contrast
    out = mat2gray(img);                            % Ensure [0,1]
end
```

### Binary Mask Cleanup

```matlab
function bw = clean_mask(bw, min_area, se_radius)
    se = strel('disk', se_radius);
    bw = imopen(bw, se);              % Remove small protrusions
    bw = imclose(bw, se);             % Close small gaps
    bw = imfill(bw, 'holes');         % Fill holes
    bw = bwareaopen(bw, min_area);    % Remove small objects
end
```

### Segment and Measure

```matlab
function stats = segment_measure(img)
    bw = imbinarize(img, 'adaptive');
    bw = bwareaopen(bw, 50);
    cc = bwconncomp(bw);
    stats = regionprops('table', cc, img, ...
        'Area', 'Centroid', 'MeanIntensity', 'Eccentricity');
end
```

## Function Quick Reference

### Filtering
| Function | Purpose | Example |
|----------|---------|---------|
| `imfilter` | Apply custom filter | `imfilter(I, h, 'replicate')` |
| `imgaussfilt` | Gaussian smoothing | `imgaussfilt(I, sigma)` |
| `medfilt2` | Median filter (salt-pepper) | `medfilt2(I, [3 3])` |
| `wiener2` | Adaptive Wiener | `wiener2(I, [5 5])` |
| `imsharpen` | Unsharp masking | `imsharpen(I, 'Amount', 1)` |

### Segmentation
| Function | Purpose | Example |
|----------|---------|---------|
| `graythresh` | Otsu threshold | `level = graythresh(I)` |
| `imbinarize` | Binarize image | `bw = imbinarize(I, 'adaptive')` |
| `multithresh` | Multi-level threshold | `thresh = multithresh(I, 2)` |
| `watershed` | Watershed segmentation | `L = watershed(D)` |
| `activecontour` | Active contours | `bw = activecontour(I, mask)` |

### Morphology
| Function | Purpose | Example |
|----------|---------|---------|
| `strel` | Create structuring element | `se = strel('disk', 5)` |
| `imerode` / `imdilate` | Erosion / Dilation | `imerode(bw, se)` |
| `imopen` / `imclose` | Opening / Closing | `imopen(bw, se)` |
| `bwareaopen` | Remove small objects | `bwareaopen(bw, 100)` |
| `imfill` | Fill holes | `imfill(bw, 'holes')` |

### Features
| Function | Purpose | Example |
|----------|---------|---------|
| `edge` | Edge detection | `edge(I, 'Canny')` |
| `regionprops` | Region measurements | `regionprops('table', bw, I, 'Area')` |
| `bwconncomp` | Connected components | `cc = bwconncomp(bw)` |
| `graycomatrix` | Texture GLCM | `glcm = graycomatrix(I)` |

### I/O & Types
| Function | Purpose | Example |
|----------|---------|---------|
| `imread` / `imwrite` | Read/write images | `I = imread('img.png')` |
| `dicomread` | Read DICOM | `I = dicomread('scan.dcm')` |
| `im2double` | To double [0,1] | `I = im2double(I)` |
| `im2uint8` | To uint8 [0,255] | `I = im2uint8(I)` |

## Knowledge Cards

Detailed documentation organized by topic:

**Core Processing:**
- `knowledge/cards/filtering-denoising.md` - Noise reduction techniques
- `knowledge/cards/segmentation-thresholding.md` - Otsu, adaptive, multi-level
- `knowledge/cards/morphology-binary.md` - Binary morphological operations

**Feature Extraction:**
- `knowledge/cards/feature-regions.md` - regionprops, connected components

**Medical Imaging:**
- `knowledge/cards/medical-mri.md` - MRI preprocessing and segmentation
- `knowledge/cards/medical-microscopy.md` - Cell counting, histology

**Advanced:**
- `knowledge/cards/deep-learning-segmentation.md` - semanticseg, U-Net
- `knowledge/cards/data-types.md` - Type conversions and pitfalls

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
