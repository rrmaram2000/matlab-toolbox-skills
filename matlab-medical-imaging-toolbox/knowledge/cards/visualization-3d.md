# 3D Visualization

This card covers rendering and browsing 3D medical image volumes using Medical Imaging Toolbox visualization functions.

## Key Functions

| Function | Purpose | Best For |
|----------|---------|----------|
| `volshow` | 3D volume rendering | Quick 3D view, patient coordinates |
| `sliceViewer` | Orthogonal slice browser | Slice-by-slice inspection |
| `labelvolshow` | Labeled volume display | Segmentation overlays |
| `montage` | 2D slice grid | Overview of all slices |
| `implay` | Video playback | 2D time series (ultrasound) |

## volshow - 3D Volume Rendering

### Basic Usage

```matlab
V = medicalVolume('ct_scan.nii');

% Simple display (uses patient coordinates automatically)
volshow(V);

% Or with voxel array and geometry
volshow(V.Voxels, V.VolumeGeometry);
```

### Rendering Options

```matlab
V = medicalVolume('ct_scan.nii');

% Create viewer with options
viewer = volshow(V, ...
    'Colormap', hot(256), ...
    'Alphamap', linspace(0, 1, 256), ...
    'BackgroundColor', [0.1 0.1 0.1], ...
    'CameraPosition', [2, -3, 1], ...
    'CameraTarget', [0, 0, 0]);

% Interactive: rotate, zoom with mouse
```

### Rendering Styles

```matlab
V = medicalVolume('ct_scan.nii');

% Maximum Intensity Projection (MIP)
viewer = volshow(V, 'RenderingStyle', 'MaximumIntensityProjection');

% Isosurface rendering
viewer = volshow(V, 'RenderingStyle', 'Isosurface', 'IsosurfaceValue', 0.5);

% Gradient opacity (shows edges)
viewer = volshow(V, 'RenderingStyle', 'GradientOpacity');
```

### Customizing Transfer Functions

```matlab
V = medicalVolume('ct_scan.nii');

% Normalize data for colormap
data = double(V.Voxels);
data = (data - min(data(:))) / (max(data(:)) - min(data(:)));

% Custom alphamap (transparency)
% Low values transparent, high values opaque
alpha = linspace(0, 0.8, 256);

% Custom colormap
cmap = parula(256);

volshow(data, V.VolumeGeometry, ...
    'Colormap', cmap, ...
    'Alphamap', alpha);
```

### CT Bone Rendering Example

```matlab
V = medicalVolume('ct_chest.nii');

% Hounsfield units: bone > 300 HU
data = double(V.Voxels);

% Create alphamap that shows bone
% HU range roughly -1000 to +3000
normalized = (data + 1000) / 4000;  % Map to 0-1

% Alpha: transparent below 300 HU, opaque above
hu_values = linspace(-1000, 3000, 256);
alpha = zeros(1, 256);
alpha(hu_values > 300) = 0.8;

volshow(normalized, V.VolumeGeometry, ...
    'Alphamap', alpha, ...
    'Colormap', bone(256));
```

## sliceViewer - Orthogonal Slice Browser

### Basic Usage

```matlab
V = medicalVolume('brain_mri.nii');

% Open slice viewer (interactive)
sliceViewer(V);

% With voxel array
sliceViewer(V.Voxels);
```

### With Custom Display Range

```matlab
V = medicalVolume('ct_scan.nii');

% Set display range (e.g., soft tissue window)
sliceViewer(V, 'DisplayRange', [-100, 300]);

% Or use window center/width
center = 40;
width = 400;
sliceViewer(V, 'DisplayRange', [center - width/2, center + width/2]);
```

### Slice Viewer Features

- Click and drag to browse slices
- Scroll to change slice
- Window/level adjustment (right-click drag on some versions)
- Orthogonal views (axial, coronal, sagittal)
- Measurements and annotations

```matlab
% Programmatic control
V = medicalVolume('scan.nii');
sv = sliceViewer(V);

% Get current slice numbers
disp(sv.SliceNumbers);

% Set specific slices
sv.SliceNumbers = [100, 150, 50];  % [transverse, coronal, sagittal]
```

## labelvolshow - Segmentation Overlay

> ⚠️ **REMOVED in R2025b:** `labelvolshow` has been removed. Use `volshow(V, OverlayData=labels)` instead.

### Modern Replacement (R2025b+)

```matlab
V_image = medicalVolume('ct_scan.nii');
V_labels = medicalVolume('segmentation.nii');

% Use volshow with OverlayData (replaces labelvolshow)
volshow(V_image.Voxels, OverlayData=V_labels.Voxels);
```

### Legacy Syntax (R2024b and earlier)

```matlab
V_image = medicalVolume('ct_scan.nii');
V_labels = medicalVolume('segmentation.nii');

% Display labels on image (REMOVED in R2025b)
labelvolshow(V_labels.Voxels, V_image.Voxels);
```

### Custom Label Colors (R2025b+)

```matlab
V_image = medicalVolume('brain.nii');
V_labels = medicalVolume('brain_seg.nii');

% Define label colors
% Labels: 0=background, 1=CSF, 2=gray matter, 3=white matter
labelColors = [
    0, 0, 0;        % 0: background (transparent)
    0.2, 0.6, 1.0;  % 1: CSF (blue)
    0.8, 0.4, 0.4;  % 2: gray matter (red)
    1.0, 1.0, 0.8   % 3: white matter (cream)
];

% Modern syntax using volshow with OverlayData
volshow(V_image.Voxels, OverlayData=V_labels.Voxels, ...
    OverlayColormap=labelColors, ...
    OverlayAlphamap=[0, 0.3, 0.3, 0.3], ...
    BackgroundColor='black');
```

### Multi-Label Visualization (R2025b+)

```matlab
V = medicalVolume('ct_scan.nii');
L = medicalVolume('multi_organ_seg.nii');

% Unique labels
labels = unique(L.Voxels(:));
labels = labels(labels > 0);  % Exclude background

fprintf('Labels found: %s\n', mat2str(labels'));

% Create colormap for labels
numLabels = max(labels);
cmap = lines(numLabels);  % Distinct colors

% Modern syntax using volshow with OverlayData
volshow(V.Voxels, OverlayData=L.Voxels, ...
    OverlayColormap=cmap, OverlayAlphamap=0.5);
```

## montage - 2D Slice Overview

### Basic Montage

```matlab
V = medicalVolume('scan.nii');

% Show all slices
figure;
montage(V.Voxels, 'DisplayRange', []);

% Specific slices
montage(V.Voxels, 'Indices', 1:5:size(V.Voxels, 3));  % Every 5th slice
```

### Custom Layout

```matlab
V = medicalVolume('scan.nii');

% Grid layout
figure;
montage(V.Voxels, ...
    'Size', [4 8], ...       % 4 rows, 8 columns
    'DisplayRange', [], ...
    'BackgroundColor', 'black');

% Add title
title('Volume Overview');
```

### Montage of Orthogonal Views

```matlab
V = medicalVolume('scan.nii');

% Extract representative slices
midT = extractSlice(V, round(V.NumTransverseSlices/2), 'transverse');
midC = extractSlice(V, round(V.NumCoronalSlices/2), 'coronal');
midS = extractSlice(V, round(V.NumSagittalSlices/2), 'sagittal');

% Combine in figure
figure;
subplot(1,3,1); imshow(midT, []); title('Transverse');
subplot(1,3,2); imshow(midC, []); title('Coronal');
subplot(1,3,3); imshow(midS, []); title('Sagittal');
sgtitle('Orthogonal Views');
```

## Multimodal Overlay (PET/CT)

```matlab
% Load CT and PET
V_ct = medicalVolume('ct.nii');
V_pet = medicalVolume('pet.nii');

% Ensure same geometry (may need registration first)
% See registration-rigid.md

% Resample PET to CT space if needed
V_pet_aligned = resample(V_pet, V_ct.VoxelSpacing);

% Create fused display
figure;

% CT as grayscale background
ct_norm = mat2gray(double(V_ct.Voxels));

% PET as hot colormap overlay
pet_norm = mat2gray(double(V_pet_aligned.Voxels));

% Display middle transverse slice
slice_idx = round(V_ct.NumTransverseSlices / 2);
ct_slice = ct_norm(:,:,slice_idx);
pet_slice = pet_norm(:,:,slice_idx);

% Show CT
imshow(ct_slice, []);
hold on;

% Overlay PET with transparency
pet_rgb = ind2rgb(gray2ind(pet_slice, 256), hot(256));
h = imshow(pet_rgb);
h.AlphaData = pet_slice * 0.6;  % Opacity proportional to PET intensity
hold off;
title('PET/CT Fusion');
```

## Medical Image Labeler App

Interactive labeling and visualization:

```matlab
% Launch app
medicalImageLabeler

% Or open with specific data
medicalImageLabeler(medicalVolume('scan.nii'))
```

**App Features:**
- Draw ROIs in 2D slices
- 3D visualization of labels
- Semi-automatic labeling tools
- MONAI Label integration
- Export ground truth for training

## Common Visualization Patterns

### Quick Volume Inspection

```matlab
function quickView(filename)
    V = medicalVolume(filename);

    figure('Position', [100 100 1200 400]);

    % Slice viewer
    subplot(1,3,1:2);
    sliceViewer(V);
    title('Slice Browser');

    % 3D render
    subplot(1,3,3);
    volshow(V);
    title('3D View');

    sgtitle(sprintf('%s (%s)', filename, V.Modality));
end
```

### Compare Before/After Processing

```matlab
function compareVolumes(V_before, V_after, slice_num)
    figure('Position', [100 100 1000 400]);

    slice1 = extractSlice(V_before, slice_num, 'transverse');
    slice2 = extractSlice(V_after, slice_num, 'transverse');

    subplot(1,2,1);
    imshow(slice1, []);
    title('Before');

    subplot(1,2,2);
    imshow(slice2, []);
    title('After');

    % Link axes for synchronized zoom/pan
    linkaxes(findall(gcf, 'Type', 'axes'));
end
```

### Create Animation Through Slices

```matlab
function animateSlices(V, filename)
    figure('Position', [100 100 512 512]);

    for k = 1:V.NumTransverseSlices
        slice = extractSlice(V, k, 'transverse');
        imshow(slice, []);
        title(sprintf('Slice %d/%d', k, V.NumTransverseSlices));

        if exist('filename', 'var')
            frame = getframe(gcf);
            if k == 1
                imwrite(frame.cdata, filename, 'gif', 'LoopCount', Inf);
            else
                imwrite(frame.cdata, filename, 'gif', 'WriteMode', 'append');
            end
        else
            pause(0.05);
        end
    end
end
```

### STL Export for 3D Printing

```matlab
V = medicalVolume('ct_scan.nii');

% Threshold to get bone surface
bone_mask = V.Voxels > 300;  % HU threshold for bone

% Clean up mask (using IPT - see cross-toolbox-ipt.md)
bone_mask = imopen(bone_mask, strel('sphere', 2));
bone_mask = imfill(bone_mask, 'holes');

% Generate isosurface
fv = isosurface(bone_mask, 0.5);

% Convert to world coordinates
% (vertices are in voxel indices, need mm for printing)
for i = 1:size(fv.vertices, 1)
    voxel = fv.vertices(i, :);
    world = intrinsicToWorld(V.VolumeGeometry, voxel);
    fv.vertices(i, :) = world;
end

% Write STL
stlwrite('bone_model.stl', fv);
```

## Troubleshooting

### Issue: Volume appears distorted

**Cause:** Anisotropic voxels not accounted for.

```matlab
% Check voxel spacing
V = medicalVolume('scan.nii');
disp(V.VoxelSpacing);  % e.g., [0.5, 0.5, 3.0]

% volshow with medicalVolume handles this automatically
volshow(V);  % Correct

% If using raw array, specify geometry
volshow(V.Voxels);  % May appear distorted
volshow(V.Voxels, V.VolumeGeometry);  % Correct
```

### Issue: Display range wrong

**Cause:** Auto-scaling to wrong range.

```matlab
V = medicalVolume('ct_scan.nii');

% Check data range
fprintf('Min: %.1f, Max: %.1f\n', min(V.Voxels(:)), max(V.Voxels(:)));

% Set explicit range
sliceViewer(V, 'DisplayRange', [-1000, 3000]);  % Full CT range
sliceViewer(V, 'DisplayRange', [-100, 200]);    % Soft tissue window
```

### Issue: labelvolshow crashes on large labels

**Cause:** Too many unique label values.

```matlab
L = medicalVolume('labels.nii');
unique_labels = unique(L.Voxels(:));
fprintf('Unique labels: %d\n', length(unique_labels));

% If too many, downsample or threshold
L.Voxels(L.Voxels > 100) = 0;  % Keep only first 100 labels
```

---

*Source: Medical Imaging Toolbox User's Guide, Chapter 3*
*See also: `labeling-workflow.md` for Medical Image Labeler app*
