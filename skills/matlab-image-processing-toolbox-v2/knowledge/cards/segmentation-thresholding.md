# Segmentation: Medical Thresholding Patterns

The model knows basic Otsu/adaptive/multi-level thresholding well. This card focuses on medical-specific tissue segmentation pipelines and the patterns that require domain knowledge.

## Multi-Level Tissue Segmentation (MRI)

The key pattern: threshold within a masked ROI, not the whole image.

```matlab
function [csf, gm, wm] = segment_brain_tissues(mri)
    mri = im2double(mri);
    mri = imgaussfilt(mri, 1);  % Light denoising

    % Create brain mask FIRST (remove skull/background)
    brain_thresh = graythresh(mri);
    brain_mask = imbinarize(mri, brain_thresh * 0.3);
    brain_mask = imfill(brain_mask, 'holes');
    brain_mask = bwareaopen(brain_mask, 1000);

    % Multi-level threshold within brain ONLY
    % (whole-image multithresh fails because background dominates)
    brain_pixels = mri(brain_mask);
    [thresh, em] = multithresh(brain_pixels, 2);

    % Check effectiveness — if < 0.7, consider different method
    fprintf('Threshold effectiveness: %.2f\n', em);

    seg = imquantize(mri, thresh);
    seg(~brain_mask) = 0;

    csf = (seg == 1) & brain_mask;
    gm = (seg == 2) & brain_mask;
    wm = (seg == 3) & brain_mask;
end
```

## CT Bone Segmentation (Hounsfield Units)

```matlab
function bone_mask = segment_bone_ct(ct_hu)
    % CT in Hounsfield Units — use domain-specific thresholds
    % Cortical bone: > 300 HU
    % Trabecular bone: 150-300 HU
    bone_mask = ct_hu > 150;
    bone_mask = imclose(bone_mask, strel('disk', 2));
    bone_mask = bwareaopen(bone_mask, 100);
end
```

## Adaptive Thresholding for Microscopy

Background correction BEFORE thresholding is essential for microscopy:

```matlab
function cell_mask = segment_cells(img)
    if size(img, 3) == 3, img = rgb2gray(img); end
    img = im2double(img);

    % Background correction (uneven illumination)
    bg = imgaussfilt(img, 50);
    corrected = mat2gray(img - bg);

    % Adaptive threshold after correction
    cell_mask = imbinarize(corrected, 'adaptive', ...
        'Sensitivity', 0.5, ...
        'ForegroundPolarity', 'bright');

    cell_mask = bwareaopen(cell_mask, 50);
    cell_mask = imfill(cell_mask, 'holes');
end
```

## Medical-Specific Gotchas

### Sensitivity Range for Medical Images
- Medical images: typically sensitivity 0.3-0.5
- Lower = fewer false positives, may miss faint structures
- Higher = more detection, may include noise

### Always Check Histogram Shape Before Using Otsu
If the histogram is NOT bimodal (common in medical images with heterogeneous tissue), Otsu gives poor results. Use `multithresh` or adaptive methods instead.

### Foreground Polarity Matters
```matlab
% Brightfield microscopy: cells are DARK on light background
bw = imbinarize(I, 'adaptive', 'ForegroundPolarity', 'dark');

% Fluorescence: objects are BRIGHT on dark background (default)
bw = imbinarize(I, 'adaptive', 'ForegroundPolarity', 'bright');
```

---
*Source: MathWorks IPT Reference (R2025a)*
