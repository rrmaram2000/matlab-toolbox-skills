# Medical Imaging Toolbox Skill - Test Results

**Test Date:** 2026-02-04
**Skill:** matlab-medical-imaging-toolbox
**Platform:** Claude Desktop with skill toggle

---

## Test 1: MedSAM Tumor Segmentation

**Question:**
```
How do I use MedSAM to segment a tumor from a CT volume in MATLAB?
```

### Without Skill

Claude believes MedSAM is Python-only and requires a complex bridge:

```matlab
%% Load CT volume
vol = niftiread('your_ct.nii.gz');
info = niftiinfo('your_ct.nii.gz');

% Select slice of interest (or loop over slices for 3D)
sliceIdx = 45;
slice2D = vol(:,:,sliceIdx);

% Normalize to [0, 255] uint8 (MedSAM expects this)
slice2D = double(slice2D);
slice2D = uint8(255 * mat2gray(slice2D));

% Convert grayscale to 3-channel (MedSAM expects RGB-like input)
sliceRGB = repmat(slice2D, [1, 1, 3]);

% Define bounding box prompt [x_min, y_min, x_max, y_max]
bbox = [120, 150, 200, 230];

% Save temporary files for Python bridge
imwrite(sliceRGB, 'temp_slice.png');
save('temp_bbox.mat', 'bbox');
```

Then requires a separate Python script (`run_medsam.py`) with 50+ lines of PyTorch code to run inference, followed by loading results back into MATLAB.

**Problems:**
- Requires Python installation and PyTorch
- Complex inter-process communication via temp files
- 100+ total lines of code
- No knowledge of native MATLAB API

### With Skill

Claude knows MATLAB has native MedSAM support:

```matlab
%% 1. Setup
model = medicalSegmentAnythingModel('ExecutionEnvironment', 'gpu');
V = medicalVolume('ct_scan.nii');

%% 2. Identify seed slice (where tumor is most visible)
sliceViewer(V);
seed_idx = 45;

%% 3. Segment seed slice
slice = mat2gray(double(extractSlice(V, seed_idx, 'transverse')));
embeddings = extractEmbeddings(model, slice);

% Bounding box prompt
bbox = [120, 90, 80, 70];
mask = segmentObjectsFromEmbeddings(model, embeddings, ...
    'BoundingBox', bbox);

%% 4. Propagate to 3D
volume_mask = false(size(V.Voxels));
volume_mask(:,:,seed_idx) = mask;

for k = seed_idx+1:V.NumTransverseSlices
    prev_mask = volume_mask(:,:,k-1);
    if ~any(prev_mask(:)), break; end

    props = regionprops(prev_mask, 'Centroid', 'BoundingBox');
    slice_k = mat2gray(double(extractSlice(V, k, 'transverse')));
    emb_k = extractEmbeddings(model, slice_k);

    volume_mask(:,:,k) = segmentObjectsFromEmbeddings(model, emb_k, ...
        'ForegroundPoints', props(1).Centroid);
end

%% 5. Post-process
volume_mask = imopen(volume_mask, strel('sphere', 2));
volume_mask = imfill(volume_mask, 'holes');
volume_mask = bwareaopen(volume_mask, 500);

%% 6. Save with spatial referencing
V_seg = medicalVolume(uint8(volume_mask), V.VolumeGeometry);
write(V_seg, 'tumor_segmentation.nii');

%% 7. Visualize
volshow(V, 'OverlayData', V_seg);
```

### Comparison Summary

| Aspect | Without Skill | With Skill |
|--------|---------------|------------|
| Approach | Python bridge required | **Native MATLAB** |
| Code complexity | 100+ lines (Python + MATLAB) | **~40 lines pure MATLAB** |
| Key function | Doesn't know it exists | `medicalSegmentAnythingModel` |
| Workflow | Temp files, subprocess calls | `extractEmbeddings` → `segmentObjectsFromEmbeddings` |
| 3D handling | "Loop over slices" (vague) | **Full propagation strategy** |
| Spatial referencing | Lost | **Preserved with medicalVolume** |

**Verdict:** Dramatic improvement. The skill transforms a complex multi-language workflow into clean native MATLAB code.

---

## Test 2: 3D Volume Visualization with Overlay

**Question:**
```
How do I visualize a 3D medical volume with a segmentation overlay in MATLAB?
```

### Without Skill

Claude provides complex workarounds without knowing the modern API:

```matlab
% Overlay using labeloverlay (slice-by-slice into RGB stack)
rgb = zeros([size(vol), 3]);
for k = 1:size(vol, 3)
    rgb(:,:,k,:) = labeloverlay(volNorm(:,:,k), seg(:,:,k), ...
        'Colormap', [1 0 0], 'Transparency', 0.6);
end

% View with Volume Viewer (interactive)
volumeViewer(volNorm);

% For segmentation overlay — create isosurface:
figure;
p = patch(isosurface(seg, 0.5));
p.FaceColor = [1 0.2 0.2];
p.FaceAlpha = 0.3;
p.EdgeColor = 'none';
hold on;
slice(double(volNorm), round(size(vol,2)/2), round(size(vol,1)/2), round(size(vol,3)/2));
shading interp; colormap gray;
```

Also suggests contour-based overlays on individual slices.

**Problems:**
- Slice-by-slice loop for 3D overlay
- Uses isosurface as workaround
- Doesn't know about `OverlayData` parameter
- No knowledge that `labelvolshow` was removed

### With Skill

Claude knows the clean modern syntax:

```matlab
V = medicalVolume('ct_scan.nii');
L = medicalVolume('segmentation.nii');

volshow(V, OverlayData=L.Voxels);
```

With custom colors and transparency:

```matlab
labelColors = [
    0,   0,   0;      % 0: background
    0.2, 0.8, 0.3;    % 1: liver (green)
    1.0, 0.2, 0.2     % 2: tumor (red)
];

labelAlpha = [0, 0.3, 0.5];

volshow(V, OverlayData=L.Voxels, ...
    OverlayColormap=labelColors, ...
    OverlayAlphamap=labelAlpha, ...
    BackgroundColor='black');
```

Also notes:
- `labelvolshow` was **REMOVED in R2025b**
- Pass full `medicalVolume` object to preserve voxel spacing
- Overlay must be integer label array with same dimensions

### Comparison Summary

| Aspect | Without Skill | With Skill |
|--------|---------------|------------|
| Approach | Workarounds (isosurface, loops) | **`OverlayData` parameter** |
| Code | 30+ lines | **3 lines** |
| Key syntax | Doesn't know it | `volshow(V, OverlayData=L.Voxels)` |
| labelvolshow | Not mentioned | **Notes REMOVED in R2025b** |
| Colormap control | Not shown | `OverlayColormap`, `OverlayAlphamap` |
| Spatial referencing | Manual | **Preserved via medicalVolume** |

**Verdict:** Clear improvement. Simple 3-line solution vs. complex workarounds.

---

## Overall Assessment

The Medical Imaging Toolbox skill demonstrates **dramatic improvements** for:
1. Modern APIs (MedSAM, volshow OverlayData)
2. R2024b+ features Claude doesn't know
3. Removed functions (labelvolshow)
4. Proper spatial referencing workflows

These examples are suitable for the public README.
