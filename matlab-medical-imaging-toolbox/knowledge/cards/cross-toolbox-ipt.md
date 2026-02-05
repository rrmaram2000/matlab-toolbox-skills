# Cross-Toolbox Integration: MIT + IPT

Medical Imaging Toolbox (MIT) and Image Processing Toolbox (IPT) are complementary. MIT handles medical-specific I/O and workflows; IPT provides pixel-level processing. This card shows when and how to use each.

## When to Use Each Toolbox

| Task | Use MIT | Use IPT |
|------|---------|---------|
| Read DICOM/NIfTI/NRRD | ✅ `medicalVolume` | ❌ |
| Spatial referencing | ✅ `medicalref3d` | ❌ |
| Coordinate transforms | ✅ `intrinsicToWorld` | ❌ |
| 3D volume rendering | ✅ `volshow` | ❌ |
| Medical registration | ✅ `imregmoment` | ❌ |
| Radiomics features | ✅ `intensityFeatures` | ❌ |
| MedSAM/Cellpose | ✅ AI models | ❌ |
| PACS integration | ✅ `dicomConnection` | ❌ |
| Gaussian filtering | ❌ | ✅ `imgaussfilt`, `imgaussfilt3` |
| Median filtering | ❌ | ✅ `medfilt2`, `medfilt3` |
| Thresholding | ❌ | ✅ `graythresh`, `imbinarize` |
| Morphology | ❌ | ✅ `imopen`, `imclose`, `imfill` |
| Edge detection | ❌ | ✅ `edge`, `imgradient` |
| Region properties | ❌ | ✅ `regionprops`, `regionprops3` |
| Data type conversion | ❌ | ✅ `im2double`, `im2uint8` |

## IPT Knowledge Cards to Reference

For detailed IPT documentation, see **matlab-image-processing-toolbox** skill:

| IPT Card | When to Use |
|----------|-------------|
| `filtering-denoising.md` | Noise reduction in medical images |
| `filtering-spatial.md` | Custom convolution filters |
| `segmentation-thresholding.md` | Otsu, adaptive, multi-level thresholds |
| `segmentation-watershed.md` | Separating touching structures |
| `morphology-binary.md` | Binary mask cleanup |
| `feature-edges.md` | Edge detection |
| `feature-regions.md` | regionprops measurements |
| `deep-learning-segmentation.md` | semanticseg, U-Net |
| `data-types.md` | Type conversions |
| `memory-performance.md` | blockproc, GPU |

## Common Combined Workflows

### Load → Process → Save

```matlab
% MIT: Load with spatial referencing
V = medicalVolume('scan.nii');

% IPT: Convert to double for processing
voxels = im2double(V.Voxels);

% IPT: Denoise
voxels = imgaussfilt3(voxels, 1.5);

% IPT: Enhance contrast (CLAHE)
for k = 1:size(voxels, 3)
    voxels(:,:,k) = adapthisteq(voxels(:,:,k));
end

% IPT: Back to original type
V.Voxels = im2uint16(voxels);

% MIT: Save with preserved spatial info
write(V, 'processed.nii');
```

### Segment and Measure

```matlab
% MIT: Load
V = medicalVolume('tumor_scan.nii');

% IPT: Threshold
level = graythresh(mat2gray(V.Voxels));
mask = imbinarize(mat2gray(V.Voxels), level);

% IPT: Morphological cleanup
se = strel('sphere', 3);
mask = imopen(mask, se);
mask = imclose(mask, se);
mask = imfill(mask, 'holes');
mask = bwareaopen(mask, 1000);  % Remove small objects

% IPT: Measure regions
props = regionprops3(mask, V.Voxels, ...
    'Volume', 'Centroid', 'MeanIntensity', 'PrincipalAxisLength');

% MIT: Convert measurements to world coordinates
R = V.VolumeGeometry;
for i = 1:height(props)
    props.CentroidWorld(i,:) = intrinsicToWorld(R, props.Centroid(i,:));
    % Volume in mm³ = voxel volume × voxel count
    props.VolumeWorld(i) = props.Volume(i) * prod(V.VoxelSpacing);
end

disp(props);
```

### Filter Each Slice

```matlab
V = medicalVolume('noisy_mri.nii');

% Process slice-by-slice (for 2D-only filters)
for k = 1:size(V.Voxels, 3)
    slice = im2double(V.Voxels(:,:,k));

    % IPT: Apply 2D filters
    slice = wiener2(slice, [5 5]);          % Adaptive noise removal
    slice = adapthisteq(slice);              % Contrast enhancement

    V.Voxels(:,:,k) = slice;
end

% MIT: Save
write(V, 'filtered.nii');
```

### Edge Detection on Volume

```matlab
V = medicalVolume('scan.nii');

% Initialize edge volume
edges = false(size(V.Voxels));

% IPT: Detect edges slice-by-slice
for k = 1:size(V.Voxels, 3)
    slice = mat2gray(V.Voxels(:,:,k));
    edges(:,:,k) = edge(slice, 'Canny');
end

% MIT: Create edge volume with same geometry
V_edges = medicalVolume(uint8(edges) * 255, V.VolumeGeometry);
write(V_edges, 'edges.nii');
```

### Watershed Segmentation

```matlab
V = medicalVolume('cells_3d.nii');

% IPT: Preprocess
data = im2double(V.Voxels);
data = imgaussfilt3(data, 1);

% IPT: Binary mask
mask = data > graythresh(data(:));

% IPT: Distance transform for watershed
D = bwdist(~mask);
D = -D;
D = imhmin(D, 2);  % Suppress shallow minima

% IPT: Watershed
L = watershed(D);
L(~mask) = 0;  % Remove background

% IPT: Measure
props = regionprops3(L, V.Voxels, 'Volume', 'Centroid', 'MeanIntensity');

% Convert volumes to physical units
props.VolumeWorld = props.Volume * prod(V.VoxelSpacing);

fprintf('Found %d objects\n', height(props));
fprintf('Mean volume: %.2f mm³\n', mean(props.VolumeWorld));
```

## Data Type Considerations

### Type Ranges

| Type | Range | Use Case |
|------|-------|----------|
| `uint8` | [0, 255] | Display, storage |
| `uint16` | [0, 65535] | DICOM CT/MR |
| `int16` | [-32768, 32767] | CT Hounsfield units |
| `single` | ~±3.4e38 | GPU, deep learning |
| `double` | ~±1.8e308 | Computation, IPT |
| `logical` | 0 or 1 | Binary masks |

### Safe Conversions

```matlab
% MIT loads in native type
V = medicalVolume('ct.nii');
fprintf('Original type: %s\n', class(V.Voxels));

% IPT: Convert for processing
original_class = class(V.Voxels);
original_range = [min(V.Voxels(:)), max(V.Voxels(:))];

% Convert to double [0, 1]
data = im2double(V.Voxels);

% Process...
data = imgaussfilt3(data, 1);

% Convert back
switch original_class
    case 'uint8'
        V.Voxels = im2uint8(data);
    case 'uint16'
        V.Voxels = im2uint16(data);
    case 'int16'
        % Rescale to original range
        V.Voxels = int16(data * diff(original_range) + original_range(1));
    case {'single', 'double'}
        V.Voxels = cast(data * diff(original_range) + original_range(1), original_class);
end
```

### CT Hounsfield Units

```matlab
V = medicalVolume('ct.nii');

% CT is typically int16 with HU values
% -1000 HU = air, 0 HU = water, +1000 HU = bone

% For IPT processing, preserve HU scale
data = double(V.Voxels);  % Keep original range

% Apply soft tissue window for thresholding
% Window: center=40, width=400 -> [-160, 240] HU
soft_tissue = (data >= -160) & (data <= 240);

% Threshold within window
level = graythresh(mat2gray(data(soft_tissue)));
threshold_hu = level * 400 - 160;  % Convert back to HU

mask = data > threshold_hu;
```

## 3D vs 2D Processing

### 3D Filters (Preferred)

```matlab
% IPT provides 3D versions of common filters
V = medicalVolume('scan.nii');
data = im2double(V.Voxels);

% 3D Gaussian
filtered = imgaussfilt3(data, 1.5);

% 3D median (custom - medfilt3 exists in some toolboxes)
% For medfilt3 if not available:
filtered = ordfilt3D(data, 14, ones(3,3,3));  % Custom implementation
```

### 2D Slice-by-Slice

```matlab
% When 3D filter not available
V = medicalVolume('scan.nii');

for k = 1:size(V.Voxels, 3)
    slice = im2double(V.Voxels(:,:,k));

    % 2D filters
    slice = medfilt2(slice, [3 3]);
    slice = wiener2(slice, [5 5]);

    V.Voxels(:,:,k) = slice;
end
```

### Consider Anisotropy

```matlab
V = medicalVolume('scan.nii');
fprintf('Spacing: %s\n', mat2str(V.VoxelSpacing));
% e.g., [0.5, 0.5, 3.0] mm - anisotropic!

% For 3D Gaussian, adjust sigma per dimension
sigma_mm = 1.5;  % Physical sigma in mm
sigma_voxels = sigma_mm ./ V.VoxelSpacing;  % [3.0, 3.0, 0.5]

filtered = imgaussfilt3(im2double(V.Voxels), sigma_voxels);

% For morphology, consider resizing to isotropic first
% or use asymmetric structuring elements
se = strel('sphere', 3);  % Assumes isotropic
% Better: use flat disk for anisotropic
se_flat = strel('disk', 3);
for k = 1:size(V.Voxels, 3)
    V.Voxels(:,:,k) = imopen(V.Voxels(:,:,k), se_flat);
end
```

## GPU Acceleration

```matlab
V = medicalVolume('large_scan.nii');

% Check GPU availability
if canUseGPU()
    % Move to GPU
    data_gpu = gpuArray(im2double(V.Voxels));

    % IPT functions work on GPU
    filtered_gpu = imgaussfilt3(data_gpu, 1);
    enhanced_gpu = imadjust3(filtered_gpu);

    % Move back to CPU
    V.Voxels = gather(enhanced_gpu);

    fprintf('GPU processing complete\n');
else
    warning('GPU not available, using CPU');
    % CPU fallback
    data = im2double(V.Voxels);
    data = imgaussfilt3(data, 1);
    V.Voxels = data;
end
```

## Common Pitfalls

### Pitfall 1: Losing Spatial Information

```matlab
% WRONG: Process raw array, lose spatial info
data = niftiread('scan.nii');          % Raw array only
processed = imgaussfilt3(data, 1);
niftiwrite(processed, 'out.nii');       % No spatial info!

% CORRECT: Use medicalVolume
V = medicalVolume('scan.nii');
V.Voxels = imgaussfilt3(im2double(V.Voxels), 1);
write(V, 'out.nii');                    % Spatial info preserved
```

### Pitfall 2: Wrong Data Type for IPT

```matlab
V = medicalVolume('scan.nii');

% WRONG: Some IPT functions expect double
edges = edge(V.Voxels(:,:,50), 'Canny');  % May fail on int16

% CORRECT: Convert first
slice = im2double(V.Voxels(:,:,50));
edges = edge(slice, 'Canny');
```

### Pitfall 3: Ignoring Anisotropy in regionprops3

```matlab
V = medicalVolume('scan.nii');
mask = V.Voxels > threshold;

% WRONG: Volume in voxels only
props = regionprops3(mask, 'Volume');
fprintf('Volume: %d voxels\n', props.Volume);

% CORRECT: Convert to physical units
voxel_volume = prod(V.VoxelSpacing);  % mm³ per voxel
props.VolumeWorld = props.Volume * voxel_volume;
fprintf('Volume: %.2f mm³\n', props.VolumeWorld);
```

## Complete Pipeline Example

```matlab
function [V_seg, stats] = processLungCT(inputFile, outputFile)
    % Load CT scan (MIT)
    V = medicalVolume(inputFile);
    assert(V.Modality == "CT", 'Expected CT scan');

    % Convert to double (IPT)
    data = im2double(V.Voxels);

    % Denoise (IPT)
    data = imgaussfilt3(data, 0.5);

    % Threshold for lung tissue (IPT)
    % Lung is around -700 to -500 HU
    % Assuming data is normalized, estimate threshold
    mask = data < graythresh(data);

    % Clean morphology (IPT)
    se = strel('sphere', 3);
    mask = imclose(mask, se);
    mask = imfill(mask, 'holes');
    mask = bwareaopen(mask, 50000);  % Keep large regions only

    % Label connected components (IPT)
    L = bwlabeln(mask);

    % Measure regions (IPT)
    props = regionprops3(L, V.Voxels, ...
        'Volume', 'Centroid', 'BoundingBox', 'MeanIntensity');

    % Convert to world coordinates (MIT)
    voxel_vol = prod(V.VoxelSpacing);
    props.VolumeWorld = props.Volume * voxel_vol;
    for i = 1:height(props)
        props.CentroidWorld(i,:) = intrinsicToWorld(V.VolumeGeometry, props.Centroid(i,:));
    end

    stats = props;

    % Create segmentation volume (MIT)
    V_seg = medicalVolume(uint8(L), V.VolumeGeometry);
    V_seg.Modality = 'SEG';

    % Save (MIT)
    if nargin > 1
        write(V_seg, outputFile);
    end

    fprintf('Found %d lung regions\n', height(stats));
    fprintf('Total lung volume: %.0f mm³\n', sum(stats.VolumeWorld));
end
```

---

*This card bridges MIT and IPT - always check both toolboxes for optimal solutions*
*See: matlab-image-processing-toolbox skill for detailed IPT documentation*
