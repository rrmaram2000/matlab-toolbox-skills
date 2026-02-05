# Segmentation: Thresholding

Convert grayscale images to binary masks using intensity thresholds. Foundation for most segmentation pipelines.

## Method Selection Guide

| Method | Use When | Function |
|--------|----------|----------|
| Otsu (global) | Bimodal histogram, uniform illumination | `graythresh`, `imbinarize` |
| Adaptive (local) | Uneven illumination, varying background | `adaptthresh`, `imbinarize(...,'adaptive')` |
| Multi-level | Multiple regions/classes | `multithresh`, `imquantize` |
| Manual | Known threshold, specific application | `imbinarize(I, threshold)` |

## Otsu's Method: Global Thresholding

**Mathematical Foundation:**

Otsu's method finds the threshold that minimizes intra-class variance (equivalently, maximizes inter-class variance):

```
σ²_within(t) = ω₀(t)σ₀²(t) + ω₁(t)σ₁²(t)

where:
- ω₀(t), ω₁(t) = class probabilities (pixels below/above threshold)
- σ₀²(t), σ₁²(t) = class variances
```

The optimal threshold t* minimizes σ²_within.

**Syntax:**
```matlab
level = graythresh(I)           % Returns normalized [0,1]
bw = imbinarize(I)              % Auto-applies Otsu
bw = imbinarize(I, level)       % Apply specific threshold
bw = imbinarize(I, 'global')    % Explicit Otsu
```

**Critical Note:** `graythresh` returns normalized [0,1] regardless of input type!

```matlab
% Example: Proper threshold handling
I = imread('coins.png');  % uint8 image

level = graythresh(I);    % Returns ~0.45 (normalized)
% NOT the actual pixel value (which would be ~115)

% Correct usage - imbinarize handles conversion internally
bw = imbinarize(I, level);

% If you need the actual threshold value:
threshold_uint8 = level * 255;  % For uint8
threshold_uint16 = level * 65535;  % For uint16
```

**From MathWorks Documentation (Ref p.1365):**
> "graythresh uses Otsu's method, which chooses the threshold to minimize the intraclass variance of the thresholded black and white pixels."

```matlab
% Complete Otsu example with analysis
I = imread('rice.png');
level = graythresh(I);

% Compute effectiveness metric
effectiveness = graythresh(I);  % Higher = more bimodal

% Apply threshold
bw = imbinarize(I, level);

% Verify segmentation
figure;
subplot(1,3,1); imshow(I); title('Original');
subplot(1,3,2); imhist(I); xline(level*255, 'r', 'LineWidth', 2);
title(sprintf('Histogram (thresh=%.0f)', level*255));
subplot(1,3,3); imshow(bw); title('Segmented');
```

## Adaptive Thresholding

For images with uneven illumination where global threshold fails.

**Syntax:**
```matlab
% Method 1: Using imbinarize
bw = imbinarize(I, 'adaptive')
bw = imbinarize(I, 'adaptive', 'Sensitivity', 0.4)
bw = imbinarize(I, 'adaptive', 'ForegroundPolarity', 'dark')

% Method 2: Using adaptthresh (more control)
T = adaptthresh(I, sensitivity)
T = adaptthresh(I, sensitivity, 'NeighborhoodSize', [m n])
bw = imbinarize(I, T)
```

**Key Parameters:**
- `Sensitivity`: 0 (less foreground) to 1 (more foreground), default 0.5
- `NeighborhoodSize`: Local region size, default `2*floor(size(I)/16)+1`
- `ForegroundPolarity`: `'bright'` (default) or `'dark'`
- `Statistic`: `'mean'` (default) or `'median'` or `'gaussian'`

```matlab
% Example: Document with uneven lighting
doc = imread('document_scan.png');
doc = im2double(rgb2gray(doc));

% Global threshold fails with uneven background
level = graythresh(doc);
bw_global = imbinarize(doc, level);  % Poor result

% Adaptive threshold handles uneven illumination
bw_adaptive = imbinarize(doc, 'adaptive', ...
    'Sensitivity', 0.4, ...
    'ForegroundPolarity', 'dark');  % Text is dark on light background
```

**Choosing Sensitivity:**
```matlab
% For medical images: typically 0.3-0.5
% Lower = fewer false positives, may miss faint structures
% Higher = more detection, may include noise

% Iterative approach:
sensitivities = 0.2:0.1:0.8;
for s = sensitivities
    bw = imbinarize(I, 'adaptive', 'Sensitivity', s);
    figure; imshow(bw); title(sprintf('Sensitivity = %.1f', s));
end
```

## Multi-level Thresholding

Segment image into multiple regions (e.g., background, gray matter, white matter in MRI).

**Syntax:**
```matlab
thresh = multithresh(I, n)          % Find n thresholds
seg = imquantize(I, thresh)         % Apply thresholds
seg = imquantize(I, thresh, values) % Custom output values
```

```matlab
% Example: 3-class brain tissue segmentation
mri = dicomread('brain.dcm');
mri = im2double(mri);

% Find 2 thresholds for 3 classes
thresh = multithresh(mri, 2);

% Segment into 3 regions
seg = imquantize(mri, thresh);

% Label: 1=CSF (dark), 2=gray matter (medium), 3=white matter (bright)
csf_mask = seg == 1;
gm_mask = seg == 2;
wm_mask = seg == 3;

% Visualize
rgb = label2rgb(seg, 'jet', 'k');
figure;
subplot(1,2,1); imshow(mri); title('Original MRI');
subplot(1,2,2); imshow(rgb); title('3-class segmentation');
```

**Effectiveness Metric:**
```matlab
% multithresh returns an effectiveness metric
[thresh, effectiveness] = multithresh(I, n);
% effectiveness in [0, 1]: higher = better separation
% If < 0.7, consider using different method
```

## Medical Imaging: Thresholding Pipelines

### Brain Tissue Segmentation (MRI)
```matlab
function [csf, gm, wm] = segment_brain_tissues(mri)
    % Preprocess
    mri = im2double(mri);
    mri = imgaussfilt(mri, 1);  % Light denoising

    % Create brain mask (remove skull/background)
    brain_thresh = graythresh(mri);
    brain_mask = imbinarize(mri, brain_thresh * 0.3);
    brain_mask = imfill(brain_mask, 'holes');
    brain_mask = bwareaopen(brain_mask, 1000);

    % Multi-level threshold within brain only
    brain_pixels = mri(brain_mask);
    thresh = multithresh(brain_pixels, 2);

    % Apply to full image
    seg = imquantize(mri, thresh);
    seg(~brain_mask) = 0;

    csf = (seg == 1) & brain_mask;
    gm = (seg == 2) & brain_mask;
    wm = (seg == 3) & brain_mask;
end
```

### Cell Detection (Microscopy)
```matlab
function cell_mask = segment_cells(img)
    % Convert and preprocess
    if size(img, 3) == 3
        img = rgb2gray(img);
    end
    img = im2double(img);

    % Background correction (uneven illumination common in microscopy)
    bg = imgaussfilt(img, 50);  % Large sigma for background
    corrected = img - bg;
    corrected = mat2gray(corrected);

    % Adaptive threshold (cells may have varying intensity)
    cell_mask = imbinarize(corrected, 'adaptive', ...
        'Sensitivity', 0.5, ...
        'ForegroundPolarity', 'bright');

    % Cleanup
    cell_mask = bwareaopen(cell_mask, 50);  % Remove noise
    cell_mask = imfill(cell_mask, 'holes');
end
```

### CT Bone Segmentation
```matlab
function bone_mask = segment_bone_ct(ct_hu)
    % CT in Hounsfield Units
    % Bone: typically > 300 HU

    % Simple threshold for cortical bone
    bone_mask = ct_hu > 300;

    % Include trabecular bone (150-300 HU)
    trabecular = (ct_hu > 150) & (ct_hu <= 300);

    % Combine with morphological cleanup
    bone_mask = bone_mask | trabecular;
    bone_mask = imclose(bone_mask, strel('disk', 2));
    bone_mask = bwareaopen(bone_mask, 100);
end
```

## Common Pitfalls

### 1. Threshold Output Range Confusion
```matlab
% WRONG: Treating graythresh output as pixel value
I = imread('coins.png');  % uint8
level = graythresh(I);    % Returns 0.45
bw = I > level;           % WRONG! Compares uint8 to 0.45

% CORRECT: Use imbinarize (handles automatically)
bw = imbinarize(I, level);

% OR convert threshold to appropriate range
bw = I > level * 255;
```

### 2. Wrong Foreground Polarity
```matlab
% WRONG: Default assumes bright foreground
dark_objects = imbinarize(I, 'adaptive');  % Misses dark objects

% CORRECT: Specify polarity
dark_objects = imbinarize(I, 'adaptive', 'ForegroundPolarity', 'dark');
```

### 3. Ignoring Histogram Shape
```matlab
% Check if Otsu is appropriate
figure; imhist(I);
% If NOT bimodal, Otsu will give poor results

% For non-bimodal: use adaptive or multi-level
```

### 4. Not Handling Edge Cases
```matlab
function bw = safe_threshold(I)
    % Handle constant images
    if std(I(:)) < 1e-6
        warning('Image has near-constant intensity');
        bw = false(size(I));
        return;
    end

    % Handle saturated images
    if mean(I(:) == 0 | I(:) == 1) > 0.5
        warning('Image is heavily saturated');
    end

    level = graythresh(I);
    bw = imbinarize(I, level);
end
```

## Performance Tips

1. **Preprocessing matters**: Denoise before thresholding
2. **Contrast enhancement**: `adapthisteq` before thresholding improves results
3. **Multi-level for complex scenes**: Don't force binary when 3+ classes exist
4. **Validate with histogram**: Always check histogram before choosing method

---
*Source: MathWorks IPT Reference (R2024b), pages 1365 (graythresh), 118 (imbinarize)*
