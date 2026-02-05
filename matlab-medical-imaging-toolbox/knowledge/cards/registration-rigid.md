# Rigid and Affine Registration

Registration aligns two or more images to a common coordinate frame. Rigid registration preserves distances and angles; affine registration adds scaling and shearing.

## Registration Types

| Type | DOF | Preserves | Use Case |
|------|-----|-----------|----------|
| **Rigid** | 6 | Distances, angles, shape | Same-modality, same-session |
| **Affine** | 12 | Parallelism | Different resolutions, slight deformation |
| **Similarity** | 7 | Angles (allows uniform scaling) | Brain registration |

DOF = Degrees of Freedom (parameters to estimate)

## Key Functions

| Function | Method | Best For |
|----------|--------|----------|
| `imregmoment` | Moment-based | Fast initial alignment |
| `imregicp` | Iterative Closest Point | Surface/point cloud registration |
| `imregtform` | Optimization-based | General intensity-based registration |
| `fitgeotform3d` | Landmark-based | When control points available |
| `imwarp` | Apply transformation | Transform moving image |

## imregmoment - Fast Moment-Based Registration

Computes geometric moments for rapid initial alignment:

```matlab
fixed = medicalVolume('pre_contrast.nii');
moving = medicalVolume('post_contrast.nii');

% Register (returns aligned volume and transform)
[registered, tform] = imregmoment(moving, fixed);

% Verify alignment
figure;
subplot(1,2,1);
imshowpair(extractSlice(fixed, 50, 'transverse'), ...
           extractSlice(moving, 50, 'transverse'), 'falsecolor');
title('Before');

subplot(1,2,2);
imshowpair(extractSlice(fixed, 50, 'transverse'), ...
           extractSlice(registered, 50, 'transverse'), 'falsecolor');
title('After');
```

### Options

```matlab
% Specify transformation type
[registered, tform] = imregmoment(moving, fixed, ...
    'TransformType', 'rigid');  % or 'affine'

% Use with medicalVolume objects preserves spatial info
registered = imregmoment(moving, fixed);
write(registered, 'aligned.nii');
```

## imregtform - Optimization-Based Registration

More accurate but slower than moment-based:

```matlab
fixed = medicalVolume('target.nii');
moving = medicalVolume('source.nii');

% Create optimizer and metric
[optimizer, metric] = imregconfig('monomodal');  % Same modality

% Compute transformation
tform = imregtform(moving.Voxels, moving.VolumeGeometry, ...
                   fixed.Voxels, fixed.VolumeGeometry, ...
                   'rigid', optimizer, metric);

% Apply transformation
registered = imwarp(moving.Voxels, tform, ...
    'OutputView', imref3d(size(fixed.Voxels)));
```

### Multimodal Registration

For different modalities (e.g., MRI to CT):

```matlab
% Use multimodal configuration
[optimizer, metric] = imregconfig('multimodal');

% Adjust optimizer for better convergence
optimizer.InitialRadius = 0.001;
optimizer.Epsilon = 1.5e-4;
optimizer.GrowthFactor = 1.01;
optimizer.MaximumIterations = 200;

% Register
tform = imregtform(moving.Voxels, moving.VolumeGeometry, ...
                   fixed.Voxels, fixed.VolumeGeometry, ...
                   'affine', optimizer, metric);
```

### Registration Pyramid (Multi-Resolution)

```matlab
% Start with coarse resolution, refine progressively
[optimizer, metric] = imregconfig('monomodal');

% Level 1: Coarse
optimizer.MaximumIterations = 50;
tform1 = imregtform(moving.Voxels, moving.VolumeGeometry, ...
                    fixed.Voxels, fixed.VolumeGeometry, ...
                    'rigid', optimizer, metric, ...
                    'PyramidLevels', 3);  % Use 3 resolution levels
```

## imregicp - Point Cloud Registration

For surface-based registration:

```matlab
% Extract surfaces (e.g., bone from CT)
fixed_mask = fixed.Voxels > 300;  % Bone threshold
moving_mask = moving.Voxels > 300;

% Convert to point clouds
[i, j, k] = ind2sub(size(fixed_mask), find(fixed_mask));
fixed_pts = [i(:), j(:), k(:)];
fixed_world = intrinsicToWorld(fixed.VolumeGeometry, fixed_pts);

[i, j, k] = ind2sub(size(moving_mask), find(moving_mask));
moving_pts = [i(:), j(:), k(:)];
moving_world = intrinsicToWorld(moving.VolumeGeometry, moving_pts);

% Create point clouds
ptCloud_fixed = pointCloud(fixed_world);
ptCloud_moving = pointCloud(moving_world);

% Subsample for speed
ptCloud_fixed = pcdownsample(ptCloud_fixed, 'gridAverage', 2);
ptCloud_moving = pcdownsample(ptCloud_moving, 'gridAverage', 2);

% Register
tform = imregicp(ptCloud_moving, ptCloud_fixed);

% Apply to moving volume
registered = imwarp(moving.Voxels, tform, ...
    'OutputView', imref3d(size(fixed.Voxels)));
```

## fitgeotform3d - Landmark-Based Registration

When anatomical landmarks are available:

```matlab
% Define corresponding points (in voxel or world coordinates)
% e.g., manually identified landmarks
fixed_points = [
    100, 150, 50;   % Landmark 1
    200, 180, 55;   % Landmark 2
    150, 100, 60;   % Landmark 3
    180, 200, 45    % Landmark 4
];

moving_points = [
    102, 148, 52;   % Same landmarks in moving image
    198, 182, 53;
    152, 98, 62;
    178, 202, 43
];

% Fit transformation (need at least 4 points for affine)
tform = fitgeotform3d(moving_points, fixed_points, 'affine');

% Or rigid (needs 3+ points)
tform_rigid = fitgeotform3d(moving_points, fixed_points, 'rigid');

% Apply
registered = imwarp(moving.Voxels, tform, ...
    'OutputView', imref3d(size(fixed.Voxels)));
```

## Medical Registration Estimator App

Interactive registration:

```matlab
% Launch app
medicalRegistrationEstimator

% Or with data
medicalRegistrationEstimator(fixed, moving)
```

**App Features:**
- Visual feedback during registration
- Manual pre-alignment
- Try multiple methods
- Export transformation
- Overlay visualization

## Complete Registration Workflow

### Step 1: Load and Inspect

```matlab
fixed = medicalVolume('reference.nii');
moving = medicalVolume('to_align.nii');

fprintf('Fixed: %s, Spacing: %s\n', ...
    mat2str(size(fixed.Voxels)), mat2str(fixed.VoxelSpacing));
fprintf('Moving: %s, Spacing: %s\n', ...
    mat2str(size(moving.Voxels)), mat2str(moving.VoxelSpacing));
```

### Step 2: Initial Alignment

```matlab
% Fast moment-based for rough alignment
[moving_initial, tform_initial] = imregmoment(moving, fixed);
```

### Step 3: Fine Registration

```matlab
% Optimization-based refinement
[optimizer, metric] = imregconfig('monomodal');
optimizer.MaximumIterations = 100;

tform_fine = imregtform(moving_initial.Voxels, moving_initial.VolumeGeometry, ...
                        fixed.Voxels, fixed.VolumeGeometry, ...
                        'affine', optimizer, metric);

registered = imwarp(moving_initial.Voxels, tform_fine, ...
    'OutputView', imref3d(size(fixed.Voxels)));
```

### Step 4: Verify and Save

```matlab
% Visual check
figure;
imshowpair(extractSlice(fixed, 50, 'transverse'), ...
           registered(:,:,50), 'falsecolor');
title('Registration Result (Green=Fixed, Magenta=Moving)');

% Save registered volume
V_registered = medicalVolume(registered, fixed.VolumeGeometry);
V_registered.Modality = moving.Modality;
write(V_registered, 'registered.nii');

% Save transformation for later use
save('registration_transform.mat', 'tform_initial', 'tform_fine');
```

## Combining Transformations

```matlab
% Chain multiple transforms
tform1 = affine3d(eye(4));  % Initial
tform2 = imregtform(...);   % Rigid
tform3 = imregtform(...);   % Affine refinement

% Combine (apply tform1, then tform2, then tform3)
combined = affine3d(tform3.T * tform2.T * tform1.T);

% Single warp with combined transform
registered = imwarp(moving.Voxels, combined, ...
    'OutputView', imref3d(size(fixed.Voxels)));
```

## Registration Quality Metrics

```matlab
function metrics = assessRegistration(fixed, registered)
    % Correlation coefficient
    metrics.correlation = corr2(fixed(:), registered(:));

    % Mutual information
    metrics.mi = mi(fixed, registered);

    % Sum of squared differences
    diff = double(fixed) - double(registered);
    metrics.ssd = sum(diff(:).^2);

    % Normalized cross-correlation
    metrics.ncc = normxcorr2(fixed(:,:,50), registered(:,:,50));
    metrics.ncc = max(metrics.ncc(:));

    fprintf('Correlation: %.4f\n', metrics.correlation);
    fprintf('NCC: %.4f\n', metrics.ncc);
    fprintf('SSD: %.2e\n', metrics.ssd);
end

function mi = mutualInformation(A, B)
    % Simple mutual information estimate
    joint = histcounts2(A(:), B(:), 256);
    joint = joint / sum(joint(:));
    pA = sum(joint, 2);
    pB = sum(joint, 1);
    joint(joint == 0) = eps;
    pA(pA == 0) = eps;
    pB(pB == 0) = eps;
    mi = sum(joint(:) .* log2(joint(:) ./ (pA * pB)));
end
```

## Common Issues and Solutions

### Issue: Registration fails or gives poor result

```matlab
% 1. Check data ranges
fprintf('Fixed range: [%.1f, %.1f]\n', min(fixed.Voxels(:)), max(fixed.Voxels(:)));
fprintf('Moving range: [%.1f, %.1f]\n', min(moving.Voxels(:)), max(moving.Voxels(:)));

% 2. Normalize data
fixed_norm = mat2gray(double(fixed.Voxels));
moving_norm = mat2gray(double(moving.Voxels));

% 3. Try different initial conditions
% Use moment-based for initial guess
[~, tform_init] = imregmoment(moving, fixed);
```

### Issue: Multimodal registration unstable

```matlab
% Use mutual information with careful tuning
[optimizer, metric] = imregconfig('multimodal');

% Reduce step size for stability
optimizer.InitialRadius = 0.0001;
optimizer.MaximumIterations = 300;

% More pyramid levels for robustness
tform = imregtform(moving.Voxels, moving.VolumeGeometry, ...
                   fixed.Voxels, fixed.VolumeGeometry, ...
                   'affine', optimizer, metric, ...
                   'PyramidLevels', 4);
```

### Issue: Edge artifacts after warping

```matlab
% Use appropriate interpolation and fill value
registered = imwarp(moving.Voxels, tform, ...
    'OutputView', imref3d(size(fixed.Voxels)), ...
    'Interp', 'linear', ...       % or 'cubic' for smoother
    'FillValues', min(moving.Voxels(:)));  % Fill with min value
```

---

*Source: Medical Imaging Toolbox User's Guide, Chapter 4*
*See also: `registration-deformable.md` for non-rigid registration*
