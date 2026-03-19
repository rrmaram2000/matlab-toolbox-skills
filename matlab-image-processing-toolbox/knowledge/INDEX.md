# MATLAB Image Processing Toolbox - Knowledge Index

Quick reference to knowledge cards and template scripts. Cards are trimmed to focus on medical-specific patterns and gotchas — the model already knows standard IPT functions well.

## Card Catalog

### Medical Imaging (Primary)

| Card | Focus | Key Value |
|------|-------|-----------|
| `cards/medical-mri.md` | MRI preprocessing, tissue segmentation, volumetry | Full domain-specific pipelines |
| `cards/medical-microscopy.md` | Cell counting, fluorescence, H&E histology | Complete analysis workflows |

### Medical-Specific Patterns (Trimmed)

| Card | Focus | Key Value |
|------|-------|-----------|
| `cards/filtering-denoising.md` | Modality-specific denoising | Rician/speckle/Poisson noise handling |
| `cards/segmentation-thresholding.md` | Tissue thresholding | Multi-level for brain, CT bone HU thresholds |
| `cards/morphology-binary.md` | Medical cleanup recipes | Cell/vessel/bone/brain mask recipes |
| `cards/feature-regions.md` | Advanced regionprops | Tumor measurement, cell population analysis |

### Integration (Trimmed)

| Card | Focus | Key Value |
|------|-------|-----------|
| `cards/deep-learning-segmentation.md` | DL + IPT integration | Post-processing DL output, patch-based inference |
| `cards/data-types.md` | Type conversion gotchas | DICOM/NIfTI format handling |

## Template Scripts

Ready-to-use medical imaging pipelines in `scripts/`:

| Script | Medical Domain |
|--------|---------------|
| `template_mri_preprocessing.m` | MRI bias correction, denoising, brain extraction |
| `template_ct_windowing.m` | CT Hounsfield unit windowing |
| `template_cell_counting.m` | Automated cell detection and counting |
| `template_fluorescence_quantification.m` | Multi-channel fluorescence analysis |
| `template_histology_stain_normalization.m` | H&E color deconvolution |
| `template_adaptive_thresholding.m` | Adaptive thresholding with sensitivity tuning |
| `template_watershed_segmentation.m` | Marker-controlled watershed |
| `template_morphological_cleanup.m` | Binary mask cleanup pipeline |
| `template_large_image_blockproc.m` | Block processing for large images |
| `template_edge_detection_pipeline.m` | Multi-method edge detection |

## Task-to-Resource Mapping

| If you need to... | Read this card | Use this template |
|-------------------|----------------|-------------------|
| Process brain MRI | `medical-mri.md` | `template_mri_preprocessing.m` |
| Count cells | `medical-microscopy.md` | `template_cell_counting.m` |
| Window CT scans | `medical-mri.md` | `template_ct_windowing.m` |
| Quantify fluorescence | `medical-microscopy.md` | `template_fluorescence_quantification.m` |
| Normalize H&E stains | `medical-microscopy.md` | `template_histology_stain_normalization.m` |
| Separate touching objects | `medical-microscopy.md` | `template_watershed_segmentation.m` |
| Clean up a binary mask | `morphology-binary.md` | `template_morphological_cleanup.m` |
| Process large images | — | `template_large_image_blockproc.m` |
| Fix data type errors | `data-types.md` | — |
| Denoise medical images | `filtering-denoising.md` | — |
| Post-process DL output | `deep-learning-segmentation.md` | — |
| Measure tumor/regions | `feature-regions.md` | — |

---
*MATLAB Image Processing Toolbox Skill v2.0 — Restructured based on Phase 1 eval findings*
