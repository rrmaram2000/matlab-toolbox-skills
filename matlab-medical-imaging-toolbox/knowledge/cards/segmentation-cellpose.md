# Cellpose for Microscopy Segmentation

Cellpose is a deep learning model for cell and nuclei segmentation in microscopy images. It excels at detecting individual cells even when touching.

## Prerequisites

```matlab
% Install support package (one-time)
% MATLAB Add-Ons > "Cellpose for MATLAB"
% Or via command:
matlab.addons.install('Cellpose for MATLAB')

% Verify installation
cellposeModels = cellposeModelList;
disp(cellposeModels);
```

## Key Functions

| Function | Purpose |
|----------|---------|
| `segmentCells2D` | Segment cells in 2D image |
| `segmentCells3D` | Segment cells in 3D volume |
| `trainCellpose` | Train custom Cellpose model |
| `refineCellpose` | Refine pretrained model |
| `cellposeModelList` | List available models |

## Pretrained Models

| Model | Best For |
|-------|----------|
| `cyto` | General cytoplasm segmentation |
| `cyto2` | Improved cytoplasm (more training data) |
| `nuclei` | Nuclei segmentation |
| `livecell` | Live cell imaging |
| `tissuenet` | Tissue microscopy |

## Basic 2D Segmentation

```matlab
% Load microscopy image
img = imread('cells.tif');

% Segment with pretrained model
L = segmentCells2D(img, 'cyto2');

% L is a label matrix: background=0, cell1=1, cell2=2, ...
numCells = max(L(:));
fprintf('Detected %d cells\n', numCells);

% Visualize
figure;
subplot(1,2,1);
imshow(img);
title('Original');

subplot(1,2,2);
imshow(label2rgb(L, 'jet', 'k', 'shuffle'));
title(sprintf('%d Cells Detected', numCells));
```

## Segmentation Options

### Specify Expected Cell Diameter

```matlab
% Diameter in pixels (critical for accuracy)
diameter = 30;  % Average cell diameter
L = segmentCells2D(img, 'cyto2', 'Diameter', diameter);

% Auto-estimate diameter
L = segmentCells2D(img, 'cyto2', 'Diameter', 0);  % 0 = auto
```

### Multi-Channel Images

```matlab
% Fluorescence with cytoplasm and nuclei channels
img_cyto = imread('cyto_channel.tif');
img_nuclei = imread('nuclei_channel.tif');

% Combine channels
img = cat(3, img_cyto, zeros(size(img_cyto)), img_nuclei);

% Segment using cyto channel
L = segmentCells2D(img, 'cyto2', ...
    'CytoplasmChannel', 1, ...   % Red channel
    'NucleiChannel', 3);          % Blue channel
```

### GPU Acceleration

```matlab
if canUseGPU()
    L = segmentCells2D(img, 'cyto2', 'UseGPU', true);
end
```

### Flow Threshold

```matlab
% Adjust to include/exclude uncertain cells
% Lower = more cells, higher = fewer (more certain)
L = segmentCells2D(img, 'cyto2', ...
    'FlowThreshold', 0.4, ...    % Default
    'CellProbabilityThreshold', 0.0);
```

## 3D Cell Segmentation

```matlab
% Load 3D microscopy stack
V = tiffreadVolume('cells_3d.tif');

% Segment in 3D
L3D = segmentCells3D(V, 'cyto2', ...
    'Diameter', 25, ...      % In voxels
    'AnisotropyRatio', 3);   % Z-resolution / XY-resolution

% Count cells
numCells = max(L3D(:));
fprintf('Detected %d cells in 3D\n', numCells);

% Visualize (labelvolshow REMOVED in R2025b)
volshow(L3D);  % or volshow(img3D, OverlayData=L3D) with context
```

## Nuclei Segmentation

```matlab
% For DAPI or Hoechst stained images
img_nuclei = imread('dapi.tif');

% Use nuclei model
L = segmentCells2D(img_nuclei, 'nuclei', 'Diameter', 15);

% Measure nuclear properties
props = regionprops(L, img_nuclei, ...
    'Area', 'Centroid', 'MeanIntensity', 'Eccentricity');

% Create table
T = struct2table(props);
fprintf('Mean nuclear area: %.1f pixels\n', mean(T.Area));
```

## Training Custom Models

### Prepare Training Data

```matlab
% Training data structure:
% - images: cell array of training images
% - labels: cell array of label matrices (same size as images)
% Label format: background=0, cell1=1, cell2=2, ...

images = cell(1, 10);
labels = cell(1, 10);

for i = 1:10
    images{i} = imread(sprintf('train/image_%03d.tif', i));
    labels{i} = imread(sprintf('train/label_%03d.tif', i));  % Instance labels
end
```

### Train Model

```matlab
% Training options
options = cellposeTrainingOptions('cyto2', ...  % Start from pretrained
    'InitialLearnRate', 0.001, ...
    'MaxEpochs', 100, ...
    'MiniBatchSize', 8, ...
    'Verbose', true);

% Train
customModel = trainCellpose(images, labels, options);

% Save model
save('my_cellpose_model.mat', 'customModel');
```

### Refine Pretrained Model

```matlab
% Fine-tune on small dataset (transfer learning)
refinedModel = refineCellpose('cyto2', images, labels, ...
    'MaxEpochs', 50);

% Use refined model
L = segmentCells2D(testImg, refinedModel);
```

## Whole Slide Image Processing

For large pathology images:

```matlab
function L = segmentWholeSlide(wsiFile, model)
    % Open whole slide image
    wsi = blockedImage(wsiFile);

    % Get dimensions at desired resolution
    level = 1;  % 0 = highest resolution
    [height, width] = size(wsi, level);

    % Process in tiles
    tileSize = [1024, 1024];
    overlap = [100, 100];  % Overlap to avoid edge artifacts

    L = zeros(height, width, 'uint16');

    maxLabel = 0;

    for row = 1:tileSize(1)-overlap(1):height-tileSize(1)+1
        for col = 1:tileSize(2)-overlap(2):width-tileSize(2)+1
            % Extract tile
            tile = getRegion(wsi, [row, col], tileSize, level);

            % Segment
            L_tile = segmentCells2D(tile, model, 'Diameter', 30);

            % Offset labels
            L_tile(L_tile > 0) = L_tile(L_tile > 0) + maxLabel;
            maxLabel = max(L_tile(:));

            % Insert (without overlap region for now)
            L(row:row+tileSize(1)-1, col:col+tileSize(2)-1) = L_tile;
        end

        fprintf('Row %d/%d complete\n', row, height);
    end
end
```

## Post-Processing Segmentation

### Remove Small/Large Cells

```matlab
L = segmentCells2D(img, 'cyto2');

% Measure areas
props = regionprops(L, 'Area', 'PixelIdxList');

% Filter by size
minArea = 100;
maxArea = 5000;

for i = 1:length(props)
    if props(i).Area < minArea || props(i).Area > maxArea
        L(props(i).PixelIdxList) = 0;
    end
end

% Relabel consecutively
L = labelmatrix(bwconncomp(L > 0));
```

### Fill Holes in Cells

```matlab
L = segmentCells2D(img, 'cyto2');

% Process each cell
for i = 1:max(L(:))
    cellMask = L == i;
    cellMask = imfill(cellMask, 'holes');
    L(cellMask) = i;
end
```

### Smooth Cell Boundaries

```matlab
L = segmentCells2D(img, 'cyto2');

L_smooth = zeros(size(L));
se = strel('disk', 3);

for i = 1:max(L(:))
    cellMask = L == i;
    cellMask = imclose(cellMask, se);
    cellMask = imopen(cellMask, se);
    L_smooth(cellMask) = i;
end
```

## Cell Measurements

```matlab
L = segmentCells2D(img, 'cyto2');

% Comprehensive measurements
props = regionprops(L, img, ...
    'Area', ...
    'Centroid', ...
    'Eccentricity', ...
    'MajorAxisLength', ...
    'MinorAxisLength', ...
    'Perimeter', ...
    'MeanIntensity', ...
    'MaxIntensity', ...
    'MinIntensity');

T = struct2table(props);
T.CellID = (1:height(T))';

% Add derived features
T.Circularity = 4 * pi * T.Area ./ (T.Perimeter.^2);
T.AspectRatio = T.MajorAxisLength ./ T.MinorAxisLength;

% Summary statistics
fprintf('Number of cells: %d\n', height(T));
fprintf('Mean area: %.1f px^2\n', mean(T.Area));
fprintf('Mean circularity: %.2f\n', mean(T.Circularity));

% Export
writetable(T, 'cell_measurements.csv');
```

## Tumor Classification Example

```matlab
% Pathology workflow: segment nuclei and classify tumor

% Load H&E stained image
img = imread('pathology_slide.tif');

% Extract hematoxylin channel (nuclei)
hed = rgb2hed(img);
nuclei_channel = hed(:,:,1);

% Segment nuclei
L = segmentCells2D(nuclei_channel, 'nuclei', 'Diameter', 12);

% Measure nuclear features (for classification)
props = regionprops(L, nuclei_channel, ...
    'Area', 'Eccentricity', 'MeanIntensity', 'Solidity');
T = struct2table(props);

% Nuclear atypia features
% - Large, irregular nuclei suggest malignancy
atypiaScore = (T.Area > median(T.Area) * 1.5) & ...
              (T.Eccentricity > 0.7) & ...
              (T.Solidity < 0.9);

percentAtypia = sum(atypiaScore) / height(T) * 100;
fprintf('Percentage of atypical nuclei: %.1f%%\n', percentAtypia);
```

## Common Issues

### Issue: Cells are merged

```matlab
% Decrease diameter estimate
L = segmentCells2D(img, 'cyto2', 'Diameter', 20);  % Smaller

% Or adjust flow threshold
L = segmentCells2D(img, 'cyto2', 'FlowThreshold', 0.3);  % More strict
```

### Issue: Cells are over-segmented

```matlab
% Increase diameter estimate
L = segmentCells2D(img, 'cyto2', 'Diameter', 50);  % Larger

% Or relax threshold
L = segmentCells2D(img, 'cyto2', 'FlowThreshold', 0.6);
```

### Issue: Missing dim cells

```matlab
% Preprocess to enhance contrast
img_enhanced = adapthisteq(img);

% Lower cell probability threshold
L = segmentCells2D(img_enhanced, 'cyto2', ...
    'CellProbabilityThreshold', -2);
```

### Issue: Out of memory on large images

```matlab
% Process in tiles
tileSize = 512;
L = zeros(size(img), 'uint16');

for i = 1:tileSize:size(img,1)
    for j = 1:tileSize:size(img,2)
        i2 = min(i+tileSize-1, size(img,1));
        j2 = min(j+tileSize-1, size(img,2));

        tile = img(i:i2, j:j2);
        L_tile = segmentCells2D(tile, 'cyto2');

        L(i:i2, j:j2) = L_tile;
    end
end

% Note: cells at tile boundaries may be split
% Consider overlap and merging for production use
```

---

*Source: Medical Imaging Toolbox User's Guide, Chapter 7*
*See also: `cross-toolbox-ipt.md` for post-processing with Image Processing Toolbox*
