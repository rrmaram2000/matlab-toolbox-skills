# Object Detection

Object detection locates and classifies multiple objects in images. Essential for nodule detection, cell counting, and anatomical landmark localization.

## Detector Architectures

| Architecture | Function | Speed | Accuracy | Best For |
|--------------|----------|-------|----------|----------|
| **YOLO v4** | `yolov4ObjectDetector` | Fast | High | Real-time, single-stage |
| **Faster R-CNN** | `fasterRCNNObjectDetector` | Slow | Highest | Accuracy-critical |
| **SSD** | `ssdObjectDetector` | Fast | Medium | Mobile/edge |
| **RetinaNet** | `retinanetObjectDetector` | Medium | High | Class imbalance |

## YOLO v4

### Create YOLO v4 Detector

```matlab
% Load pretrained YOLO v4
detector = yolov4ObjectDetector('csp-darknet53-coco');

% Or train custom detector
inputSize = [416 416 3];
numClasses = 5;
anchorBoxes = estimateAnchorBoxes(trainingData, 9);

% Create detector with custom anchors
lgraph = yolov4Layers(inputSize, numClasses, anchorBoxes, 'csp-darknet53');
detector = yolov4ObjectDetector(lgraph);
```

### Anchor Box Estimation

```matlab
% Load training data (table with image paths and bboxes)
data = load('groundTruth.mat');
trainingData = data.gTruth;

% Estimate anchors for different scales
numAnchors = 9;  % 3 per scale for YOLO v4
anchorBoxes = estimateAnchorBoxes(trainingData, numAnchors);

% Display anchor statistics
fprintf('Anchor boxes:\n');
disp(anchorBoxes);

% Mean IoU between anchors and ground truth
meanIoU = mean(bboxOverlapRatio(anchorBoxes, ...
    vertcat(trainingData.bboxes{:})));
fprintf('Mean IoU: %.3f\n', meanIoU);
```

### Training YOLO v4

```matlab
% Training options
options = trainingOptions('adam', ...
    'MaxEpochs', 100, ...
    'MiniBatchSize', 8, ...
    'InitialLearnRate', 1e-4, ...
    'LearnRateSchedule', 'piecewise', ...
    'LearnRateDropFactor', 0.1, ...
    'LearnRateDropPeriod', 50, ...
    'ResetInputNormalization', false, ...
    'Shuffle', 'every-epoch', ...
    'Plots', 'training-progress', ...
    'ExecutionEnvironment', 'gpu');

% Train detector
[detector, info] = trainYOLOv4ObjectDetector(trainingData, detector, options);
```

## Faster R-CNN

### Create Faster R-CNN

```matlab
% Input size and classes
inputSize = [600 600 3];
numClasses = 3;

% Define feature extraction network (backbone)
featureExtractionNetwork = resnet50;
featureLayer = 'activation_40_relu';  % Late layer for better features

% Anchor boxes (width x height)
anchorBoxes = [32 32; 64 64; 128 128; 256 256;
               32 64; 64 128; 128 256;
               64 32; 128 64; 256 128];

% Create detector
lgraph = fasterRCNNLayers(inputSize, numClasses, anchorBoxes, ...
    featureExtractionNetwork, featureLayer);

% Or use pretrained
detector = fasterRCNNObjectDetector('resnet50-coco');
```

### Training Faster R-CNN

```matlab
% Region proposal settings
rpnOptions = trainingOptions('sgdm', ...
    'MaxEpochs', 10, ...
    'MiniBatchSize', 1, ...       % Usually 1-2 for Faster R-CNN
    'InitialLearnRate', 1e-3, ...
    'Plots', 'training-progress');

% Full detector training
detectorOptions = trainingOptions('sgdm', ...
    'MaxEpochs', 10, ...
    'MiniBatchSize', 1, ...
    'InitialLearnRate', 1e-4, ...  % Lower for fine-tuning
    'CheckpointPath', 'checkpoints/', ...
    'Plots', 'training-progress');

% Train (4-step alternating training)
detector = trainFasterRCNNObjectDetector(trainingData, lgraph, ...
    rpnOptions, 'DetectorTrainingOptions', detectorOptions);
```

## SSD (Single Shot Detector)

```matlab
% Create SSD detector
inputSize = [300 300 3];
numClasses = 4;

% With MobileNet backbone (fast)
lgraph = ssdLayers(inputSize, numClasses, 'mobilenetv2');

% With ResNet backbone (accurate)
lgraph = ssdLayers(inputSize, numClasses, 'resnet50');

% Train
options = trainingOptions('adam', ...
    'MaxEpochs', 50, ...
    'MiniBatchSize', 16, ...
    'InitialLearnRate', 1e-3);

detector = trainSSDObjectDetector(trainingData, lgraph, options);
```

## RetinaNet (Focal Loss)

```matlab
% RetinaNet with focal loss (good for imbalanced datasets)
inputSize = [600 600 3];
numClasses = 2;  % e.g., nodule vs background

% Create RetinaNet
lgraph = retinanetLayers(inputSize, numClasses, 'resnet50');

% Training with focal loss (built-in)
options = trainingOptions('sgdm', ...
    'MaxEpochs', 40, ...
    'MiniBatchSize', 2, ...
    'InitialLearnRate', 1e-4);

detector = trainRetinaNetObjectDetector(trainingData, lgraph, options);
```

## Data Preparation

### Box Label Datastore

```matlab
% Ground truth table format:
%   ImagePath | Class1 | Class2 | ...
%   'img1.png'| [x y w h; ...]| [x y w h; ...]

% Load ground truth
load('detectionGroundTruth.mat', 'gTruth');

% Create datastores
imds = imageDatastore(gTruth.imageFilename);
blds = boxLabelDatastore(gTruth(:, 2:end));

% Combine
trainingData = combine(imds, blds);

% Visualize sample
data = read(trainingData);
I = data{1};
bboxes = data{2};
labels = data{3};

figure;
annotatedImage = insertObjectAnnotation(I, 'Rectangle', bboxes, labels);
imshow(annotatedImage);
```

### Data Augmentation for Detection

```matlab
% Transform function must handle both image AND bboxes
function data = augmentDetection(data)
    img = data{1};
    bboxes = data{2};
    labels = data{3};

    % Random horizontal flip
    if rand > 0.5
        img = fliplr(img);
        % Adjust bbox x-coordinates
        bboxes(:,1) = size(img, 2) - bboxes(:,1) - bboxes(:,3);
    end

    % Random color jitter (image only)
    img = jitterColorHSV(img, ...
        'Contrast', 0.2, ...
        'Hue', 0.1, ...
        'Saturation', 0.2, ...
        'Brightness', 0.2);

    data = {img, bboxes, labels};
end

% Apply to datastore
augmentedData = transform(trainingData, @augmentDetection);
```

### Resizing with Bounding Boxes

```matlab
function data = resizeWithBboxes(data, targetSize)
    img = data{1};
    bboxes = data{2};
    labels = data{3};

    [H, W, ~] = size(img);
    scaleX = targetSize(2) / W;
    scaleY = targetSize(1) / H;

    % Resize image
    img = imresize(img, targetSize);

    % Scale bounding boxes
    bboxes(:, [1 3]) = bboxes(:, [1 3]) * scaleX;
    bboxes(:, [2 4]) = bboxes(:, [2 4]) * scaleY;

    data = {img, bboxes, labels};
end
```

## Inference

### Single Image Detection

```matlab
% Load image
img = imread('test_image.png');
img = imresize(img, [416 416]);  % Match training size

% Detect objects
[bboxes, scores, labels] = detect(detector, img);

% Apply confidence threshold
minScore = 0.5;
keep = scores >= minScore;
bboxes = bboxes(keep, :);
scores = scores(keep);
labels = labels(keep);

% Visualize
annotatedImg = insertObjectAnnotation(img, 'Rectangle', bboxes, ...
    cellstr(labels) + " " + string(round(scores, 2)));
figure; imshow(annotatedImg);
```

### Batch Detection

```matlab
% Detect on multiple images
results = detect(detector, testImages, ...
    'MiniBatchSize', 8, ...
    'Threshold', 0.5);

% results is a table with columns: Boxes, Scores, Labels
```

### Non-Maximum Suppression

```matlab
% Custom NMS (if needed)
function [bboxes, scores, labels] = customNMS(bboxes, scores, labels, overlapThresh)
    if isempty(bboxes)
        return;
    end

    % Sort by score
    [scores, idx] = sort(scores, 'descend');
    bboxes = bboxes(idx, :);
    labels = labels(idx);

    keep = true(size(scores));
    for i = 1:numel(scores)
        if ~keep(i), continue; end

        for j = (i+1):numel(scores)
            if ~keep(j), continue; end

            iou = bboxOverlapRatio(bboxes(i,:), bboxes(j,:));
            if iou > overlapThresh && labels(i) == labels(j)
                keep(j) = false;
            end
        end
    end

    bboxes = bboxes(keep, :);
    scores = scores(keep);
    labels = labels(keep);
end
```

## Evaluation

### Mean Average Precision (mAP)

```matlab
% Evaluate detector
results = detect(detector, testData, 'MiniBatchSize', 4);

% Compute precision-recall and AP
[ap, recall, precision] = evaluateObjectDetection(results, testData);

% Display results
fprintf('Mean AP @ IoU 0.5: %.3f\n', mean(ap));

% Per-class AP
classNames = testData.Properties.VariableNames(2:end);
for i = 1:numel(classNames)
    fprintf('%s AP: %.3f\n', classNames{i}, ap(i));
end
```

### Precision-Recall Curve

```matlab
% Plot PR curves
figure;
hold on;
colors = lines(numel(classNames));

for i = 1:numel(classNames)
    plot(recall{i}, precision{i}, 'Color', colors(i,:), ...
        'LineWidth', 2, 'DisplayName', sprintf('%s (AP=%.2f)', ...
        classNames{i}, ap(i)));
end

xlabel('Recall');
ylabel('Precision');
title('Precision-Recall Curves');
legend('Location', 'southwest');
grid on;
```

### Detection Statistics

```matlab
% Analyze detection results
function stats = analyzeDetections(results, groundTruth, iouThreshold)
    stats.TP = 0;  % True positives
    stats.FP = 0;  % False positives
    stats.FN = 0;  % False negatives

    for i = 1:height(results)
        detBoxes = results.Boxes{i};
        gtBoxes = groundTruth{i, 2};

        if isempty(gtBoxes)
            stats.FP = stats.FP + size(detBoxes, 1);
            continue;
        end

        if isempty(detBoxes)
            stats.FN = stats.FN + size(gtBoxes, 1);
            continue;
        end

        % Compute IoU matrix
        iouMatrix = bboxOverlapRatio(detBoxes, gtBoxes);

        % Match detections to ground truth
        matched = false(size(gtBoxes, 1), 1);
        for j = 1:size(detBoxes, 1)
            [maxIoU, idx] = max(iouMatrix(j, :));
            if maxIoU >= iouThreshold && ~matched(idx)
                stats.TP = stats.TP + 1;
                matched(idx) = true;
            else
                stats.FP = stats.FP + 1;
            end
        end
        stats.FN = stats.FN + sum(~matched);
    end

    % Compute metrics
    stats.precision = stats.TP / (stats.TP + stats.FP);
    stats.recall = stats.TP / (stats.TP + stats.FN);
    stats.f1 = 2 * stats.precision * stats.recall / ...
        (stats.precision + stats.recall);
end
```

## Medical Object Detection Example

```matlab
% Lung nodule detection in CT scans
% Ground truth: table with ImagePath and Nodule columns

%% 1. Load and prepare data
load('noduleGroundTruth.mat', 'gTruth');
[trainData, valData, testData] = splitData(gTruth, 0.7, 0.15);

%% 2. Estimate anchor boxes
numAnchors = 6;
anchorBoxes = estimateAnchorBoxes(trainData, numAnchors);

%% 3. Create YOLO v4 detector (good for real-time screening)
inputSize = [512 512 3];
numClasses = 1;  % Single class: Nodule

lgraph = yolov4Layers(inputSize, numClasses, anchorBoxes, 'csp-darknet53');

%% 4. Data augmentation
augmentedTrain = transform(trainData, @(data) augmentNodule(data));

function data = augmentNodule(data)
    img = data{1};
    bboxes = data{2};
    labels = data{3};

    % Convert grayscale to RGB (for pretrained backbone)
    if size(img, 3) == 1
        img = repmat(img, 1, 1, 3);
    end

    % Random flip
    if rand > 0.5
        img = fliplr(img);
        bboxes(:,1) = size(img,2) - bboxes(:,1) - bboxes(:,3);
    end

    % Random rotation (±10°)
    angle = (rand - 0.5) * 20;
    img = imrotate(img, angle, 'bilinear', 'crop');
    % Note: bbox rotation is complex, skip for small angles

    % Intensity augmentation
    img = img * (0.9 + rand * 0.2);  % ±10% brightness

    data = {im2single(img), bboxes, labels};
end

%% 5. Train
options = trainingOptions('adam', ...
    'MaxEpochs', 80, ...
    'MiniBatchSize', 4, ...
    'InitialLearnRate', 1e-4, ...
    'LearnRateSchedule', 'piecewise', ...
    'LearnRateDropFactor', 0.1, ...
    'LearnRateDropPeriod', 40, ...
    'ValidationData', valData, ...
    'ValidationFrequency', 100, ...
    'Plots', 'training-progress', ...
    'ExecutionEnvironment', 'gpu');

[detector, info] = trainYOLOv4ObjectDetector(augmentedTrain, lgraph, options);

%% 6. Evaluate
results = detect(detector, testData, 'MiniBatchSize', 4, 'Threshold', 0.3);
[ap, recall, precision] = evaluateObjectDetection(results, testData);

fprintf('Nodule Detection AP @ IoU 0.5: %.3f\n', ap);
fprintf('Sensitivity (Recall): %.3f\n', recall{1}(end));

% FROC analysis (Free-Response ROC for medical imaging)
thresholds = 0.1:0.1:0.9;
sensitivity = zeros(size(thresholds));
fpPerImage = zeros(size(thresholds));

for t = 1:numel(thresholds)
    stats = analyzeDetections(results, testData, thresholds(t));
    sensitivity(t) = stats.recall;
    fpPerImage(t) = stats.FP / height(testData);
end

figure;
plot(fpPerImage, sensitivity, 'b-o', 'LineWidth', 2);
xlabel('False Positives per Image');
ylabel('Sensitivity');
title('FROC Curve - Nodule Detection');
grid on;
```

---

*Source: Deep Learning Toolbox Documentation - Object Detection (R2025b)*
