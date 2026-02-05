# Dual-Tree Complex Wavelet Transform

## Why Dual-Tree?

Standard DWT limitations:
- **Shift variance**: Small shifts cause large coefficient changes
- **Poor directional selectivity**: Only H, V, D orientations
- **Oscillating coefficients**: Ringing near edges

Dual-tree CWT solves these with:
- **Near shift-invariance**: 2x redundancy
- **6 orientations per scale**: ±15°, ±45°, ±75°
- **Smooth magnitude response**: Better for texture/edge analysis

## Basic Usage

```matlab
% Forward transform
[a, d] = dualtree2(img, Level=4);
% a: approximation coefficients (cell array)
% d: detail coefficients (cell array per level)
%    d{level} is H x W x 6 (6 orientations)

% Inverse transform
imgRec = idualtree2(a, d);
```

## Accessing Directional Subbands

```matlab
[a, d] = dualtree2(img, Level=3);

% d{level}(:,:,direction) where direction is:
% 1: +15° (near-horizontal, slightly up)
% 2: -15° (near-horizontal, slightly down)
% 3: +45° (diagonal, up-right)
% 4: -45° (diagonal, down-right)
% 5: +75° (near-vertical, slightly right)
% 6: -75° (near-vertical, slightly left)

% Example: extract 45° diagonal at level 2
diag45 = abs(d{2}(:,:,3));
```

## Edge Detection by Orientation

```matlab
[a, d] = dualtree2(img, Level=3);

% Compute edge magnitude at each orientation
edgeMaps = cell(1, 6);
for dir = 1:6
    % Sum across scales for this orientation
    edgeMaps{dir} = zeros(size(img));
    for lev = 1:3
        coeffs = abs(d{lev}(:,:,dir));
        edgeMaps{dir} = edgeMaps{dir} + ...
            imresize(coeffs, size(img));
    end
end

% Dominant orientation at each pixel
[~, dominantDir] = max(cat(3, edgeMaps{:}), [], 3);
```

## Selective Enhancement

```matlab
% Enhance horizontal edges (directions 1, 2)
[a, d] = dualtree2(img, Level=3);

for lev = 1:3
    d{lev}(:,:,1) = d{lev}(:,:,1) * 1.5;  % +15°
    d{lev}(:,:,2) = d{lev}(:,:,2) * 1.5;  % -15°
end

enhanced = idualtree2(a, d);
```

## Directional Denoising

```matlab
[a, d] = dualtree2(noisyImg, Level=4);

for lev = 1:4
    for dir = 1:6
        coeffs = d{lev}(:,:,dir);
        sigma = median(abs(coeffs(:))) / 0.6745;
        thr = sigma * sqrt(2 * log(numel(coeffs)));
        d{lev}(:,:,dir) = wthresh(coeffs, 's', thr);
    end
end

denoised = idualtree2(a, d);
```

## Comparison with Standard DWT

| Property | DWT | Dual-Tree |
|----------|-----|-----------|
| Shift invariance | No | Near |
| Orientations | 3 (H,V,D) | 6 per scale |
| Redundancy | None | 4x (2D) |
| Speed | Fast | ~4x slower |
| Use case | Compression | Analysis/enhancement |

## When to Use Dual-Tree

**Good for:**
- Texture analysis (oriented patterns)
- Edge detection (multiple orientations)
- Feature extraction (rotation-sensitive)
- Denoising with edge preservation

**Not ideal for:**
- Compression (redundancy)
- Speed-critical applications
- Simple smooth images
