# Deformable (Non-Rigid) Registration

Gotchas and advanced patterns for deformable registration. For basic `imregdeform` usage, see SKILL.md.

## GridSpacing Tuning (Critical)

`GridSpacing` controls the smoothness-vs-accuracy tradeoff:

```matlab
% Soft tissue with large deformation: finer grid
[D, registered] = imregdeform(moving.Voxels, fixed.Voxels, ...
    'GridSpacing', [2 2 2]);

% Subtle changes: coarser grid (more regularization)
[D, registered] = imregdeform(moving.Voxels, fixed.Voxels, ...
    'GridSpacing', [8 8 8]);

% Multimodal: use mutual information
[D, registered] = imregdeform(moving.Voxels, fixed.Voxels, ...
    'SimilarityMetric', 'mattesMutualInformation', ...
    'GridSpacing', [4 4 4], 'NumIterations', 150);
```

## Displacement Field Analysis

### Visualizing Displacement

```matlab
[D, registered] = imregdeform(moving.Voxels, fixed.Voxels);

% Displacement magnitude
D_magnitude = sqrt(D(:,:,:,1).^2 + D(:,:,:,2).^2 + D(:,:,:,3).^2);

% Visualize on middle slice
figure;
slice_idx = round(size(D_magnitude, 3) / 2);

subplot(1,2,1);
imagesc(D_magnitude(:,:,slice_idx));
colorbar;
title('Displacement Magnitude (voxels)');

subplot(1,2,2);
% Quiver plot of displacement vectors
[X, Y] = meshgrid(1:size(D,2), 1:size(D,1));
skip = 5;  % Show every 5th vector
quiver(X(1:skip:end, 1:skip:end), Y(1:skip:end, 1:skip:end), ...
       D(1:skip:end, 1:skip:end, slice_idx, 1), ...
       D(1:skip:end, 1:skip:end, slice_idx, 2));
axis equal;
title('Displacement Vectors');
```

### Convert Displacement to Physical Units

```matlab
% Displacements are in voxel units
% Convert to mm using spacing
spacing = fixed.VoxelSpacing;

D_mm = D;
D_mm(:,:,:,1) = D(:,:,:,1) * spacing(1);
D_mm(:,:,:,2) = D(:,:,:,2) * spacing(2);
D_mm(:,:,:,3) = D(:,:,:,3) * spacing(3);

D_magnitude_mm = sqrt(D_mm(:,:,:,1).^2 + D_mm(:,:,:,2).^2 + D_mm(:,:,:,3).^2);

fprintf('Max displacement: %.2f mm\n', max(D_magnitude_mm(:)));
fprintf('Mean displacement: %.2f mm\n', mean(D_magnitude_mm(:)));
```

### Jacobian Analysis (Volume Change)

```matlab
function jacobian = computeJacobian(D)
    % Jacobian determinant indicates local volume change
    % J > 1: expansion
    % J < 1: contraction
    % J = 1: no volume change
    % J < 0: folding (invalid transformation)

    [Dx_x, Dx_y, Dx_z] = gradient(D(:,:,:,1));
    [Dy_x, Dy_y, Dy_z] = gradient(D(:,:,:,2));
    [Dz_x, Dz_y, Dz_z] = gradient(D(:,:,:,3));

    % Deformation gradient tensor
    % F = I + grad(D)
    jacobian = (1 + Dx_x) .* ((1 + Dy_y) .* (1 + Dz_z) - Dy_z .* Dz_y) ...
             - Dx_y .* (Dy_x .* (1 + Dz_z) - Dy_z .* Dz_x) ...
             + Dx_z .* (Dy_x .* Dz_y - (1 + Dy_y) .* Dz_x);
end

J = computeJacobian(D);
fprintf('Jacobian range: [%.3f, %.3f]\n', min(J(:)), max(J(:)));

if min(J(:)) < 0
    warning('Negative Jacobian detected - folding in transformation');
end
```

## imreggroupwise - Multi-Image Registration

For registering a series of images to a common template:

```matlab
% Load time series or multi-subject data
volumes = cell(1, 10);
for i = 1:10
    volumes{i} = medicalVolume(sprintf('subject%02d.nii', i));
end

% Stack into 4D array
data = cat(4, volumes{:});

% Groupwise registration
[registered, tforms] = imreggroupwise(data);

% registered is the aligned series
% tforms contains transformations for each volume
```

### Groupwise Options

```matlab
% Control registration behavior
[registered, tforms] = imreggroupwise(data, ...
    'TransformationType', 'nonrigid', ...  % or 'rigid', 'affine'
    'GridSpacing', [4 4 4], ...
    'NumIterations', 50);
```

## Lung Motion Estimation Example

Classic deformable registration application:

```matlab
% Load inhale and exhale CT scans
inhale = medicalVolume('ct_inhale.nii');
exhale = medicalVolume('ct_exhale.nii');

% Deformable registration (inhale -> exhale)
[D, registered] = imregdeform(inhale.Voxels, exhale.Voxels, ...
    'GridSpacing', [3 3 3], ...      % Fine grid for lung motion
    'NumIterations', 150, ...
    'SimilarityMetric', 'ssd');

% Analyze diaphragm motion
D_mm = D;
D_mm(:,:,:,3) = D(:,:,:,3) * inhale.VoxelSpacing(3);  % Z displacement in mm

% Find max motion (typically at diaphragm)
[maxMotion, maxIdx] = max(abs(D_mm(:,:,:,3)), [], 'all', 'linear');
[i, j, k] = ind2sub(size(exhale.Voxels), maxIdx);
fprintf('Max diaphragm motion: %.1f mm at voxel [%d, %d, %d]\n', ...
    maxMotion, i, j, k);

% Visualize motion
figure;
imagesc(squeeze(D_mm(:, round(end/2), :, 3))');
colorbar;
title('Superior-Inferior Displacement (mm)');
xlabel('Voxel X'); ylabel('Voxel Z');
```

## Apply Saved Displacement Field

```matlab
% Save displacement field
save('displacement.mat', 'D');

% Later: load and apply to other data
load('displacement.mat', 'D');

% Apply to labels (use nearest neighbor to preserve label values)
labels = medicalVolume('labels.nii');
labels_warped = imwarp(labels.Voxels, D, 'nearest');

% Apply to another volume
other = medicalVolume('other_modality.nii');
other_warped = imwarp(other.Voxels, D, 'linear');
```

## Combining Rigid and Deformable

Best practice: rigid first, then deformable

```matlab
function [D_total, registered] = hierarchicalRegistration(moving, fixed)
    % Step 1: Rigid alignment
    [moving_rigid, tform_rigid] = imregmoment(moving, fixed);

    % Step 2: Affine refinement
    [optimizer, metric] = imregconfig('monomodal');
    tform_affine = imregtform(moving_rigid.Voxels, moving_rigid.VolumeGeometry, ...
                              fixed.Voxels, fixed.VolumeGeometry, ...
                              'affine', optimizer, metric);
    moving_affine = imwarp(moving_rigid.Voxels, tform_affine, ...
                           'OutputView', imref3d(size(fixed.Voxels)));

    % Step 3: Deformable registration
    [D, registered] = imregdeform(moving_affine, fixed.Voxels, ...
                                   'GridSpacing', [4 4 4], ...
                                   'NumIterations', 100);

    % Store combined displacement
    D_total = D;

    fprintf('Hierarchical registration complete\n');
end
```

## Inverse Displacement Field

```matlab
% Sometimes need to warp in opposite direction
% Approximate inverse by negating displacement field

% Better: compute inverse using optimization
function D_inv = invertDisplacement(D)
    sz = size(D);
    D_inv = zeros(sz);

    % Initial guess: negative displacement
    D_inv = -D;

    % Refine with fixed-point iteration (simplified)
    for iter = 1:10
        % Forward warp of identity plus inverse should give identity
        for c = 1:3
            D_inv(:,:,:,c) = -interp3(D(:,:,:,c), ...
                1:sz(2), (1:sz(1))', 1:sz(3), 'linear', 0);
        end
    end
end
```

## Common Issues and Solutions

### Issue: Registration takes too long

```matlab
% Reduce resolution
moving_down = imresize3(moving.Voxels, 0.5, 'linear');
fixed_down = imresize3(fixed.Voxels, 0.5, 'linear');

% Register at low resolution
[D_low, ~] = imregdeform(moving_down, fixed_down, 'GridSpacing', [4 4 4]);

% Upsample displacement field
D = imresize3(D_low, size(fixed.Voxels)./size(fixed_down), 'linear') * 2;

% Apply to full resolution
registered = imwarp(moving.Voxels, D, 'linear');
```

### Issue: Folding in displacement field

```matlab
% Increase regularization (larger grid spacing)
[D, registered] = imregdeform(moving.Voxels, fixed.Voxels, ...
    'GridSpacing', [8 8 8]);  % More regularization

% Check Jacobian
J = computeJacobian(D);
if any(J(:) < 0)
    warning('Increase GridSpacing to prevent folding');
end
```

### Issue: Poor alignment in specific region

```matlab
% Use region of interest
mask = fixed.Voxels > threshold;  % Focus region

% Weight similarity by mask (if supported)
% Or pre-align globally, then locally within ROI
```

---

*Source: Medical Imaging Toolbox User's Guide, Chapter 4*
*See also: `registration-rigid.md` for rigid/affine registration*
