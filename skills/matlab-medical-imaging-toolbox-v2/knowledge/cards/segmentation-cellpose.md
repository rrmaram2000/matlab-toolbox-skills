# Cell & Nuclei Segmentation in Microscopy

Strategies for segmenting individual cells in microscopy images. Covers watershed-based instance segmentation, deep learning approaches, and MedSAM interactive segmentation.

> **Note:** R2025b includes `segmentCells2D(cp, im)` which requires a `cellpose` object and the "Medical Imaging Toolbox Interface for Cellpose Library" add-on. If the add-on is not installed, use the watershed or MedSAM approaches below, or Python integration via `pyrunfile`.

## Strategy Overview

| Approach | Best For | Functions |
|----------|----------|-----------|
| Watershed | Well-separated cells, fluorescence | `watershed`, `bwdist`, `regionprops` |
| MedSAM | Interactive ROI segmentation | `medicalSegmentAnythingModel` |
| U-Net | Large annotated datasets | `unet`, `trainnet`, `semanticseg` |
| Python Cellpose | State-of-art instance segmentation | `pyrunfile`, `py.cellpose` |

## Watershed-Based Instance Segmentation

Best for fluorescence microscopy with distinguishable cells.

```matlab
% Load and preprocess
img = imread('cells.tif');
imgGray = im2single(im2gray(img));
imgEnhanced = adapthisteq(imgGray, 'NumTiles', [8 8], 'ClipLimit', 0.02);

% Background subtraction for uneven illumination
bgEst = imopen(imgEnhanced, strel('disk', 50));
imgCorr = mat2gray(imgEnhanced - bgEst);

% Adaptive thresholding
T = adaptthresh(imgCorr, 0.5, 'NeighborhoodSize', 51);
bw = imbinarize(imgCorr, T);

% Cleanup
bw = imfill(bw, 'holes');
bw = bwareaopen(bw, 50);  % Remove small debris

% Separate touching cells with marker-controlled watershed
D = -bwdist(~bw);
D = imhmin(D, 2);  % Suppress shallow minima (controls split sensitivity)
L = watershed(D);
bw(L == 0) = false;  % Remove watershed ridges

% Create instance labels
labels = bwlabel(bw);
fprintf('Detected %d cells\n', max(labels(:)));
```

### Tune Watershed Sensitivity

```matlab
% More aggressive splitting (over-segment)
D = imhmin(-bwdist(~bw), 1);  % Lower = more splits

% Less aggressive (under-segment, keep merged)
D = imhmin(-bwdist(~bw), 5);  % Higher = fewer splits
```

### H-minima vs Extended-minima Markers

```matlab
% Alternative: use extended minima as markers
markers = imextendedmin(imgCorr, 0.05);
markers = imclose(markers, strel('disk', 2));
imposedMin = imimposemin(imgCorr, markers);
L = watershed(imposedMin);
```

## Cell Measurements

```matlab
% Comprehensive measurements
props = regionprops('table', labels, imgGray, ...
    'Area', 'Centroid', 'Perimeter', 'Eccentricity', ...
    'MajorAxisLength', 'MinorAxisLength', ...
    'MeanIntensity', 'Solidity', 'EquivDiameter');

% Derived features
props.Circularity = (4 * pi * props.Area) ./ (props.Perimeter.^2);
props.AspectRatio = props.MajorAxisLength ./ props.MinorAxisLength;

% Filter by size
validIdx = props.Area >= 100 & props.Area <= 5000;
props = props(validIdx, :);

% Export
writetable(props, 'cell_measurements.csv');
```

## Nuclei Segmentation in H&E

```matlab
% Extract hematoxylin channel (nuclei-specific)
hed = rgb2hed(img);  % Hematoxylin-Eosin-DAB separation
nucleiChannel = hed(:,:,1);
nucleiChannel = mat2gray(nucleiChannel);

% Threshold nuclei (dark in hematoxylin channel)
T = graythresh(nucleiChannel);
bw = imbinarize(nucleiChannel, T);

% Cleanup and separate
bw = imfill(bw, 'holes');
bw = bwareaopen(bw, 30);
D = -bwdist(~bw);
D = imhmin(D, 1);
L = watershed(D);
bw(L == 0) = false;
labels = bwlabel(bw);
```

## MedSAM for Interactive Cell Segmentation

When you need precise segmentation of specific cells:

```matlab
% Load MedSAM (requires support package)
model = medicalSegmentAnythingModel;

% Generate embeddings
embeddings = extractEmbeddings(model, img);
imageSize = size(img, [1 2]);

% Segment specific cell with bounding box
bbox = [x, y, width, height];  % Around target cell
mask = segmentObjectsFromEmbeddings(model, embeddings, ...
    imageSize, BoundingBox=bbox);
```

## Python Cellpose Integration

For state-of-art cell instance segmentation:

```matlab
% Save image for Python
imwrite(img, 'temp_image.tif');

% Call Cellpose via Python
pyrunfile("cellpose_segment.py", "temp_image.tif")

% Load results back
labels = imread('temp_labels.tif');
```

Where `cellpose_segment.py`:
```python
import sys
from cellpose import models
from skimage import io

img = io.imread(sys.argv[1])
model = models.Cellpose(model_type='cyto2')
masks, _, _, _ = model.eval(img, diameter=30)
io.imsave('temp_labels.tif', masks.astype('uint16'))
```

## Post-Processing

### Remove Border Cells

```matlab
labels = imclearborder(labels);
```

### Filter by Size and Shape

```matlab
props = regionprops(labels, 'Area', 'Eccentricity', 'PixelIdxList');
for i = 1:length(props)
    if props(i).Area < 50 || props(i).Area > 5000 || props(i).Eccentricity > 0.95
        labels(props(i).PixelIdxList) = 0;
    end
end
labels = labelmatrix(bwconncomp(labels > 0));
```

### Smooth Boundaries

```matlab
se = strel('disk', 2);
for i = 1:max(labels(:))
    cellMask = labels == i;
    cellMask = imclose(imopen(cellMask, se), se);
    labels(cellMask) = i;
end
```

## Common Issues

| Problem | Solution |
|---------|----------|
| Cells merged together | Lower `imhmin` threshold (e.g., 1 instead of 3) |
| Over-segmented | Raise `imhmin` threshold (e.g., 5) or increase `bwareaopen` size |
| Dim cells missed | Use `adapthisteq` before thresholding |
| Uneven illumination | Apply `imopen`-based background subtraction |
| Touching nuclei in H&E | Use distance transform watershed |

---

*See also: `cross-toolbox-ipt.md` for Image Processing Toolbox integration*
*See also: `segmentation-medsam.md` for interactive segmentation with MedSAM*
