# Instance Segmentation

Instance segmentation combines object detection with pixel-level segmentation, identifying individual objects and their precise boundaries. Essential for cell counting, nuclei detection, and multi-object medical imaging.

## Mask R-CNN

### Overview

Mask R-CNN extends Faster R-CNN with a parallel branch for predicting segmentation masks. It provides:
- Bounding box detection
- Class labels
- Instance-level masks

### Create Mask R-CNN

```matlab
% Load pretrained Mask R-CNN
detector = maskrcnn('resnet50-coco');

% Or create custom Mask R-CNN
inputSize = [512 512 3];
numClasses = 3;  % cell, nucleus, background

% Create network
lgraph = maskrcnnLayers(inputSize, numClasses, ...
    'resnet50', ...                     % Backbone
    'AnchorBoxes', anchorBoxes, ...     % Estimated anchors
    'ROIOutputSize', [14 14]);          % Mask resolution

detector = maskrcnn(lgraph, classNames);
```

### Anchor Box Estimation

```matlab
% Ground truth table with masks
load('instanceGroundTruth.mat', 'gTruth');
% gTruth: table with ImagePath | InstanceMasks

% Extract bounding boxes from masks
bboxes = [];
for i = 1:height(gTruth)
    masks = gTruth.InstanceMasks{i};
    for j = 1:numel(masks)
        props = regionprops(masks{j}, 'BoundingBox');
        bboxes = [bboxes; props.BoundingBox];
    end
end

% Estimate anchors
numAnchors = 9;  % 3 scales × 3 aspect ratios
anchorBoxes = estimateAnchorBoxes(bboxes, numAnchors);
```

## Data Preparation

### Instance Segmentation Ground Truth

```matlab
% Ground truth format for instance segmentation
% Table columns: ImagePath | Class1Masks | Class2Masks | ...
% Each cell contains cell array of binary masks

% Example structure:
gTruth = table();
gTruth.imageFilename = {'img1.png'; 'img2.png'};
gTruth.Cell = {
    {mask1_cell1, mask1_cell2, mask1_cell3};  % Image 1: 3 cells
    {mask2_cell1, mask2_cell2}                % Image 2: 2 cells
};
gTruth.Nucleus = {
    {mask1_nuc1, mask1_nuc2, mask1_nuc3};
    {mask2_nuc1, mask2_nuc2}
};
```

### Creating Masks from Labels

```matlab
% Convert labeled image to instance masks
function masks = labeledToMasks(labeledImg)
    numObjects = max(labeledImg(:));
    masks = cell(numObjects, 1);

    for i = 1:numObjects
        masks{i} = labeledImg == i;
    end
end

% From polygon annotations (e.g., COCO format)
function mask = polyToMask(polygon, imgSize)
    mask = poly2mask(polygon(:,1), polygon(:,2), imgSize(1), imgSize(2));
end

% From bounding boxes (approximate rectangles)
function mask = bboxToMask(bbox, imgSize)
    mask = false(imgSize);
    x = round(bbox(1));
    y = round(bbox(2));
    w = round(bbox(3));
    h = round(bbox(4));
    mask(y:y+h-1, x:x+w-1) = true;
end
```

### Data Augmentation for Instance Segmentation

```matlab
function data = augmentInstance(data)
    img = data{1};
    masks = data{2};  % Cell array of binary masks
    labels = data{3};

    [H, W, ~] = size(img);

    % Random horizontal flip
    if rand > 0.5
        img = fliplr(img);
        for i = 1:numel(masks)
            masks{i} = fliplr(masks{i});
        end
    end

    % Random rotation (small angle)
    if rand > 0.5
        angle = (rand - 0.5) * 20;  % ±10°
        img = imrotate(img, angle, 'bilinear', 'crop');
        for i = 1:numel(masks)
            masks{i} = imrotate(masks{i}, angle, 'nearest', 'crop');
        end
    end

    % Random scale
    if rand > 0.5
        scale = 0.9 + rand * 0.2;  % 0.9-1.1
        newSize = round([H W] * scale);
        img = imresize(img, newSize);
        for i = 1:numel(masks)
            masks{i} = imresize(masks{i}, newSize, 'nearest');
        end
        % Crop or pad to original size
        [img, masks] = cropOrPad(img, masks, [H W]);
    end

    % Intensity augmentation (image only)
    img = img * (0.8 + rand * 0.4);
    img = max(0, min(1, img));

    data = {img, masks, labels};
end

function [img, masks] = cropOrPad(img, masks, targetSize)
    [H, W, C] = size(img);
    targetH = targetSize(1);
    targetW = targetSize(2);

    if H > targetH || W > targetW
        % Crop from center
        startH = floor((H - targetH) / 2) + 1;
        startW = floor((W - targetW) / 2) + 1;
        img = img(startH:startH+targetH-1, startW:startW+targetW-1, :);
        for i = 1:numel(masks)
            masks{i} = masks{i}(startH:startH+targetH-1, startW:startW+targetW-1);
        end
    elseif H < targetH || W < targetW
        % Pad
        padH = targetH - H;
        padW = targetW - W;
        img = padarray(img, [floor(padH/2) floor(padW/2)], 0, 'pre');
        img = padarray(img, [ceil(padH/2) ceil(padW/2)], 0, 'post');
        for i = 1:numel(masks)
            masks{i} = padarray(masks{i}, [floor(padH/2) floor(padW/2)], 0, 'pre');
            masks{i} = padarray(masks{i}, [ceil(padH/2) ceil(padW/2)], 0, 'post');
        end
    end
end
```

## Training

### Training Mask R-CNN

```matlab
% Training options
options = trainingOptions('sgdm', ...
    'MaxEpochs', 20, ...
    'MiniBatchSize', 2, ...             % Small batch for Mask R-CNN
    'InitialLearnRate', 0.001, ...
    'LearnRateSchedule', 'piecewise', ...
    'LearnRateDropFactor', 0.1, ...
    'LearnRateDropPeriod', 10, ...
    'L2Regularization', 0.0001, ...
    'Shuffle', 'every-epoch', ...
    'VerboseFrequency', 50, ...
    'Plots', 'training-progress', ...
    'ExecutionEnvironment', 'gpu');

% Train
[detector, info] = trainMaskRCNN(trainingData, detector, options);
```

### Transfer Learning

```matlab
% Start from COCO-pretrained model
detector = maskrcnn('resnet50-coco');

% Replace classification head for custom classes
lgraph = layerGraph(detector.Network);

% Find and replace FC layers
oldFCName = 'rcnnBoxFC';  % Example layer name
newFC = fullyConnectedLayer(numClasses * 4, 'Name', 'rcnnBoxFC_custom');
lgraph = replaceLayer(lgraph, oldFCName, newFC);

% Retrain with lower learning rate
options = trainingOptions('sgdm', ...
    'InitialLearnRate', 0.0001, ...  % Low for fine-tuning
    'MaxEpochs', 10);

detector = trainMaskRCNN(trainingData, lgraph, options);
```

## Inference

### Detect and Segment

```matlab
% Load image
img = imread('cells.png');

% Detect instances
[masks, labels, scores, bboxes] = segmentObjects(detector, img);

% Filter by confidence
threshold = 0.5;
keep = scores >= threshold;
masks = masks(:,:,keep);
labels = labels(keep);
scores = scores(keep);
bboxes = bboxes(keep,:);

% Display results
figure;
imshow(img);
hold on;

% Overlay masks with different colors
colors = lines(numel(labels));
for i = 1:numel(labels)
    mask = masks(:,:,i);
    overlay = cat(3, colors(i,1)*ones(size(mask)), ...
                     colors(i,2)*ones(size(mask)), ...
                     colors(i,3)*ones(size(mask)));
    h = imshow(overlay);
    set(h, 'AlphaData', 0.4 * mask);

    % Add bounding box
    rectangle('Position', bboxes(i,:), 'EdgeColor', colors(i,:), 'LineWidth', 2);

    % Add label
    text(bboxes(i,1), bboxes(i,2)-10, sprintf('%s: %.2f', labels(i), scores(i)), ...
        'Color', 'w', 'BackgroundColor', colors(i,:), 'FontSize', 10);
end
```

### Batch Processing

```matlab
% Process multiple images
testFiles = dir('test_images/*.png');
allResults = cell(numel(testFiles), 1);

for i = 1:numel(testFiles)
    img = imread(fullfile(testFiles(i).folder, testFiles(i).name));
    [masks, labels, scores, bboxes] = segmentObjects(detector, img);

    allResults{i} = struct(...
        'masks', masks, ...
        'labels', labels, ...
        'scores', scores, ...
        'bboxes', bboxes);
end
```

## Evaluation

### Instance Segmentation Metrics

```matlab
% Compute AP for instance segmentation
function metrics = evaluateInstanceSegmentation(results, groundTruth, iouThresholds)
    if nargin < 3
        iouThresholds = 0.5:0.05:0.95;  % COCO-style
    end

    metrics.AP = zeros(numel(iouThresholds), 1);

    for t = 1:numel(iouThresholds)
        [ap, precision, recall] = computeAP(results, groundTruth, iouThresholds(t));
        metrics.AP(t) = ap;
    end

    metrics.mAP = mean(metrics.AP);  % Mean over IoU thresholds
    metrics.AP50 = metrics.AP(1);    % AP at IoU=0.5
    metrics.AP75 = metrics.AP(find(iouThresholds >= 0.75, 1));  % AP at IoU=0.75
end

function [ap, precision, recall] = computeAP(results, groundTruth, iouThreshold)
    % Collect all predictions
    allScores = [];
    allTP = [];

    for i = 1:numel(results)
        predMasks = results{i}.masks;
        gtMasks = groundTruth{i}.masks;

        if isempty(predMasks)
            continue;
        end

        scores = results{i}.scores;
        allScores = [allScores; scores(:)];

        % Match predictions to ground truth
        matched = false(size(gtMasks, 3), 1);
        tp = false(numel(scores), 1);

        for j = 1:size(predMasks, 3)
            bestIoU = 0;
            bestIdx = 0;

            for k = 1:size(gtMasks, 3)
                if matched(k), continue; end

                iou = computeMaskIoU(predMasks(:,:,j), gtMasks(:,:,k));
                if iou > bestIoU
                    bestIoU = iou;
                    bestIdx = k;
                end
            end

            if bestIoU >= iouThreshold && bestIdx > 0
                tp(j) = true;
                matched(bestIdx) = true;
            end
        end

        allTP = [allTP; tp];
    end

    % Sort by score
    [~, idx] = sort(allScores, 'descend');
    allTP = allTP(idx);

    % Compute precision-recall
    cumTP = cumsum(allTP);
    cumFP = cumsum(~allTP);
    totalPositives = sum(cellfun(@(x) size(x.masks, 3), groundTruth));

    precision = cumTP ./ (cumTP + cumFP);
    recall = cumTP / totalPositives;

    % Compute AP (area under PR curve)
    ap = computeAUC(recall, precision);
end

function iou = computeMaskIoU(mask1, mask2)
    intersection = sum(mask1(:) & mask2(:));
    union = sum(mask1(:) | mask2(:));
    iou = intersection / (union + eps);
end
```

### Panoptic Quality

```matlab
% Panoptic quality (combines segmentation + detection quality)
function pq = panopticQuality(predMasks, gtMasks, iouThreshold)
    if nargin < 3
        iouThreshold = 0.5;
    end

    % Match predictions to ground truth
    numPred = size(predMasks, 3);
    numGT = size(gtMasks, 3);

    matched = zeros(numGT, 1);
    iouSum = 0;
    TP = 0;
    FP = 0;
    FN = 0;

    for i = 1:numPred
        bestIoU = 0;
        bestIdx = 0;

        for j = 1:numGT
            if matched(j), continue; end
            iou = computeMaskIoU(predMasks(:,:,i), gtMasks(:,:,j));
            if iou > bestIoU
                bestIoU = iou;
                bestIdx = j;
            end
        end

        if bestIoU >= iouThreshold && bestIdx > 0
            TP = TP + 1;
            iouSum = iouSum + bestIoU;
            matched(bestIdx) = true;
        else
            FP = FP + 1;
        end
    end

    FN = numGT - TP;

    % Panoptic Quality = SQ × RQ
    % SQ (Segmentation Quality) = average IoU of matched pairs
    % RQ (Recognition Quality) = TP / (TP + 0.5*FP + 0.5*FN)
    SQ = iouSum / (TP + eps);
    RQ = TP / (TP + 0.5*FP + 0.5*FN + eps);
    pq = SQ * RQ;
end
```

## Medical Applications

### Cell Instance Segmentation

```matlab
%% Cell Detection and Segmentation Pipeline

% 1. Load data
load('cellGroundTruth.mat', 'gTruth');

% 2. Create Mask R-CNN
inputSize = [512 512 3];
classNames = ["Cell"];
numClasses = 1;

% Estimate anchors from cell sizes
anchorBoxes = estimateAnchorBoxes(gTruth, 6);

lgraph = maskrcnnLayers(inputSize, numClasses, ...
    'resnet50', ...
    'AnchorBoxes', anchorBoxes);

detector = maskrcnn(lgraph, classNames);

% 3. Train
options = trainingOptions('sgdm', ...
    'MaxEpochs', 30, ...
    'MiniBatchSize', 2, ...
    'InitialLearnRate', 0.001, ...
    'ExecutionEnvironment', 'gpu');

detector = trainMaskRCNN(gTruth, detector, options);

% 4. Inference
img = imread('cells_test.png');
[masks, labels, scores, bboxes] = segmentObjects(detector, img);

% 5. Post-processing
% Remove overlapping detections
[masks, scores] = nonMaxSuppressionMasks(masks, scores, 0.5);

% Count cells
numCells = size(masks, 3);
fprintf('Detected %d cells\n', numCells);

% 6. Measurement
for i = 1:numCells
    props = regionprops(masks(:,:,i), 'Area', 'Perimeter', 'Eccentricity');
    fprintf('Cell %d: Area=%d, Perimeter=%.1f, Eccentricity=%.2f\n', ...
        i, props.Area, props.Perimeter, props.Eccentricity);
end
```

### Nuclei Detection (Pathology)

```matlab
% Nuclei detection in histopathology
function [nucleiMasks, stats] = detectNuclei(img, detector)
    % Normalize staining (optional)
    img = normalizeStaining(img);

    % Detect nuclei
    [masks, labels, scores] = segmentObjects(detector, img);

    % Filter by size (remove debris)
    validMasks = [];
    for i = 1:size(masks, 3)
        props = regionprops(masks(:,:,i), 'Area');
        if props.Area > 50 && props.Area < 5000  % Size filter
            validMasks = cat(3, validMasks, masks(:,:,i));
        end
    end

    nucleiMasks = validMasks;

    % Compute statistics
    stats.count = size(nucleiMasks, 3);
    stats.areas = zeros(stats.count, 1);
    for i = 1:stats.count
        props = regionprops(nucleiMasks(:,:,i), 'Area');
        stats.areas(i) = props.Area;
    end
    stats.meanArea = mean(stats.areas);
    stats.stdArea = std(stats.areas);
end

% Stain normalization for H&E
function imgNorm = normalizeStaining(img)
    % Convert to OD space
    img = im2double(img);
    OD = -log10(img + 0.001);

    % Target stain vectors (standard H&E)
    HE_target = [0.650, 0.704, 0.286;   % Hematoxylin
                 0.072, 0.990, 0.105];  % Eosin

    % Normalize (simplified)
    imgNorm = im2uint8(img);  % Placeholder - use Macenko or Vahadane
end
```

---

*Source: Deep Learning Toolbox Documentation - Instance Segmentation (R2025b)*
