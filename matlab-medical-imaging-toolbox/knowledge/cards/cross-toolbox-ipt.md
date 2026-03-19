# Cross-Toolbox Integration: MIT + IPT

Brief integration patterns for MIT + IPT. For detailed IPT functions, see **matlab-image-processing-toolbox** skill.

**Rule:** MIT handles I/O, spatial referencing, registration, radiomics. IPT handles filtering, thresholding, morphology, region measurements.

## Key Pitfalls

### Convert regionprops3 measurements to physical units

```matlab
V = medicalVolume('scan.nii');
mask = V.Voxels > threshold;
props = regionprops3(mask, 'Volume', 'Centroid');

% Volume is in VOXELS, not mm^3 -- always convert
voxel_volume = prod(V.VoxelSpacing);
props.VolumeWorld = props.Volume * voxel_volume;

% Centroid is in voxel indices -- convert to world coords
for i = 1:height(props)
    props.CentroidWorld(i,:) = intrinsicToWorld(V.VolumeGeometry, props.Centroid(i,:));
end
```

### Handle anisotropic voxels in 3D filters

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

### Always convert data types before IPT functions

```matlab
% WRONG: Some IPT functions fail on int16
edges = edge(V.Voxels(:,:,50), 'Canny');  % May error

% CORRECT: Convert first
slice = im2double(V.Voxels(:,:,50));
edges = edge(slice, 'Canny');
```

### Always use medicalVolume for I/O (preserves spatial info)

```matlab
% WRONG: niftiread + niftiwrite loses spatial info
data = niftiread('scan.nii');
niftiwrite(imgaussfilt3(data, 1), 'out.nii');

% CORRECT: medicalVolume preserves geometry
V = medicalVolume('scan.nii');
V.Voxels = imgaussfilt3(im2double(V.Voxels), 1);
write(V, 'out.nii');
```

---

*See: matlab-image-processing-toolbox skill for detailed IPT documentation*
