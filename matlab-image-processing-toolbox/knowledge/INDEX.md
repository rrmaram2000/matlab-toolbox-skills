# MATLAB Image Processing Toolbox - Knowledge Index

Quick reference to all knowledge cards organized by category.

## Card Catalog

### Core Processing

| Card | Lines | Description | Key Functions |
|------|-------|-------------|---------------|
| `cards/filtering-denoising.md` | ~280 | Noise reduction techniques | `imgaussfilt`, `medfilt2`, `wiener2` |
| `cards/segmentation-thresholding.md` | ~320 | Global, adaptive, multi-level thresholding | `graythresh`, `imbinarize`, `multithresh` |
| `cards/morphology-binary.md` | ~340 | Binary morphological operations | `strel`, `imopen`, `imclose`, `bwareaopen` |
| `cards/feature-regions.md` | ~350 | Region measurement and analysis | `regionprops`, `bwconncomp`, `bwlabel` |
| `cards/data-types.md` | ~280 | Image data types and conversions | `im2double`, `im2uint8`, `mat2gray` |

### Medical Imaging

| Card | Lines | Description | Key Functions |
|------|-------|-------------|---------------|
| `cards/medical-mri.md` | ~380 | MRI preprocessing and tissue segmentation | `dicomread`, bias correction, `multithresh` |
| `cards/medical-microscopy.md` | ~420 | Cell counting, fluorescence, histology | watershed, `regionprops`, H&E deconvolution |

### Advanced

| Card | Lines | Description | Key Functions |
|------|-------|-------------|---------------|
| `cards/deep-learning-segmentation.md` | ~320 | Semantic segmentation with deep learning | `semanticseg`, `unetLayers`, `trainNetwork` |

## Task-to-Card Mapping

| If you need to... | Read this card |
|-------------------|----------------|
| Remove noise from an image | `filtering-denoising.md` |
| Convert grayscale to binary | `segmentation-thresholding.md` |
| Clean up a binary mask | `morphology-binary.md` |
| Count/measure objects | `feature-regions.md` |
| Handle uint8/double conversion | `data-types.md` |
| Process brain MRI | `medical-mri.md` |
| Count cells in microscopy | `medical-microscopy.md` |
| Use U-Net for segmentation | `deep-learning-segmentation.md` |

## Quick Links by Function

### Filtering Functions
- `imgaussfilt` → `filtering-denoising.md`
- `medfilt2` → `filtering-denoising.md`
- `wiener2` → `filtering-denoising.md`
- `imbilatfilt` → `filtering-denoising.md`

### Segmentation Functions
- `graythresh` → `segmentation-thresholding.md`
- `imbinarize` → `segmentation-thresholding.md`
- `multithresh` → `segmentation-thresholding.md`
- `watershed` → `medical-microscopy.md`
- `activecontour` → (see SKILL.md quick reference)

### Morphology Functions
- `strel` → `morphology-binary.md`
- `imerode`, `imdilate` → `morphology-binary.md`
- `imopen`, `imclose` → `morphology-binary.md`
- `bwareaopen` → `morphology-binary.md`
- `imfill` → `morphology-binary.md`

### Feature Functions
- `regionprops` → `feature-regions.md`
- `bwconncomp` → `feature-regions.md`
- `bwlabel` → `feature-regions.md`
- `bwboundaries` → `feature-regions.md`

### Deep Learning Functions
- `semanticseg` → `deep-learning-segmentation.md`
- `unetLayers` → `deep-learning-segmentation.md`
- `trainNetwork` → `deep-learning-segmentation.md`

### Type Conversion Functions
- `im2double` → `data-types.md`
- `im2uint8` → `data-types.md`
- `mat2gray` → `data-types.md`

## Documentation Source

All cards are grounded in official MathWorks documentation:
- **User Guide** (1,952 pages): Tutorials, concepts, workflows
- **Function Reference** (4,006 pages): Complete API documentation

Extracted content preserved in:
- `output/matlab-image-processing-toolbox_extracted.json` (User Guide)
- `output/matlab-ipt-reference_extracted.json` (Function Reference)

---
*MATLAB Image Processing Toolbox Skill v1.0*
*Created with manual curation from official MathWorks documentation*
