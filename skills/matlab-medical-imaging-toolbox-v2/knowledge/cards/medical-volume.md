# The medicalVolume Class

Specialized patterns and properties for `medicalVolume`. For basic creation (`medicalVolume('file.nii')`) and common usage, see SKILL.md.

## Creating from Existing Data

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

## Specialized Patterns

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

*Verified against MATLAB R2025b*
*See also: `coordinate-systems.md` for spatial transformations*
