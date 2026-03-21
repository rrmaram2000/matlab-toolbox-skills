# Medical Image Coordinate Systems

**This is the most critical concept in medical imaging.** Understanding coordinate systems prevents subtle bugs that can lead to incorrect measurements, registration failures, and misaligned overlays.

## The Two Coordinate Systems

Every medical image has two coordinate systems:

| System | Also Called | Units | Origin | Use |
|--------|-------------|-------|--------|-----|
| **Intrinsic** | Voxel, Array, Image | Indices (1,2,3...) | Corner of first voxel | Array indexing, MATLAB operations |
| **Patient/World** | Physical, Scanner | mm (usually) | DICOM-defined point | Clinical measurements, registration |

## Visual Representation

```
INTRINSIC (Voxel) Coordinates          PATIENT (World) Coordinates

   i=1  i=2  i=3  ...                     x (mm)
  +----+----+----+                       +---->
j=1| 1,1| 1,2| 1,3|                      |
  +----+----+----+               y (mm)  |    Actual physical
j=2| 2,1| 2,2| 2,3|                      v    positions in
  +----+----+----+                            patient space
j=3| 3,1| 3,2| 3,3|
  ...                                    Origin defined by
                                         ImagePositionPatient
Origin: corner of voxel (1,1,1)          in DICOM
```

## Key Functions

| Function | Purpose | Direction |
|----------|---------|-----------|
| `intrinsicToWorld` | Convert voxel indices to mm | Intrinsic → Patient |
| `worldToIntrinsic` | Convert mm to continuous voxel coords | Patient → Intrinsic |
| `worldToSubscript` | Convert mm to integer voxel indices | Patient → Intrinsic (rounded) |

## medicalref3d - The Spatial Reference Object

`medicalref3d` stores the transformation between coordinate systems:

```matlab
% Create from parameters
R = medicalref3d(volumeSize, voxelSpacing, origin);

% Example: 256×256×128 volume, 1×1×2mm spacing, origin at (0,0,0)
R = medicalref3d([256, 256, 128], [1, 1, 2], [0, 0, 0]);

% Access from medicalVolume
V = medicalVolume('scan.nii');
R = V.VolumeGeometry;

% Key properties
disp(R.VolumeSize);           % [256, 256, 128]
disp(R.Position);             % Nx3: Patient position of each slice
disp(R.VoxelDistances);       % Cell array of voxel spacing
disp(R.PatientCoordinateSystem);  % 'LPS+', 'RAS+', etc.
```

## Coordinate Conversion Examples

### Intrinsic to World

```matlab
V = medicalVolume('scan.nii');
R = V.VolumeGeometry;

% Single point
voxel = [100, 150, 50];  % (i, j, k)
world = intrinsicToWorld(R, voxel);
fprintf('Voxel [%d,%d,%d] is at [%.1f, %.1f, %.1f] mm\n', ...
    voxel, world);

% Multiple points
voxels = [100, 150, 50;
          200, 200, 60;
          50,  100, 40];
worlds = intrinsicToWorld(R, voxels);
```

### World to Intrinsic

```matlab
% Get continuous coordinates (can be fractional)
world_point = [50.5, 75.3, -20.1];  % mm
intrinsic = worldToIntrinsic(R, world_point);
% intrinsic might be [100.5, 150.3, 49.7]

% Get integer indices for array access
[i, j, k] = worldToSubscript(R, world_point);
% i, j, k are rounded to nearest valid indices

% Access voxel at that location
value = V.Voxels(i, j, k);
```

## Patient Orientation Conventions

Medical images use anatomical orientation systems:

### LPS+ (DICOM standard)
- **L**eft: +X points to patient's left
- **P**osterior: +Y points to patient's back
- **S**uperior: +Z points to patient's head

### RAS+ (NIfTI/FSL/FreeSurfer)
- **R**ight: +X points to patient's right
- **A**nterior: +Y points to patient's front
- **S**uperior: +Z points to patient's head

```matlab
V = medicalVolume('scan.nii');
R = V.VolumeGeometry;

% Check coordinate system
fprintf('Coordinate System: %s\n', R.PatientCoordinateSystem);

% DataDimensionMeaning tells you what each array dimension represents
fprintf('Dimension meanings: %s\n', strjoin(V.DataDimensionMeaning, ', '));
% e.g., "left, posterior, superior"
```

## Slice Orientation

The `Orientation` property indicates how slices are acquired:

| Orientation | Slices Perpendicular To | View |
|-------------|------------------------|------|
| transverse | Superior-Inferior (head-foot) | Axial, looking down |
| coronal | Anterior-Posterior (front-back) | Front view |
| sagittal | Left-Right | Side view |

```matlab
V = medicalVolume('scan.nii');

fprintf('Orientation: %s\n', V.Orientation);
fprintf('Normal Vector: [%.3f, %.3f, %.3f]\n', V.NormalVector);
fprintf('Plane Mapping: %s\n', strjoin(V.PlaneMapping, ', '));

% PlaneMapping shows which array dimension corresponds to which plane
% e.g., ["sagittal", "coronal", "transverse"]
% means dim 1 = sagittal slices, dim 2 = coronal, dim 3 = transverse
```

## Common Pitfalls

### Pitfall 1: Mixing Coordinate Systems

```matlab
% WRONG: Treating voxel indices as mm
V = medicalVolume('scan.nii');
tumor_center = [150, 200, 50];  % Are these voxels or mm?
radius = 20;  % Is this voxels or mm?
% Ambiguous and error-prone!

% CORRECT: Be explicit about coordinate system
tumor_center_voxel = [150, 200, 50];  % Intrinsic
tumor_center_mm = intrinsicToWorld(V.VolumeGeometry, tumor_center_voxel);
radius_mm = 20;  % Physical measurement

% Or work entirely in world coordinates
tumor_center_mm = [50.5, 30.2, -15.0];  % From clinical report
radius_mm = 20;
```

### Pitfall 2: Ignoring Anisotropic Voxels

```matlab
V = medicalVolume('scan.nii');
spacing = V.VoxelSpacing;  % e.g., [0.5, 0.5, 3.0] mm

% WRONG: Assuming isotropic for distance calculation
voxel_distance = norm([10, 10, 10]);  % 17.3 "voxels"

% CORRECT: Convert to mm using spacing
physical_distance = norm([10, 10, 10] .* spacing);  % 30.4 mm
% The Z distance dominates because of 3mm slice thickness!
```

### Pitfall 3: Array Dimension Order

```matlab
% MATLAB arrays are (row, column) = (Y, X) for 2D
% For 3D: (Y, X, Z) or (row, col, slice)

V = medicalVolume('scan.nii');
% V.Voxels is organized as (dim1, dim2, dim3)
% The meaning depends on acquisition!

% Check what each dimension means:
disp(V.PlaneMapping);  % e.g., ["sagittal", "coronal", "transverse"]
disp(V.DataDimensionMeaning);  % e.g., ["left", "posterior", "superior"]

% Use extractSlice to avoid confusion:
transverse_slice = extractSlice(V, 50, 'transverse');  % Always correct
```

### Pitfall 4: Origin Confusion

```matlab
% DICOM origin (ImagePositionPatient) is center of first voxel
% Some software uses corner of first voxel

V = medicalVolume('scan.dcm');
R = V.VolumeGeometry;

% First voxel position in world coordinates
first_voxel_world = intrinsicToWorld(R, [1, 1, 1]);
% This gives the CENTER of voxel (1,1,1)

% For half-voxel offset to corner:
corner_world = intrinsicToWorld(R, [0.5, 0.5, 0.5]);
```

## Practical Workflows

### Measure Distance Between Two Points

```matlab
function dist_mm = measureDistance(V, point1_voxel, point2_voxel)
    % Convert to world coordinates
    R = V.VolumeGeometry;
    world1 = intrinsicToWorld(R, point1_voxel);
    world2 = intrinsicToWorld(R, point2_voxel);

    % Euclidean distance in mm
    dist_mm = norm(world2 - world1);
end

% Usage
V = medicalVolume('scan.nii');
d = measureDistance(V, [100, 100, 50], [150, 120, 55]);
fprintf('Distance: %.2f mm\n', d);
```

### Create Spherical ROI at World Coordinate

```matlab
function mask = createSphereROI(V, center_mm, radius_mm)
    R = V.VolumeGeometry;
    [ni, nj, nk] = size(V.Voxels);
    mask = false(ni, nj, nk);

    for i = 1:ni
        for j = 1:nj
            for k = 1:nk
                % Convert voxel to world
                world = intrinsicToWorld(R, [i, j, k]);

                % Check if inside sphere
                if norm(world - center_mm) <= radius_mm
                    mask(i, j, k) = true;
                end
            end
        end
    end
end

% Usage: 20mm sphere at (50, 30, -20) mm
mask = createSphereROI(V, [50, 30, -20], 20);
```

### Align Two Volumes to Same Coordinate Frame

```matlab
% Load volumes
V1 = medicalVolume('scan1.nii');  % Reference
V2 = medicalVolume('scan2.nii');  % Moving

% Check if they share the same world coordinates
fprintf('V1 origin: %s\n', mat2str(intrinsicToWorld(V1.VolumeGeometry, [1,1,1])));
fprintf('V2 origin: %s\n', mat2str(intrinsicToWorld(V2.VolumeGeometry, [1,1,1])));

% If different, need registration (see registration-rigid.md)
% Or resample V2 to V1's geometry:
V2_aligned = resample(V2, V1.VoxelSpacing);
```

### Extract Coordinates of Segmented Region

```matlab
V = medicalVolume('scan.nii');
mask = medicalVolume('segmentation.nii');

% Find all voxels in segmentation
[i, j, k] = ind2sub(size(mask.Voxels), find(mask.Voxels > 0));

% Convert to world coordinates
voxel_coords = [i(:), j(:), k(:)];
world_coords = intrinsicToWorld(V.VolumeGeometry, voxel_coords);

% Compute centroid in world coordinates
centroid_mm = mean(world_coords, 1);
fprintf('Centroid: [%.2f, %.2f, %.2f] mm\n', centroid_mm);

% Compute bounding box in world coordinates
min_world = min(world_coords, [], 1);
max_world = max(world_coords, [], 1);
fprintf('Bounding box: [%.1f, %.1f, %.1f] to [%.1f, %.1f, %.1f] mm\n', ...
    min_world, max_world);
```

## Debugging Coordinate Issues

```matlab
function debugCoordinates(V)
    R = V.VolumeGeometry;

    fprintf('=== Coordinate System Debug ===\n');
    fprintf('Volume Size: %s\n', mat2str(size(V.Voxels)));
    fprintf('Voxel Spacing: %s mm\n', mat2str(V.VoxelSpacing));
    fprintf('Spatial Units: %s\n', V.SpatialUnits);
    fprintf('Orientation: %s\n', V.Orientation);
    fprintf('Patient Coord System: %s\n', R.PatientCoordinateSystem);
    fprintf('Plane Mapping: %s\n', strjoin(V.PlaneMapping, ', '));

    % Check corners
    corners = [1, 1, 1;
               size(V.Voxels, 1), 1, 1;
               1, size(V.Voxels, 2), 1;
               1, 1, size(V.Voxels, 3);
               size(V.Voxels)];

    fprintf('\nCorner positions (mm):\n');
    for c = 1:size(corners, 1)
        world = intrinsicToWorld(R, corners(c,:));
        fprintf('  Voxel %s -> World %s\n', ...
            mat2str(corners(c,:)), mat2str(world, 3));
    end

    % Physical extent
    corner1_world = intrinsicToWorld(R, [1, 1, 1]);
    cornerN_world = intrinsicToWorld(R, size(V.Voxels));
    extent = abs(cornerN_world - corner1_world);
    fprintf('\nPhysical Extent: %.1f x %.1f x %.1f mm\n', extent);
end
```

---

*Verified against MATLAB R2025b*
*This is the CRITICAL card - read before any medical imaging work*
