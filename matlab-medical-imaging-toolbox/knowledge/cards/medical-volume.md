# The medicalVolume Class

`medicalVolume` is the central object for working with 3D medical images in MATLAB. It encapsulates voxel data, spatial referencing, and metadata in a single object.

## Why Use medicalVolume?

| Without medicalVolume | With medicalVolume |
|----------------------|-------------------|
| Voxel data separate from geometry | All in one object |
| Manual coordinate transforms | Built-in `intrinsicToWorld` |
| Lost spatial info on save/load | Preserved automatically |
| Manual modality tracking | `Modality` property |
| Manual slice extraction | `extractSlice` method |

## Creating medicalVolume Objects

### From Files (Most Common)

```matlab
% From DICOM folder
V = medicalVolume('path/to/dicom_folder');

% From NIfTI file
V = medicalVolume('brain.nii');
V = medicalVolume('brain.nii.gz');  % Compressed

% From NRRD file
V = medicalVolume('scan.nrrd');

% From dicomCollection (specific series)
coll = dicomCollection('patient_data');
V = medicalVolume(coll, 'Rows', 2);  % Second series
```

### From Existing Data

```matlab
% From 3D array with geometry
data = rand(256, 256, 128);
geometry = medicalref3d([256, 256, 128], [1, 1, 2], [0, 0, 0]);
V = medicalVolume(data, geometry);

% Copy geometry from another volume
V_new = medicalVolume(processed_data, V_original.VolumeGeometry);
V_new.Modality = V_original.Modality;
```

## Properties Reference

### Core Properties

| Property | Type | Description |
|----------|------|-------------|
| `Voxels` | numeric array | 3D array of voxel intensities |
| `VolumeGeometry` | `medicalref3d` | Spatial reference object |
| `SpatialUnits` | string | Units (usually "mm") |
| `Modality` | string | "CT", "MR", "PT", "US", "SEG", etc. |

### Geometry Properties

| Property | Type | Description |
|----------|------|-------------|
| `VoxelSpacing` | 1×3 double | [x, y, z] spacing in SpatialUnits |
| `Orientation` | string | "transverse", "sagittal", "coronal" |
| `NormalVector` | 1×3 double | Direction normal to primary slices |
| `PlaneMapping` | 1×3 string | Maps dimensions to anatomical planes |
| `DataDimensionMeaning` | 1×3 string | What each dimension represents |

### Slice Counts

| Property | Type | Description |
|----------|------|-------------|
| `NumTransverseSlices` | double | Number of axial slices |
| `NumCoronalSlices` | double | Number of coronal slices |
| `NumSagittalSlices` | double | Number of sagittal slices |

### Display Properties (from DICOM)

| Property | Type | Description |
|----------|------|-------------|
| `WindowCenters` | Nx1 double | Display window centers per slice |
| `WindowWidths` | Nx1 double | Display window widths per slice |

## Key Methods

### extractSlice - Get Slice in Patient Coordinates

```matlab
V = medicalVolume('brain.nii');

% Extract by slice number and plane
transverse_50 = extractSlice(V, 50, 'transverse');
coronal_100 = extractSlice(V, 100, 'coronal');
sagittal_128 = extractSlice(V, 128, 'sagittal');

% Extract middle slice of each plane
midT = extractSlice(V, round(V.NumTransverseSlices/2), 'transverse');
midC = extractSlice(V, round(V.NumCoronalSlices/2), 'coronal');
midS = extractSlice(V, round(V.NumSagittalSlices/2), 'sagittal');

% Display
figure;
subplot(1,3,1); imshow(midT, []); title('Transverse');
subplot(1,3,2); imshow(midC, []); title('Coronal');
subplot(1,3,3); imshow(midS, []); title('Sagittal');
```

### replaceSlice - Modify Slice in Place

```matlab
V = medicalVolume('scan.nii');

% Process and replace transverse slices
for k = 1:V.NumTransverseSlices
    slice = extractSlice(V, k, 'transverse');

    % Process (using IPT functions)
    slice = medfilt2(slice);
    slice = adapthisteq(slice);

    % Replace
    V = replaceSlice(V, slice, k, 'transverse');
end
```

### resample - Change Resolution

```matlab
V = medicalVolume('anisotropic.nii');
fprintf('Original: %s mm\n', mat2str(V.VoxelSpacing));

% Resample to isotropic 1mm
V_iso = resample(V, [1, 1, 1]);
fprintf('Isotropic: %s mm\n', mat2str(V_iso.VoxelSpacing));

% Resample to match another volume
V_target = medicalVolume('reference.nii');
V_resampled = resample(V, V_target.VoxelSpacing);
```

### write - Save to File

```matlab
V = medicalVolume('input.nii');

% Process...
V.Voxels = imgaussfilt3(double(V.Voxels), 1.5);

% Write (only NIfTI format supported)
write(V, 'output.nii');
write(V, 'output.nii.gz');  % Compressed
```

## medicalImage for 2D Series

For 2D image series (ultrasound, cine MRI):

```matlab
% Load 2D series
I = medicalImage('ultrasound.dcm');

% Properties
disp(I.Pixels);       % 2D or 3D (frames) array
disp(I.NumFrames);    % Number of frames
disp(I.FrameTime);    % Time between frames (ms)
disp(I.PixelSpacing); % [x, y] spacing
disp(I.Modality);     % Usually 'US'

% Access frames
frame1 = I.Pixels(:,:,1);
frame10 = I.Pixels(:,:,10);

% Play as video
implay(I);
```

## Coordinate Transformations

See `coordinate-systems.md` for detailed explanation.

```matlab
V = medicalVolume('scan.nii');
R = V.VolumeGeometry;  % medicalref3d object

% Voxel indices to world coordinates
intrinsic = [100, 200, 50];  % Voxel (i, j, k)
world = intrinsicToWorld(R, intrinsic);
% world is now [x, y, z] in mm

% World to voxel indices
[i, j, k] = worldToSubscript(R, world);

% World to continuous intrinsic coordinates
intrinsic_cont = worldToIntrinsic(R, world);
```

## Common Patterns

### Load, Process, Save Pipeline

```matlab
function processVolume(inputFile, outputFile)
    % Load
    V = medicalVolume(inputFile);

    % Convert to double for processing
    original_class = class(V.Voxels);
    V.Voxels = im2double(V.Voxels);

    % Process (IPT functions - see cross-toolbox-ipt.md)
    V.Voxels = imgaussfilt3(V.Voxels, 1);
    V.Voxels = adapthisteq(V.Voxels(:), 'NumTiles', [8 8]);
    V.Voxels = reshape(V.Voxels, size(V.Voxels));

    % Convert back if needed
    if strcmp(original_class, 'int16')
        V.Voxels = int16(V.Voxels * 32767);
    end

    % Save
    write(V, outputFile);
end
```

### Create Labeled Volume from Mask

```matlab
% Original image volume
V_image = medicalVolume('scan.nii');

% Binary mask (same size as image)
mask = V_image.Voxels > threshold;
mask = imopen(mask, strel('sphere', 3));  % IPT cleanup

% Create label volume with same geometry
V_labels = medicalVolume(uint8(mask), V_image.VolumeGeometry);
V_labels.Modality = 'SEG';

% Save
write(V_labels, 'segmentation.nii');
```

### Compare Two Volumes

```matlab
function compareVolumes(file1, file2)
    V1 = medicalVolume(file1);
    V2 = medicalVolume(file2);

    % Check geometry match
    sameSize = isequal(size(V1.Voxels), size(V2.Voxels));
    sameSpacing = isequal(V1.VoxelSpacing, V2.VoxelSpacing);

    fprintf('Same size: %d\n', sameSize);
    fprintf('Same spacing: %d\n', sameSpacing);
    fprintf('V1 modality: %s\n', V1.Modality);
    fprintf('V2 modality: %s\n', V2.Modality);

    if sameSize
        % Compute difference
        diff = abs(double(V1.Voxels) - double(V2.Voxels));
        fprintf('Max difference: %.3f\n', max(diff(:)));
        fprintf('Mean difference: %.3f\n', mean(diff(:)));
    end
end
```

### Extract ROI Using World Coordinates

```matlab
V = medicalVolume('scan.nii');
R = V.VolumeGeometry;

% Define ROI in world coordinates (mm)
world_center = [50, 30, -20];  % mm
world_size = [40, 40, 30];     % mm

% Convert to voxel indices
corner1 = world_center - world_size/2;
corner2 = world_center + world_size/2;

[i1, j1, k1] = worldToSubscript(R, corner1);
[i2, j2, k2] = worldToSubscript(R, corner2);

% Ensure valid indices
i1 = max(1, min(size(V.Voxels,1), i1));
i2 = max(1, min(size(V.Voxels,1), i2));
% ... same for j, k

% Extract ROI
roi = V.Voxels(i1:i2, j1:j2, k1:k2);
```

## Memory Considerations

```matlab
V = medicalVolume('large_scan.nii');

% Check memory usage
voxel_count = numel(V.Voxels);
bytes_per_voxel = whos('V').bytes / voxel_count;
fprintf('Volume: %d voxels, %.2f GB\n', voxel_count, ...
    voxel_count * bytes_per_voxel / 1e9);

% For large volumes, process slice-by-slice
for k = 1:V.NumTransverseSlices
    slice = extractSlice(V, k, 'transverse');
    % Process 2D slice (uses less memory)
    processed = myProcessing(slice);
    V = replaceSlice(V, processed, k, 'transverse');
end
```

## Troubleshooting

### Issue: "Modality is 'unknown'"

**Cause:** NIfTI/NRRD files don't store modality information.

```matlab
V = medicalVolume('brain.nii');
V.Modality = 'MR';  % Set manually based on your knowledge
```

### Issue: Properties are read-only

Some properties are computed from VolumeGeometry:

```matlab
% Can't do this:
% V.VoxelSpacing = [1, 1, 2];  % Error!

% Instead, create new medicalref3d
newGeom = medicalref3d(size(V.Voxels), [1, 1, 2], [0, 0, 0]);
V_new = medicalVolume(V.Voxels, newGeom);
```

### Issue: Voxel data type unexpected

```matlab
V = medicalVolume('scan.nii');
fprintf('Data type: %s\n', class(V.Voxels));

% Convert if needed
if isa(V.Voxels, 'int16')
    V.Voxels = im2double(V.Voxels);  % IPT function
end
```

---

*Source: Medical Imaging Toolbox User's Guide, Chapter 1*
*See also: `coordinate-systems.md` for spatial transformations*
