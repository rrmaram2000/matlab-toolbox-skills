# Deep Learning Segmentation: IPT Integration Patterns

> **R2024b+ API Changes:** `unetLayers` → `unet` (returns dlnetwork), `trainNetwork` → `trainnet` with loss argument, `NumFirstEncoderFilters` default = **64** (not 32). See Deep Learning Toolbox skill for full modern syntax.

This card covers IPT-specific integration patterns for DL segmentation, not general DL training.

## Medical Image Preprocessing for DL

### Grayscale-to-3-Channel Expansion
```matlab
% Most pretrained networks expect 3 channels
img = im2single(imread('medical_image.png'));
if size(img, 3) == 1
    img = repmat(img, [1 1 3]);  % Expand grayscale to 3 channels
end
```

### Patch-Based Inference for Large Medical Images
```matlab
function segmented = segment_large_image(img, net, patchSize, overlap)
    % For histology/whole-slide images that don't fit in memory
    arguments
        img
        net
        patchSize = [256 256]
        overlap = 32  % Overlap reduces tile-boundary artifacts
    end

    [H, W, ~] = size(img);
    segmented = zeros(H, W, 'uint8');
    stepSize = patchSize - overlap;

    for y = 1:stepSize(1):H
        for x = 1:stepSize(2):W
            y_end = min(y + patchSize(1) - 1, H);
            x_end = min(x + patchSize(2) - 1, W);
            patch = img(y:y_end, x:x_end, :);

            % Pad undersized edge patches
            if size(patch, 1) < patchSize(1) || size(patch, 2) < patchSize(2)
                patch = padarray(patch, ...
                    [patchSize(1)-size(patch,1), patchSize(2)-size(patch,2)], ...
                    0, 'post');
            end

            seg_patch = semanticseg(im2single(patch), net);
            patch_h = y_end - y + 1;
            patch_w = x_end - x + 1;
            segmented(y:y_end, x:x_end) = uint8(seg_patch(1:patch_h, 1:patch_w));
        end
    end
end
```

## Post-Processing DL Output with IPT

```matlab
% DL segmentation output often needs morphological cleanup
seg = semanticseg(img, net);
mask = seg == "tumor";

% Standard IPT cleanup on DL output
mask = bwareaopen(mask, 50);       % Remove small false positives
mask = imfill(mask, 'holes');      % Fill holes in predictions
mask = imclose(mask, strel('disk', 3)); % Smooth boundaries

% Measure with regionprops
stats = regionprops('table', mask, im2double(img), ...
    'Area', 'Centroid', 'MeanIntensity');
```

## Class Imbalance — The Medical Imaging Problem

Background dominates in medical images. Without weighting, the network predicts everything as background.

```matlab
% Calculate inverse-frequency class weights
tbl = countEachLabel(pxds);
totalPixels = sum(tbl.PixelCount);
classWeights = totalPixels ./ tbl.PixelCount;
classWeights = classWeights / sum(classWeights);
```

## Evaluation Using IPT Functions

```matlab
% IPT provides jaccard and dice for segmentation evaluation
metrics.iou = jaccard(predicted, groundTruth);   % IoU per class
metrics.dice = dice(predicted, groundTruth);     % Dice per class
metrics.meanDice = mean(metrics.dice);
```

---
*Verified against MATLAB R2025b*
