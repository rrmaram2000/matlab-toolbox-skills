# Morphology: Binary Operations

Mathematical morphology for processing binary masks. Foundation for cleaning segmentation results and shape analysis.

## Core Concepts

**Structuring Element (SE):** A small binary image that defines the neighborhood for morphological operations. The SE "probes" the image.

**Fundamental Operations:**
- **Erosion**: Shrinks objects, removes small protrusions
- **Dilation**: Expands objects, fills small holes
- **Opening**: Erosion → Dilation (removes noise, preserves size)
- **Closing**: Dilation → Erosion (fills gaps, preserves size)

## Structuring Elements: `strel`

**From MathWorks Documentation (Ref p.556):**
> "A structuring element is a small matrix of zeros and ones that specifies the pixels to be used in a morphological operation."

**Syntax:**
```matlab
se = strel('disk', radius)          % Disk (most common)
se = strel('disk', radius, n)       % n-approximation (0,4,6,8)
se = strel('square', width)         % Square
se = strel('rectangle', [m n])      % Rectangle
se = strel('diamond', radius)       % Diamond
se = strel('line', len, deg)        % Line at angle
se = strel('octagon', radius)       % Octagon
se = strel('arbitrary', nhood)      % Custom shape
```

**SE Sizing Rule:**
```
SE radius ≈ (feature size to affect) / 2
```

```matlab
% Example: Remove noise blobs ~10 pixels diameter
noise_diameter = 10;
se = strel('disk', round(noise_diameter / 2));  % radius = 5

% Example: Fill gaps up to ~6 pixels
gap_size = 6;
se = strel('disk', round(gap_size / 2));  % radius = 3
```

**Visualizing SEs:**
```matlab
se = strel('disk', 5);
figure; imagesc(se.Neighborhood); axis equal;
title('Disk SE, radius=5');
colormap(gray);
```

## Erosion: `imerode`

Shrinks foreground objects. A pixel is set to 1 only if ALL pixels under the SE are 1.

**From MathWorks Documentation (Ref p.555):**
> "For binary images, erosion is equivalent to taking the minimum over all pixels in the neighborhood."

```matlab
eroded = imerode(bw, se)
```

**Effects:**
- Removes thin protrusions
- Separates narrowly connected objects
- Shrinks all objects by SE radius
- Removes objects smaller than SE

```matlab
% Example: Separate touching cells
bw = imread('touching_cells.png');
se = strel('disk', 3);
separated = imerode(bw, se);
```

## Dilation: `imdilate`

Expands foreground objects. A pixel is set to 1 if ANY pixel under the SE is 1.

**From MathWorks Documentation (Ref p.580):**
> "For binary images, dilation is equivalent to taking the maximum over all pixels in the neighborhood."

```matlab
dilated = imdilate(bw, se)
```

**Effects:**
- Fills small holes and gaps
- Connects nearby objects
- Expands all objects by SE radius
- Smooths boundaries

```matlab
% Example: Connect broken edges
edges = edge(I, 'Canny');
se = strel('disk', 2);
connected_edges = imdilate(edges, se);
```

## Opening: `imopen`

Erosion followed by dilation. Removes small objects without changing size of large objects.

**From MathWorks Documentation (Ref p.1623):**
> "Opening smooths the contour of an object, breaks narrow isthmuses, and eliminates thin protrusions."

```matlab
opened = imopen(bw, se)
% Equivalent to: imdilate(imerode(bw, se), se)
```

**Use Cases:**
- Remove noise (small bright spots)
- Separate objects connected by thin bridges
- Smooth object boundaries

```matlab
% Example: Remove noise from cell mask
cell_mask = imbinarize(cells);
se = strel('disk', 3);
clean_mask = imopen(cell_mask, se);

% Objects smaller than SE will be removed
% Large objects remain approximately same size
```

## Closing: `imclose`

Dilation followed by erosion. Fills small holes without changing size of large objects.

**From MathWorks Documentation (Ref p.1619):**
> "Closing smooths the contour of an object, fuses narrow breaks and long thin gulfs, and eliminates small holes."

```matlab
closed = imclose(bw, se)
% Equivalent to: imerode(imdilate(bw, se), se)
```

**Use Cases:**
- Fill small holes
- Connect nearby objects
- Close narrow gaps in boundaries

```matlab
% Example: Fill holes in cell nuclei
nuclei_mask = imbinarize(nuclei);
se = strel('disk', 5);
filled_nuclei = imclose(nuclei_mask, se);
```

## Additional Operations

### Fill Holes: `imfill`
```matlab
filled = imfill(bw, 'holes')              % Fill all holes
filled = imfill(bw, locations)            % Fill from seed points
filled = imfill(bw, locations, conn)      % Specify connectivity
```

### Remove Small Objects: `bwareaopen`
```matlab
cleaned = bwareaopen(bw, minArea)         % Remove objects < minArea pixels
cleaned = bwareaopen(bw, minArea, conn)   % Specify connectivity (4 or 8)
```

### Thin/Skeletonize: `bwmorph`
```matlab
thinned = bwmorph(bw, 'thin', Inf)        % Thin to 1-pixel lines
skeleton = bwmorph(bw, 'skel', Inf)       % Skeletonize
endpoints = bwmorph(skeleton, 'endpoints') % Find endpoints
branches = bwmorph(skeleton, 'branchpoints') % Find branch points
```

### Distance Transform: `bwdist`
```matlab
D = bwdist(bw)                            % Euclidean distance to nearest 0
D = bwdist(bw, 'cityblock')               % L1 distance
D = bwdist(bw, 'chessboard')              % L∞ distance
```

## Standard Cleanup Pipeline

```matlab
function bw_clean = morphological_cleanup(bw, min_area, se_radius)
    % Standard morphological cleanup pipeline

    if nargin < 2, min_area = 50; end
    if nargin < 3, se_radius = 3; end

    se = strel('disk', se_radius);

    % 1. Opening: remove small protrusions and noise
    bw_clean = imopen(bw, se);

    % 2. Closing: fill small gaps and holes
    bw_clean = imclose(bw_clean, se);

    % 3. Fill remaining holes
    bw_clean = imfill(bw_clean, 'holes');

    % 4. Remove small objects
    bw_clean = bwareaopen(bw_clean, min_area);
end
```

## Medical Imaging Applications

### Cell Segmentation Cleanup
```matlab
function cells = segment_and_clean_cells(img)
    % Threshold
    bw = imbinarize(im2double(img), 'adaptive');

    % Morphological cleanup
    se_small = strel('disk', 2);
    se_large = strel('disk', 5);

    % Remove noise (small bright spots)
    bw = imopen(bw, se_small);

    % Fill holes in cells
    bw = imclose(bw, se_large);
    bw = imfill(bw, 'holes');

    % Remove debris (< 100 pixels)
    cells = bwareaopen(bw, 100);
end
```

### Vessel Segmentation Enhancement
```matlab
function vessels = enhance_vessels(bw_vessels)
    % Connect broken vessel segments
    se_connect = strel('disk', 2);
    vessels = imdilate(bw_vessels, se_connect);

    % Remove noise
    vessels = bwareaopen(vessels, 50);

    % Thin to centerlines if needed
    centerlines = bwmorph(vessels, 'thin', Inf);
end
```

### Bone Mask Refinement
```matlab
function bone = refine_bone_mask(bw_bone)
    % Fill internal holes (trabecular bone)
    bone = imfill(bw_bone, 'holes');

    % Smooth boundaries
    se = strel('disk', 3);
    bone = imclose(bone, se);
    bone = imopen(bone, se);

    % Remove isolated small fragments
    bone = bwareaopen(bone, 200);
end
```

## Common Pitfalls

### 1. SE Too Large
```matlab
% WRONG: SE larger than features removes them
small_cells = ...;  % Cells ~20 pixels diameter
se = strel('disk', 15);  % Radius > cell radius
gone = imopen(small_cells, se);  % Cells disappear!

% CORRECT: SE radius < smallest feature / 2
se = strel('disk', 5);  % Radius < 20/2 = 10
preserved = imopen(small_cells, se);
```

### 2. Wrong Operation Order
```matlab
% WRONG: Close then open (fills then removes - may not help)
bw1 = imopen(imclose(bw, se), se);

% Usually BETTER: Open then close (remove noise, then fill)
bw2 = imclose(imopen(bw, se), se);
```

### 3. Forgetting Connectivity
```matlab
% Different results with 4 vs 8 connectivity
cc4 = bwconncomp(bw, 4);  % Only edge-adjacent
cc8 = bwconncomp(bw, 8);  % Also diagonal-adjacent

% Use 8 for more "connected" interpretation (default)
% Use 4 for stricter connectivity
```

### 4. Operating on Wrong Type
```matlab
% WRONG: Morphology on grayscale when binary intended
gray_result = imopen(I, se);  % Grayscale morphology!

% CORRECT: Binarize first
bw = imbinarize(I);
binary_result = imopen(bw, se);  % Binary morphology
```

## Operation Selection Guide

| Goal | Operation | SE Size |
|------|-----------|---------|
| Remove small noise | `imopen` | Radius = noise_size / 2 |
| Fill small holes | `imclose` | Radius = hole_size / 2 |
| Fill all holes | `imfill(...,'holes')` | N/A |
| Remove small objects | `bwareaopen` | min_area in pixels |
| Separate touching objects | `imerode` or watershed | Radius = neck_width / 2 |
| Connect nearby objects | `imdilate` | Radius = gap_size / 2 |
| Smooth boundaries | `imopen` then `imclose` | Small radius (2-5) |
| Extract skeleton | `bwmorph(...,'skel')` | N/A |

---
*Source: MathWorks IPT Reference (R2024b), pages 555-556 (imerode, strel), 580 (imdilate), 1619-1623 (imclose, imopen)*
