---
name: matlab-medical-imaging-toolbox
description: "MATLAB Medical Imaging Toolbox. Functions - medicalVolume, dicomread, dicominfo, dicomCollection, niftiread, niftiinfo, nrrdread, medicalref3d, intrinsicToWorld, worldToIntrinsic, volshow, sliceViewer, imregmoment, imregdeform, imregtform, radiomics, intensityFeatures, shapeFeatures, textureFeatures, medicalSegmentAnythingModel, segmentCells2D, dicomConnection, dicomquery, dicomget. Tasks - load medical scans, read DICOM series, open NIfTI or NRRD files, convert patient and voxel coordinates, visualize 3D volumes, overlay segmentation, align MRI or CT scans, register pre and post treatment images, extract radiomics features, segment with MedSAM or Cellpose, connect to PACS server, label ground truth, resample to isotropic spacing. Domains - DICOM, NIfTI, NRRD, MRI, CT, PET, PET/CT fusion, ultrasound, X-ray, brain imaging, liver segmentation, cardiac imaging, lung nodules, tumor analysis, clinical workflows, PACS integration."
---

# MATLAB Medical Imaging Toolbox

Expert skill for 3D medical image analysis using MATLAB's Medical Imaging Toolbox (MIT R2025b+).

**Cross-Toolbox Note:** For filtering, segmentation, and morphology operations, see **matlab-image-processing-toolbox** skill. MIT handles I/O, spatial referencing, registration, and medical-specific workflows.

## When to Use This Skill

- Reading/writing DICOM series, NIfTI (.nii/.nii.gz), or NRRD files
- Creating `medicalVolume` objects with spatial referencing
- Converting between Patient (world) and Intrinsic (voxel) coordinates
- 3D volume visualization (`volshow`, `sliceViewer`)
- Medical image registration (rigid, affine, deformable, multimodal)
- Radiomics feature extraction (IBSI-compliant)
- AI-assisted segmentation with MedSAM or Cellpose
- PACS server integration for DICOM retrieval
- Multi-modality workflows (PET/CT fusion, MRI series)
- Ground truth labeling with Medical Image Labeler app

## Read Before Coding

| Task | Knowledge Card | Key Functions |
|------|----------------|---------------|
| Read DICOM series | `file-io-dicom.md` | `medicalVolume`, `dicomread`, `dicomCollection` |
| Load NIfTI/NRRD | `file-io-nifti-nrrd.md` | `niftiread`, `nrrdread`, `niftiinfo` |
| Create medical volume | `medical-volume.md` | `medicalVolume`, `medicalImage`, `medicalref3d` |
| Coordinate conversion | `coordinate-systems.md` | `intrinsicToWorld`, `worldToIntrinsic` |
| 3D visualization | `visualization-3d.md` | `volshow`, `sliceViewer`, `labelvolshow` |
| Rigid registration | `registration-rigid.md` | `imregmoment`, `imregicp`, `fitgeotform3d` |
| Deformable registration | `registration-deformable.md` | `imregdeform`, `imreggroupwise` |
| Extract radiomics | `radiomics-features.md` | `intensityFeatures`, `shapeFeatures`, `textureFeatures` |
| Segment with MedSAM | `segmentation-medsam.md` | `medicalSegmentAnythingModel` |
| Cell detection | `segmentation-cellpose.md` | `segmentCells2D`, `trainCellpose` |
| Label ground truth | `labeling-workflow.md` | `groundTruthMedical`, Medical Image Labeler |
| PACS server access | `pacs-integration.md` | `dicomConnection`, `dicomquery`, `dicomget` |
| Apply filtering | `cross-toolbox-ipt.md` | **→ See IPT skill** |
| Threshold/segment | `cross-toolbox-ipt.md` | **→ See IPT skill** |

## Critical Rules

### Rule 1: Coordinate Systems - The #1 Source of Errors

Medical images have TWO coordinate systems:

| System | Units | Origin | Use Case |
|--------|-------|--------|----------|
| **Intrinsic** | Voxel indices (i,j,k) | Corner of first voxel | Array indexing, IPT functions |
| **Patient/World** | Physical units (mm) | DICOM-defined patient origin | Clinical measurements, registration |

```matlab
% WRONG: Mixing coordinate systems
pixel = V.Voxels(100, 200, 50);  % Intrinsic indexing
world_point = [100, 200, 50];    % Treating indices as world coords!

% CORRECT: Explicit conversion (separate coordinate arrays)
V = medicalVolume('scan.nii');
i = 100; j = 200; k = 50;  % Voxel indices
[x, y, z] = intrinsicToWorld(V.VolumeGeometry, i, j, k);
% x, y, z are now in mm, in patient coordinate system
world_point = [x, y, z];

% Convert back (also requires separate arrays)
[row, col, slice] = worldToSubscript(V.VolumeGeometry, x, y, z);
```

### Rule 2: Always Use medicalVolume for Spatial Context

Never read raw voxels without spatial information:

```matlab
% WRONG: Loses spatial referencing
data = niftiread('brain.nii');  % Just a 3D array, no spatial info

% CORRECT: Preserves geometry
V = medicalVolume('brain.nii');
% V.VolumeGeometry contains transformation matrix
% V.VoxelSpacing is in mm
% V.SpatialUnits documents the units
```

### Rule 3: Check Orientation Before Slice Extraction

Slice orientation depends on acquisition, not array dimension:

```matlab
V = medicalVolume('scan.dcm');

% Check orientation
disp(V.Orientation);        % 'transverse', 'sagittal', or 'coronal'
disp(V.PlaneMapping);       % Maps dimensions to anatomical planes

% Extract slices in patient coordinates (not array indices!)
slice = extractSlice(V, 50, 'transverse');  % 50th transverse slice

% For axial browsing regardless of acquisition:
sliceViewer(V);  % Automatically handles orientation
```

### Rule 4: DICOM Metadata First

Always inspect metadata before processing:

```matlab
% Get collection info for DICOM series
collection = dicomCollection('DICOM_folder');
disp(collection.Properties.VariableNames);

% Check modality, series description
info = dicominfo('slice001.dcm');
fprintf('Modality: %s\n', info.Modality);
fprintf('Series: %s\n', info.SeriesDescription);
fprintf('Spacing: %.2f x %.2f x %.2f mm\n', ...
    info.PixelSpacing(1), info.PixelSpacing(2), info.SliceThickness);
```

### Rule 5: Memory Management for 3D Volumes

Large volumes (512×512×500+) require careful memory handling:

```matlab
% Check volume size before loading
info = niftiinfo('large_scan.nii');
voxels = prod(info.ImageSize);
bytes_needed = voxels * info.BitsPerPixel / 8;
fprintf('Size: %.2f GB\n', bytes_needed / 1e9);

% Process slice-by-slice for huge volumes
for k = 1:V.NumTransverseSlices
    slice = extractSlice(V, k, 'transverse');
    % Process slice using IPT functions
    processed = imgaussfilt(slice, 1.5);  % IPT
    V = replaceSlice(V, processed, k, 'transverse');
end
```

### Rule 6: Cross-Toolbox Workflow

MIT handles I/O and spatial referencing; IPT handles pixel-level processing:

```matlab
% Load with MIT (preserves spatial info)
V = medicalVolume('scan.nii');

% Process with IPT (see matlab-image-processing-toolbox skill)
voxels = im2double(V.Voxels);
voxels = imgaussfilt3(voxels, 1.5);           % Gaussian smoothing
voxels = adapthisteq(voxels, 'NumTiles', [4 4 4]);  % CLAHE

% Segment with IPT
level = graythresh(voxels(:));
mask = voxels > level;
mask = imopen(mask, strel('sphere', 3));      % Morphological cleanup

% Create labeled volume with MIT (preserves spatial context)
labelVol = medicalVolume(uint8(mask), V.VolumeGeometry);
labelVol.Modality = 'SEG';
write(labelVol, 'segmentation.nii');
```

## Quick Patterns

### Load DICOM Series to medicalVolume

```matlab
% From directory of DICOM files
V = medicalVolume('path/to/dicom_folder');

% From dicomCollection for multi-series
coll = dicomCollection('patient_folder', 'IncludeSubfolders', true);
disp(coll);  % Shows all series

% Load specific series
V = medicalVolume(coll, 'Rows', 2);  % 2nd series in collection
```

### Extract Slice in Patient Coordinates

```matlab
V = medicalVolume('brain.nii');

% Get middle slices in each plane
midT = round(V.NumTransverseSlices / 2);
midC = round(V.NumCoronalSlices / 2);
midS = round(V.NumSagittalSlices / 2);

transverse = extractSlice(V, midT, 'transverse');
coronal = extractSlice(V, midC, 'coronal');
sagittal = extractSlice(V, midS, 'sagittal');

% Display
figure;
subplot(1,3,1); imshow(transverse, []); title('Transverse');
subplot(1,3,2); imshow(coronal, []); title('Coronal');
subplot(1,3,3); imshow(sagittal, []); title('Sagittal');
```

### Register Two Volumes

```matlab
fixed = medicalVolume('pre_contrast.nii');
moving = medicalVolume('post_contrast.nii');

% Rigid registration (fast, for same-modality)
[registered, tform] = imregmoment(moving, fixed);

% Affine registration with optimization
[optimizer, metric] = imregconfig('monomodal');
tform = imregtform(moving.Voxels, moving.VolumeGeometry, ...
                   fixed.Voxels, fixed.VolumeGeometry, ...
                   'affine', optimizer, metric);

% Apply transformation
registered = imwarp(moving.Voxels, tform, 'OutputView', ...
    imref3d(size(fixed.Voxels)));
```

### Extract Radiomics Features

```matlab
V = medicalVolume('tumor_scan.nii');
mask = medicalVolume('tumor_mask.nii');

% Resample to isotropic (required for some features)
V_iso = resample(V, [1 1 1]);  % 1mm isotropic
mask_iso = resample(mask, [1 1 1]);

% Create radiomics object first (required pattern)
R = radiomics(V_iso.Voxels, mask_iso.Voxels > 0);

% Extract IBSI-compliant features as methods of radiomics object
intensity = intensityFeatures(R);
shape = shapeFeatures(R);
texture = textureFeatures(R);

% Combine into table
features = [intensity, shape, texture];
```

### Segment with MedSAM

```matlab
% Load model (requires support package)
model = medicalSegmentAnythingModel;

% Load image and extract embeddings
V = medicalVolume('liver_ct.nii');
slice = extractSlice(V, 50, 'transverse');
embeddings = extractEmbeddings(model, slice);

% Get image size (required parameter)
imageSize = size(slice);

% Segment with bounding box prompt (imageSize is required)
bbox = [100, 100, 200, 150];  % [x, y, width, height]
[mask, score] = segmentObjectsFromEmbeddings(model, embeddings, imageSize, ...
    BoundingBox=bbox);
```

## Function Quick Reference

### File I/O
| Function | Purpose | Example |
|----------|---------|---------|
| `medicalVolume` | Load 3D medical image | `V = medicalVolume('scan.nii')` |
| `medicalImage` | Load 2D medical image series | `I = medicalImage('us_video.dcm')` |
| `dicomread` | Read single DICOM file | `img = dicomread('slice.dcm')` |
| `dicominfo` | Read DICOM metadata | `info = dicominfo('slice.dcm')` |
| `dicomCollection` | Catalog DICOM folders | `coll = dicomCollection(folder)` |
| `niftiread` | Read NIfTI file | `data = niftiread('brain.nii')` |
| `nrrdread` | Read NRRD file | `data = nrrdread('scan.nrrd')` |
| `write` | Write medicalVolume to NIfTI | `write(V, 'output.nii')` |

### Spatial Referencing
| Function | Purpose | Example |
|----------|---------|---------|
| `medicalref3d` | Create spatial reference | `R = medicalref3d(volumeSize, voxelSpacing)` |
| `intrinsicToWorld` | Voxel to patient coords | `[X,Y,Z] = intrinsicToWorld(R, I, J, K)` |
| `worldToIntrinsic` | Patient to voxel coords | `[I,J,K] = worldToIntrinsic(R, X, Y, Z)` |
| `worldToSubscript` | Patient coords to indices | `[row,col,slice] = worldToSubscript(R, X, Y, Z)` |
| `extractSlice` | Get slice in patient space | `s = extractSlice(V, n, 'transverse')` |
| `resample` | Resample to new resolution | `V2 = resample(V, [1 1 1])` |

### Visualization
| Function | Purpose | Example |
|----------|---------|---------|
| `volshow` | 3D volume rendering | `volshow(V)` or `volshow(V, OverlayData=L)` |
| `sliceViewer` | Orthogonal slice browser | `sliceViewer(V)` |
| ~~`labelvolshow`~~ | **REMOVED in R2025b** | Use `volshow(V, OverlayData=labels)` instead |
| `montage` | 2D slice montage | `montage(V.Voxels)` |
| `implay` | Video playback (2D series) | `implay(I)` |

### Registration
| Function | Purpose | Example |
|----------|---------|---------|
| `imregmoment` | Fast moment-based rigid | `[tform, reg] = imregmoment(moving, fixed)` |
| `imregicp` | Iterative closest point | `[regSurf, tform] = imregicp(surf1, surf2)` |
| `imregdeform` | Deformable registration | `D = imregdeform(moving, fixed)` |
| `imreggroupwise` | Groupwise registration | `tforms = imreggroupwise(volumes)` |
| `fitgeotform3d` | Landmark-based transform | `tform = fitgeotform3d(pts1, pts2, 'affine')` |

### Radiomics
| Function | Purpose | Example |
|----------|---------|---------|
| `radiomics` | Create radiomics object | `R = radiomics(data, roi)` |
| `intensityFeatures` | Histogram-based features | `F = intensityFeatures(R)` |
| `shapeFeatures` | 3D shape descriptors | `F = shapeFeatures(R)` |
| `textureFeatures` | GLCM, GLRLM, etc. | `F = textureFeatures(R)` |

### AI Segmentation
| Function | Purpose | Example |
|----------|---------|---------|
| `medicalSegmentAnythingModel` | Load MedSAM | `model = medicalSegmentAnythingModel` |
| `extractEmbeddings` | Compute image embeddings | `emb = extractEmbeddings(model, img)` |
| `segmentObjectsFromEmbeddings` | Segment with prompts | `mask = segmentObjectsFromEmbeddings(...)` |
| `segmentCells2D`* | Cellpose 2D segmentation | `L = segmentCells2D(img, 'cyto')` |
| `segmentCells3D`* | Cellpose 3D segmentation | `L = segmentCells3D(V, 'nuclei')` |
| `trainCellpose`* | Train custom Cellpose | `model = trainCellpose(ds, opts)` |

> **\*** Cellpose functions require the "Deep Learning Toolbox Model for Cellpose" support package. Install via Add-On Explorer.

### PACS Integration
| Function | Purpose | Example |
|----------|---------|---------|
| `dicomConnection` | Connect to PACS | `conn = dicomConnection(ip, port)` |
| `dicomquery` | Query PACS for studies | `results = dicomquery(conn, 'Study')` |
| `dicomget` | Retrieve images | `dicomget(conn, results, folder)` |
| `dicomstore` | Send images to PACS | `dicomstore(conn, folder)` |

## Knowledge Cards

Detailed documentation organized by topic:

**File I/O:**
- `knowledge/cards/file-io-dicom.md` - DICOM reading, metadata, series handling
- `knowledge/cards/file-io-nifti-nrrd.md` - NIfTI and NRRD formats

**Core Concepts:**
- `knowledge/cards/medical-volume.md` - medicalVolume class and properties
- `knowledge/cards/coordinate-systems.md` - Patient vs Intrinsic coordinates (CRITICAL)
- `knowledge/cards/visualization-3d.md` - volshow, sliceViewer, rendering options

**Registration:**
- `knowledge/cards/registration-rigid.md` - Rigid/affine registration methods
- `knowledge/cards/registration-deformable.md` - Deformable and groupwise registration

**Analysis:**
- `knowledge/cards/radiomics-features.md` - IBSI-compliant radiomics extraction
- `knowledge/cards/segmentation-medsam.md` - Medical Segment Anything Model
- `knowledge/cards/segmentation-cellpose.md` - Cellpose for microscopy

**Workflows:**
- `knowledge/cards/labeling-workflow.md` - Medical Image Labeler app
- `knowledge/cards/pacs-integration.md` - PACS server communication
- `knowledge/cards/cross-toolbox-ipt.md` - Using IPT functions with MIT

## Cross-Toolbox Integration

**For filtering, segmentation, and morphology → matlab-image-processing-toolbox**

| MIT Task | IPT Function | IPT Knowledge Card |
|----------|--------------|-------------------|
| Denoise volume slices | `imgaussfilt`, `medfilt2`, `wiener2` | `filtering-denoising.md` |
| Enhance contrast | `adapthisteq`, `imadjust` | `filtering-denoising.md` |
| Threshold volume | `graythresh`, `imbinarize` | `segmentation-thresholding.md` |
| Clean binary masks | `imopen`, `imclose`, `imfill`, `bwareaopen` | `morphology-binary.md` |
| Measure regions | `regionprops3`, `bwconncomp` | `feature-regions.md` |
| Detect edges | `edge`, `imgradient` | `feature-edges.md` |
| Data type conversion | `im2double`, `im2uint8` | `data-types.md` |

**For wavelet-based denoising → matlab-wavelet-toolbox**

```matlab
% Combined workflow: MIT + IPT + Wavelet
V = medicalVolume('noisy_mri.nii');           % MIT: Load with spatial info

% Process each slice (IPT + Wavelet)
for k = 1:size(V.Voxels, 3)
    slice = im2double(V.Voxels(:,:,k));       % IPT: Convert type
    slice = wdenoise2(slice);                  % Wavelet: Denoise
    slice = adapthisteq(slice);                % IPT: Enhance
    V.Voxels(:,:,k) = slice;
end

write(V, 'enhanced_mri.nii');                  % MIT: Write with spatial info
```

---
*Source: MathWorks Medical Imaging Toolbox Documentation (R2025b)*
*User Guide: 468 pages | Function Reference: 362 pages*
