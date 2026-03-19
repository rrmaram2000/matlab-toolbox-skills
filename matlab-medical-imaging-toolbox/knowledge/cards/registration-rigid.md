# Rigid and Affine Registration

Gotchas and advanced patterns for medical image registration. For basic `imregmoment` and `imregtform` usage, see SKILL.md.

## Multimodal Registration

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

### PyramidLevels for Robustness

```matlab
% Use multiple resolution levels for better convergence
tform = imregtform(moving.Voxels, moving.VolumeGeometry, ...
                   fixed.Voxels, fixed.VolumeGeometry, ...
                   'affine', optimizer, metric, ...
                   'PyramidLevels', 4);
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
