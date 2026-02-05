# Knowledge Card Index

Quick reference to all Medical Imaging Toolbox knowledge cards.

## File I/O (2 cards)

| Card | Description | Key Functions |
|------|-------------|---------------|
| [`file-io-dicom.md`](cards/file-io-dicom.md) | DICOM file reading, series handling, metadata navigation, DICOM writing | `medicalVolume`, `dicomread`, `dicominfo`, `dicomCollection`, `dicomwrite` |
| [`file-io-nifti-nrrd.md`](cards/file-io-nifti-nrrd.md) | NIfTI and NRRD formats for research workflows, format conversion | `niftiread`, `niftiwrite`, `niftiinfo`, `nrrdread`, `nrrdinfo` |

## Core Concepts (3 cards)

| Card | Description | Key Functions |
|------|-------------|---------------|
| [`medical-volume.md`](cards/medical-volume.md) | The `medicalVolume` class - central object for 3D medical images with spatial referencing | `medicalVolume`, `medicalImage`, `extractSlice`, `replaceSlice`, `resample` |
| [`coordinate-systems.md`](cards/coordinate-systems.md) | **CRITICAL** - Patient vs Intrinsic coordinates, orientation conventions (RAS/LPS), coordinate transformations | `medicalref3d`, `intrinsicToWorld`, `worldToIntrinsic`, `worldToSubscript` |
| [`visualization-3d.md`](cards/visualization-3d.md) | 3D volume rendering, slice browsing, multimodal overlay, rendering options | `volshow`, `sliceViewer`, `labelvolshow`, `montage`, rendering properties |

## Registration (2 cards)

| Card | Description | Key Functions |
|------|-------------|---------------|
| [`registration-rigid.md`](cards/registration-rigid.md) | Rigid and affine registration, moment-based methods, ICP for surfaces, landmark-based | `imregmoment`, `imregicp`, `fitgeotform3d`, `imregtform`, `imwarp` |
| [`registration-deformable.md`](cards/registration-deformable.md) | Non-rigid deformable registration, displacement fields, groupwise registration, lung motion estimation | `imregdeform`, `imreggroupwise`, displacement field visualization |

## Analysis (3 cards)

| Card | Description | Key Functions |
|------|-------------|---------------|
| [`radiomics-features.md`](cards/radiomics-features.md) | IBSI-compliant radiomics: intensity, shape, and texture features for clinical research | `intensityFeatures`, `shapeFeatures`, `textureFeatures`, feature normalization |
| [`segmentation-medsam.md`](cards/segmentation-medsam.md) | Medical Segment Anything Model (MedSAM) for interactive AI segmentation with point/box prompts | `medicalSegmentAnythingModel`, `extractEmbeddings`, `segmentObjectsFromEmbeddings` |
| [`segmentation-cellpose.md`](cards/segmentation-cellpose.md) | Cellpose for microscopy: cell/nuclei detection, pretrained models, custom training, whole slide images | `segmentCells2D`, `segmentCells3D`, `trainCellpose`, `refineCellpose` |

## Workflows (3 cards)

| Card | Description | Key Functions |
|------|-------------|---------------|
| [`labeling-workflow.md`](cards/labeling-workflow.md) | Medical Image Labeler app, ground truth creation, MONAI Label integration, multi-labeler collaboration | `groundTruthMedical`, Medical Image Labeler app, label definitions |
| [`pacs-integration.md`](cards/pacs-integration.md) | PACS server connection, DICOM query/retrieve/store operations, clinical workflow patterns | `dicomConnection`, `dicomquery`, `dicomget`, `dicomstore` |
| [`cross-toolbox-ipt.md`](cards/cross-toolbox-ipt.md) | When to use IPT vs MIT, applying IPT functions to medical volumes, combined workflow patterns | Links to **matlab-image-processing-toolbox** skill |

---

## Card Selection Guide

### By Modality

| Modality | Recommended Cards |
|----------|-------------------|
| **CT** | `file-io-dicom.md`, `coordinate-systems.md`, `visualization-3d.md`, `radiomics-features.md` |
| **MRI** | `file-io-nifti-nrrd.md`, `medical-volume.md`, `registration-rigid.md`, `segmentation-medsam.md` |
| **PET/SPECT** | `file-io-dicom.md`, `registration-deformable.md`, `visualization-3d.md` (multimodal overlay) |
| **Ultrasound** | `medical-volume.md` (medicalImage for 2D series), `labeling-workflow.md` |
| **Microscopy** | `segmentation-cellpose.md`, `cross-toolbox-ipt.md` |

### By Task

| Task | Cards to Read |
|------|---------------|
| Load and display medical image | `file-io-dicom.md` or `file-io-nifti-nrrd.md`, then `visualization-3d.md` |
| Understand coordinates | `coordinate-systems.md` (read first!) |
| Register pre/post contrast | `registration-rigid.md` |
| Register different modalities | `registration-deformable.md` |
| Extract quantitative features | `radiomics-features.md` |
| Interactive AI segmentation | `segmentation-medsam.md` |
| Cell counting | `segmentation-cellpose.md` |
| Create training data | `labeling-workflow.md` |
| Connect to hospital PACS | `pacs-integration.md` |
| Apply filters/morphology | `cross-toolbox-ipt.md` → **matlab-image-processing-toolbox** |

### By Experience Level

**Beginner:**
1. Start with `coordinate-systems.md` - understanding coordinates prevents most errors
2. Then `file-io-dicom.md` or `file-io-nifti-nrrd.md` for your data format
3. Then `medical-volume.md` for the core object
4. Then `visualization-3d.md` for display

**Intermediate:**
- Add `registration-rigid.md` for alignment tasks
- Add `cross-toolbox-ipt.md` for processing pipelines
- Add `radiomics-features.md` for quantitative analysis

**Advanced:**
- `registration-deformable.md` for complex registration
- `segmentation-medsam.md` or `segmentation-cellpose.md` for AI workflows
- `pacs-integration.md` for clinical deployment

---

## Cross-References to Other Skills

| Need | Skill | Key Cards |
|------|-------|-----------|
| Filtering, denoising | **matlab-image-processing-toolbox** | `filtering-denoising.md` |
| Segmentation, thresholding | **matlab-image-processing-toolbox** | `segmentation-thresholding.md`, `morphology-binary.md` |
| Region measurements | **matlab-image-processing-toolbox** | `feature-regions.md` |
| Deep learning segmentation | **matlab-image-processing-toolbox** | `deep-learning-segmentation.md` |
| Wavelet denoising | **matlab-wavelet-toolbox** | Wavelet-based denoising cards |

---

*Navigation: Return to [SKILL.md](../SKILL.md) for overview*
