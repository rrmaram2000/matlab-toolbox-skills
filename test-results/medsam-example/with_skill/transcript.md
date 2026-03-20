# MedSAM Tumor Segmentation - Skill-Guided Transcript

## Task

Segment a tumor from a CT NIfTI volume using MedSAM in MATLAB R2025b, with interactive point prompts on one slice and 3D propagation.

## Knowledge Cards Consulted

1. **SKILL.md** - Main skill file for Medical Imaging Toolbox. Identified Critical Rules (coordinate systems, always use medicalVolume, check orientation) and the MedSAM quick pattern.
2. **INDEX.md** - Directed to `segmentation-medsam.md` as the primary card, plus `file-io-nifti-nrrd.md` and `visualization-3d.md` for supporting patterns.
3. **segmentation-medsam.md** - Core reference for the implementation. Provided:
   - `medicalSegmentAnythingModel` constructor with GPU option
   - `extractEmbeddings` for caching image features
   - `segmentObjectsFromEmbeddings(model, embeddings, imageSize, ...)` R2025b signature with required `imageSize` parameter
   - `ForegroundPoints` and `BackgroundPoints` name-value syntax
   - Interactive `ginput` loop for point selection
   - `segment3DFromSeed` pattern for slice-by-slice propagation using centroid of previous mask
   - Performance tips: reuse embeddings, GPU acceleration
4. **file-io-nifti-nrrd.md** - Confirmed `medicalVolume('file.nii')` preserves spatial referencing. NIfTI modality defaults to 'unknown'; set `Modality = 'SEG'` for segmentation output.
5. **visualization-3d.md** - Confirmed `labelvolshow` is REMOVED in R2025b; must use `volshow(V.Voxels, OverlayData=labels)` with `OverlayColormap` and `OverlayAlphamap`.

## Key Skill-Guided Decisions

| Decision | Skill Guidance Applied |
|----------|----------------------|
| Load via `medicalVolume` not `niftiread` | Critical Rule 2: Always use medicalVolume for spatial context |
| Use `extractSlice(V, k, 'transverse')` | Critical Rule 3: Check orientation before slice extraction |
| Pass `imageSize` to `segmentObjectsFromEmbeddings` | Card: R2025b requires imageSize as 3rd positional argument |
| Use `volshow(..., OverlayData=...)` not `labelvolshow` | Card + MEMORY.md: labelvolshow removed in R2025b |
| Use `ForegroundPoints=` / `BackgroundPoints=` name-value syntax | Card: point prompt API |
| Propagate via centroid of previous mask | Card: `segment3DFromSeed` pattern |
| Area-ratio stopping criterion | Added beyond card guidance for robustness |
| Post-process with IPT (`imfill`, `imclose`, `bwconncomp`) | Critical Rule 6: Cross-toolbox workflow, MIT for I/O + IPT for pixel processing |
| Save with `write(segVol, 'output.nii.gz')` | Card: preserve spatial referencing on output |
| Compute physical volume via `V.VoxelSpacing` | Card: coordinate-systems, intrinsic-to-world |

## Code Structure

```
medsam_tumor_segmentation.m
  Step 1:  Load NIfTI CT as medicalVolume
  Step 2:  Load MedSAM model (GPU/CPU)
  Step 3:  Select and extract seed slice
  Step 4:  Interactive ginput loop (FG/BG points)
  Step 5:  Segment seed slice with point prompts
  Step 6:  Propagate up and down through volume
  Step 7:  Post-process 3D mask (morphology, largest component)
  Step 8:  Compute tumor volume in mm^3 / cm^3
  Step 9:  Visualize (seed overlay, montage, 3D volshow)
  Step 10: Save NIfTI segmentation + stats + PNG
```

## R2025b API Compliance

- `segmentObjectsFromEmbeddings(model, embeddings, imageSize, ...)` -- imageSize is required (not optional)
- `volshow(V.Voxels, OverlayData=uint8(mask))` -- labelvolshow removed
- `medicalSegmentAnythingModel('ExecutionEnvironment', 'gpu')` -- GPU acceleration
- `medicalVolume(uint8(mask), V.VolumeGeometry)` with `.Modality = 'SEG'` -- standard segmentation output
