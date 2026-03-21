# Knowledge Card Index

Quick reference to all Medical Imaging Toolbox knowledge cards.

## Critical Cards (unique knowledge the model needs)

| Card | Priority | Description |
|------|----------|-------------|
| [`radiomics-features.md`](cards/radiomics-features.md) | **CRITICAL** | Object-oriented radiomics API: create `radiomics(data, roi)` first, then call methods on object |
| [`coordinate-systems.md`](cards/coordinate-systems.md) | **CRITICAL** | Patient vs Intrinsic coordinates, orientation conventions (RAS/LPS) |
| [`segmentation-medsam.md`](cards/segmentation-medsam.md) | **CRITICAL** | MedSAM workflows, `segmentObjectsFromEmbeddings` requires `imageSize` |
| [`segmentation-cellpose.md`](cards/segmentation-cellpose.md) | **CRITICAL** | Cell/nuclei segmentation: watershed, MedSAM, Python Cellpose integration |
| [`labeling-workflow.md`](cards/labeling-workflow.md) | **CRITICAL** | Medical Image Labeler app, MONAI Label integration |
| [`pacs-integration.md`](cards/pacs-integration.md) | **CRITICAL** | PACS server connection, DICOM query/retrieve/store |

## Reference Cards (edge cases and gotchas)

| Card | Description | Key Functions |
|------|-------------|---------------|
| [`file-io-dicom.md`](cards/file-io-dicom.md) | DICOM edge cases: private tags, metadata navigation, windowing | `dicomCollection`, `dicomanon`, `dicomwrite` |
| [`file-io-nifti-nrrd.md`](cards/file-io-nifti-nrrd.md) | NIfTI/NRRD edge cases: 4D data, NRRD write-only limitation, format conversion | `niftiread`, `nrrdread` |
| [`medical-volume.md`](cards/medical-volume.md) | Specialized `medicalVolume` patterns: read-only properties, `medicalImage` for 2D series | `medicalVolume`, `extractSlice`, `resample` |
| [`visualization-3d.md`](cards/visualization-3d.md) | Advanced rendering: transfer functions, CT bone rendering, STL export | `volshow`, `sliceViewer` |
| [`registration-rigid.md`](cards/registration-rigid.md) | Registration gotchas: multimodal tuning, quality metrics, edge artifacts | `imregmoment`, `imregtform`, `fitgeotform3d` |
| [`registration-deformable.md`](cards/registration-deformable.md) | Deformable gotchas: Jacobian folding, GridSpacing tuning, displacement fields | `imregdeform`, `imreggroupwise` |
| [`cross-toolbox-ipt.md`](cards/cross-toolbox-ipt.md) | Brief MIT+IPT integration patterns, anisotropy handling | Image Processing Toolbox (`imgaussfilt`, `imbinarize`, `regionprops`) |

## Template Scripts

Ready-to-use `.m` files in `scripts/` -- copy, rename, and adapt:

| Script | Related Card |
|--------|-------------|
| `template_dicom_series_loader.m` | `file-io-dicom.md` |
| `template_nifti_volume_processing.m` | `file-io-nifti-nrrd.md` |
| `template_coordinate_transform.m` | `coordinate-systems.md` |
| `template_volume_visualization.m` | `visualization-3d.md` |
| `template_rigid_registration.m` | `registration-rigid.md` |
| `template_deformable_registration.m` | `registration-deformable.md` |
| `template_radiomics_extraction.m` | `radiomics-features.md` |
| `template_medsam_segmentation.m` | `segmentation-medsam.md` |
| `template_cellpose_segmentation.m` | `segmentation-cellpose.md` |
| `template_labeling_workflow.m` | `labeling-workflow.md` |
| `template_pacs_query_retrieve.m` | `pacs-integration.md` |
| `template_multimodal_fusion.m` | `visualization-3d.md` |

---

## Card Selection Guide

### By Modality

| Modality | Recommended Cards |
|----------|-------------------|
| **CT** | `file-io-dicom.md`, `coordinate-systems.md`, `visualization-3d.md`, `radiomics-features.md` |
| **MRI** | `file-io-nifti-nrrd.md`, `medical-volume.md`, `registration-rigid.md`, `segmentation-medsam.md` |
| **PET/SPECT** | `file-io-dicom.md`, `registration-deformable.md`, `visualization-3d.md` (multimodal overlay) |
| **Ultrasound** | `medical-volume.md` (medicalImage for 2D series), `labeling-workflow.md` |
| **Microscopy** | `segmentation-cellpose.md` (cell segmentation), `cross-toolbox-ipt.md` |

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
| Apply filters/morphology | `cross-toolbox-ipt.md` -- use Image Processing Toolbox (`imgaussfilt`, `imbinarize`, `strel`) |

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

## Cross-Toolbox Functions

| Need | Toolbox & Functions |
|------|---------------------|
| Filtering, denoising | Image Processing Toolbox (`imgaussfilt`, `medfilt2`, `wiener2`) |
| Segmentation, thresholding | Image Processing Toolbox (`imbinarize`, `graythresh`, `watershed`) |
| Region measurements | Image Processing Toolbox (`regionprops`, `regionprops3`, `bwconncomp`) |
| Deep learning segmentation | Deep Learning Toolbox (`unet`, `trainnet`, `semanticseg`) |
| Wavelet denoising | Wavelet Toolbox (`wdenoise2`) |

---

*Navigation: Return to [SKILL.md](../SKILL.md) for overview*
