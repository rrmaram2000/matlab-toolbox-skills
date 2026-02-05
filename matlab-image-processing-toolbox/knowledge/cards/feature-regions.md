# Feature Extraction: Region Properties

Measure properties of connected regions in binary or labeled images. Essential for quantitative image analysis.

## Core Functions

| Function | Purpose | Output |
|----------|---------|--------|
| `bwconncomp` | Find connected components | Struct with pixel indices |
| `bwlabel` | Label connected regions | Label matrix |
| `regionprops` | Measure region properties | Struct or table |
| `bwboundaries` | Extract region boundaries | Cell array of coordinates |

## Connected Components: `bwconncomp`

Find connected regions efficiently. Preferred over `bwlabel` for large images.

**From MathWorks Documentation (Ref p.511):**
> "bwconncomp finds connected components in binary images. It returns the number of connected components and a PixelIdxList containing the linear indices of the pixels in each component."

```matlab
cc = bwconncomp(bw)           % 8-connectivity (default)
cc = bwconncomp(bw, conn)     % Specify connectivity (4 or 8)

% Output structure:
% cc.Connectivity  - 4 or 8
% cc.ImageSize     - [rows cols]
% cc.NumObjects    - Number of regions
% cc.PixelIdxList  - Cell array of linear indices
```

```matlab
% Example: Count and access objects
bw = imread('coins.png') > 100;
cc = bwconncomp(bw);

fprintf('Found %d objects\n', cc.NumObjects);

% Access pixels of first object
first_object_pixels = cc.PixelIdxList{1};
[rows, cols] = ind2sub(cc.ImageSize, first_object_pixels);
```

## Label Matrix: `bwlabel`

Create label matrix where each connected region has unique integer.

**From MathWorks Documentation (Ref p.501):**
> "bwlabel labels connected components in a 2-D binary image. Each connected component has a unique label."

```matlab
[L, num] = bwlabel(bw)        % 8-connectivity (default)
[L, num] = bwlabel(bw, conn)  % Specify connectivity (4 or 8)

% L(i,j) = label of region at pixel (i,j), 0 for background
% num = total number of regions
```

```matlab
% Example: Visualize labeled regions
bw = imread('text.png') > 128;
[L, num] = bwlabel(bw);

% Display with colors
rgb = label2rgb(L, 'jet', 'k', 'shuffle');
imshow(rgb);
title(sprintf('%d regions found', num));
```

**`bwconncomp` vs `bwlabel`:**
- `bwconncomp`: Memory efficient, returns indices
- `bwlabel`: Returns full label matrix, easier visualization
- For large images with many objects, use `bwconncomp`

## Region Properties: `regionprops`

**The workhorse function for region measurement.**

**Syntax:**
```matlab
stats = regionprops(bw, properties)           % From binary image
stats = regionprops(L, properties)            % From label matrix
stats = regionprops(cc, properties)           % From bwconncomp output
stats = regionprops('table', ...)             % Return as table (recommended)
stats = regionprops(..., I, properties)       % Include grayscale image for intensity props
```

### Property Categories

**Shape Properties (no grayscale image needed):**
```matlab
stats = regionprops('table', bw, ...
    'Area', ...              % Number of pixels
    'Centroid', ...          % [x, y] center of mass
    'BoundingBox', ...       % [x, y, width, height]
    'Perimeter', ...         % Boundary length
    'Eccentricity', ...      % 0 (circle) to 1 (line)
    'Circularity', ...       % 4π×Area/Perimeter² (1 = circle)
    'EquivDiameter', ...     % Diameter of circle with same area
    'Solidity', ...          % Area / ConvexArea
    'Extent', ...            % Area / BoundingBox area
    'Orientation', ...       % Angle of major axis (-90 to 90)
    'MajorAxisLength', ...   % Length of major axis
    'MinorAxisLength', ...   % Length of minor axis
    'ConvexHull', ...        % Convex hull vertices
    'ConvexArea', ...        % Area of convex hull
    'FilledArea', ...        % Area with holes filled
    'EulerNumber', ...       % Objects - holes
    'Extrema', ...           % 8 extreme points
    'PixelIdxList', ...      % Linear indices of pixels
    'PixelList');            % [x, y] coordinates
```

**Intensity Properties (require grayscale image I):**
```matlab
stats = regionprops('table', bw, I, ...
    'MeanIntensity', ...     % Mean of pixel intensities
    'MinIntensity', ...      % Minimum intensity
    'MaxIntensity', ...      % Maximum intensity
    'WeightedCentroid', ...  % Intensity-weighted center
    'PixelValues');          % All pixel intensities
```

### Practical Examples

**Cell Counting and Measurement:**
```matlab
% Load and segment
cells = imread('cells.tif');
cells = im2double(rgb2gray(cells));
bw = imbinarize(cells, 'adaptive');
bw = bwareaopen(bw, 50);
bw = imfill(bw, 'holes');

% Measure all properties at once
stats = regionprops('table', bw, cells, ...
    'Area', 'Centroid', 'Eccentricity', ...
    'MeanIntensity', 'Perimeter', 'Circularity');

% Filter by criteria
valid_cells = stats.Area > 100 & stats.Area < 5000 & ...
              stats.Eccentricity < 0.8;
cell_stats = stats(valid_cells, :);

fprintf('Found %d valid cells\n', height(cell_stats));
fprintf('Mean area: %.1f pixels\n', mean(cell_stats.Area));
fprintf('Mean circularity: %.2f\n', mean(cell_stats.Circularity));
```

**Locate and Mark Centroids:**
```matlab
stats = regionprops('table', bw, 'Centroid', 'Area');

% Display with markers
imshow(I);
hold on;
for k = 1:height(stats)
    plot(stats.Centroid(k,1), stats.Centroid(k,2), 'r+', 'MarkerSize', 10);
    text(stats.Centroid(k,1)+5, stats.Centroid(k,2), ...
         sprintf('%d', stats.Area(k)), 'Color', 'yellow');
end
hold off;
```

**Filter by Shape:**
```matlab
% Find circular objects (cells, not debris)
stats = regionprops('table', bw, 'Area', 'Circularity', 'Eccentricity');

% Circularity close to 1 = circular
circular_mask = stats.Circularity > 0.7;
circular_objects = stats(circular_mask, :);

% Eccentricity close to 0 = circular
round_mask = stats.Eccentricity < 0.5;
round_objects = stats(round_mask, :);
```

## Boundary Extraction: `bwboundaries`

Extract boundary coordinates of regions.

```matlab
B = bwboundaries(bw)                   % Cell array of boundaries
B = bwboundaries(bw, conn)             % Specify connectivity
B = bwboundaries(bw, conn, 'noholes')  % Exclude holes
[B, L] = bwboundaries(bw)              % Also return label matrix
```

```matlab
% Example: Plot all boundaries
bw = imread('circles.png') > 128;
B = bwboundaries(bw);

imshow(bw);
hold on;
for k = 1:length(B)
    boundary = B{k};
    plot(boundary(:,2), boundary(:,1), 'g', 'LineWidth', 2);
end
hold off;
```

## Medical Imaging Applications

### Tumor Measurement
```matlab
function tumor_stats = analyze_tumor(tumor_mask, ct_image)
    % Ensure single connected region
    tumor_mask = bwareafilt(tumor_mask, 1);  % Keep largest

    % Comprehensive measurements
    stats = regionprops('table', tumor_mask, ct_image, ...
        'Area', 'Perimeter', 'Centroid', ...
        'MajorAxisLength', 'MinorAxisLength', ...
        'Eccentricity', 'Solidity', ...
        'MeanIntensity', 'MaxIntensity', 'MinIntensity');

    % Convert to physical units (assume 1mm pixel spacing)
    pixel_spacing = 1;  % mm/pixel
    tumor_stats.Area_mm2 = stats.Area * pixel_spacing^2;
    tumor_stats.Perimeter_mm = stats.Perimeter * pixel_spacing;
    tumor_stats.MajorAxis_mm = stats.MajorAxisLength * pixel_spacing;
    tumor_stats.MinorAxis_mm = stats.MinorAxisLength * pixel_spacing;

    % Estimated volume (for 2D slice)
    tumor_stats.Diameter_mm = stats.EquivDiameter * pixel_spacing;

    % Shape descriptors
    tumor_stats.Roundness = stats.Circularity;
    tumor_stats.Irregularity = 1 - stats.Solidity;

    % Intensity features (important for tumor characterization)
    tumor_stats.HU_mean = stats.MeanIntensity;
    tumor_stats.HU_max = stats.MaxIntensity;
    tumor_stats.HU_min = stats.MinIntensity;
end
```

### Cell Population Analysis
```matlab
function [summary, individual] = analyze_cell_population(cell_mask, fluorescence)
    % Get individual cell measurements
    stats = regionprops('table', cell_mask, fluorescence, ...
        'Area', 'Eccentricity', 'MeanIntensity', 'Centroid');

    % Filter valid cells
    valid = stats.Area > 50 & stats.Area < 2000;
    individual = stats(valid, :);

    % Population statistics
    summary.cell_count = height(individual);
    summary.mean_area = mean(individual.Area);
    summary.std_area = std(individual.Area);
    summary.mean_intensity = mean(individual.MeanIntensity);
    summary.std_intensity = std(individual.MeanIntensity);

    % Classification by shape
    summary.round_cells = sum(individual.Eccentricity < 0.5);
    summary.elongated_cells = sum(individual.Eccentricity > 0.7);
end
```

## Common Pitfalls

### 1. Wrong Property Syntax
```matlab
% WRONG: Properties as separate strings
stats = regionprops(bw, 'Area', 'Centroid');  % Works but...

% BETTER: Use cell array for clarity
stats = regionprops(bw, {'Area', 'Centroid'});

% BEST: Use 'table' output for easier manipulation
stats = regionprops('table', bw, 'Area', 'Centroid');
```

### 2. Centroid Coordinate Order
```matlab
% Centroid is [x, y], NOT [row, col]!
stats = regionprops('table', bw, 'Centroid');
centroid = stats.Centroid(1, :);  % [x, y]

% For matrix indexing:
row = round(centroid(2));  % y → row
col = round(centroid(1));  % x → col
pixel_value = I(row, col);
```

### 3. Missing Grayscale Image for Intensity Properties
```matlab
% WRONG: Asking for MeanIntensity without grayscale image
stats = regionprops(bw, 'MeanIntensity');  % Error!

% CORRECT: Provide grayscale image
stats = regionprops(bw, I, 'MeanIntensity');
```

### 4. Table vs Struct Output
```matlab
% Struct output (default) - harder to work with
stats_struct = regionprops(bw, 'Area');
areas = [stats_struct.Area];  % Need to extract

% Table output (recommended) - vectorized operations
stats_table = regionprops('table', bw, 'Area');
areas = stats_table.Area;  % Already a vector
filtered = stats_table(stats_table.Area > 100, :);  % Easy filtering
```

## Property Reference Table

| Property | Type | Description | Requires I |
|----------|------|-------------|------------|
| Area | Scalar | Pixel count | No |
| Centroid | 1×2 | [x, y] center | No |
| BoundingBox | 1×4 | [x, y, w, h] | No |
| Perimeter | Scalar | Boundary length | No |
| Eccentricity | Scalar | 0-1 (circle-line) | No |
| Circularity | Scalar | 4πA/P² | No |
| Solidity | Scalar | Area/ConvexArea | No |
| MeanIntensity | Scalar | Mean of pixels | Yes |
| MinIntensity | Scalar | Minimum | Yes |
| MaxIntensity | Scalar | Maximum | Yes |
| WeightedCentroid | 1×2 | Intensity-weighted | Yes |
| PixelIdxList | Vector | Linear indices | No |
| PixelList | N×2 | [x, y] coordinates | No |

---
*Source: MathWorks IPT Reference (R2024b), pages 29 (regionprops), 501 (bwlabel), 511 (bwconncomp)*
