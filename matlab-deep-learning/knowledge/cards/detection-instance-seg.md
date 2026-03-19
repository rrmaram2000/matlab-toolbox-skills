# Object Detection & Instance Segmentation

Condensed reference for YOLO v4, Faster R-CNN, SSD, RetinaNet, and Mask R-CNN. Focuses on configuration, anchor box estimation, training, and medical-specific patterns.

## Detector Architectures

| Architecture | Function | Speed | Accuracy | Best For |
|--------------|----------|-------|----------|----------|
| **YOLO v4** | `yolov4ObjectDetector` | Fast | High | Real-time, single-stage |
| **Faster R-CNN** | `fasterRCNNObjectDetector` | Slow | Highest | Accuracy-critical |
| **SSD** | `ssdObjectDetector` | Fast | Medium | Mobile/edge |
| **RetinaNet** | `retinanetObjectDetector` | Medium | High | Class imbalance |
| **Mask R-CNN** | `maskrcnn` | Slow | Highest | Instance segmentation |

## Anchor Box Estimation (Critical for All Detectors)

```matlab
load('groundTruth.mat', 'gTruth');
numAnchors = 9;  % 3 per scale for YOLO v4
anchorBoxes = estimateAnchorBoxes(gTruth, numAnchors);
```

## YOLO v4

```matlab
% Custom detector
inputSize = [416 416 3];
lgraph = yolov4Layers(inputSize, numClasses, anchorBoxes, 'csp-darknet53');
detector = yolov4ObjectDetector(lgraph);

options = trainingOptions('adam', ...
    'MaxEpochs', 80, ...
    'MiniBatchSize', 8, ...
    'InitialLearnRate', 1e-4, ...
    'ResetInputNormalization', false, ...
    'ExecutionEnvironment', 'gpu');
[detector, info] = trainYOLOv4ObjectDetector(trainData, detector, options);
```

## Faster R-CNN

```matlab
featureExtractionNetwork = resnet50;
featureLayer = 'activation_40_relu';
anchorBoxes = [32 32; 64 64; 128 128; 256 256;
               32 64; 64 128; 128 256;
               64 32; 128 64; 256 128];

lgraph = fasterRCNNLayers(inputSize, numClasses, anchorBoxes, ...
    featureExtractionNetwork, featureLayer);
detector = trainFasterRCNNObjectDetector(trainData, lgraph, options);
```

## Mask R-CNN (Instance Segmentation)

```matlab
% Load pretrained
detector = maskrcnn('resnet50-coco');

% Custom Mask R-CNN
lgraph = maskrcnnLayers(inputSize, numClasses, ...
    'resnet50', ...
    'AnchorBoxes', anchorBoxes, ...
    'ROIOutputSize', [14 14]);
detector = maskrcnn(lgraph, classNames);

% Train
options = trainingOptions('sgdm', ...
    'MaxEpochs', 20, ...
    'MiniBatchSize', 2, ...     % Small batch for Mask R-CNN
    'InitialLearnRate', 0.001, ...
    'ExecutionEnvironment', 'gpu');
[detector, info] = trainMaskRCNN(trainingData, detector, options);

% Inference
[masks, labels, scores, bboxes] = segmentObjects(detector, img);
```

## Data Augmentation for Detection

```matlab
% MUST transform both image AND bboxes together
function data = augmentDetection(data)
    img = data{1};
    bboxes = data{2};
    labels = data{3};

    if rand > 0.5
        img = fliplr(img);
        bboxes(:,1) = size(img, 2) - bboxes(:,1) - bboxes(:,3);
    end

    img = jitterColorHSV(img, ...
        'Contrast', 0.2, 'Hue', 0.1, ...
        'Saturation', 0.2, 'Brightness', 0.2);

    data = {img, bboxes, labels};
end
```

## Evaluation

```matlab
results = detect(detector, testData, 'MiniBatchSize', 4);
[ap, recall, precision] = evaluateObjectDetection(results, testData);
fprintf('Mean AP @ IoU 0.5: %.3f\n', mean(ap));
```

## Medical Example: Lung Nodule Detection

```matlab
% FROC analysis (Free-Response ROC for medical imaging)
thresholds = 0.1:0.1:0.9;
sensitivity = zeros(size(thresholds));
fpPerImage = zeros(size(thresholds));

for t = 1:numel(thresholds)
    stats = analyzeDetections(results, testData, thresholds(t));
    sensitivity(t) = stats.recall;
    fpPerImage(t) = stats.FP / height(testData);
end

plot(fpPerImage, sensitivity, 'b-o', 'LineWidth', 2);
xlabel('False Positives per Image');
ylabel('Sensitivity');
title('FROC Curve');
```

---

*Source: Deep Learning Toolbox Documentation - Object Detection & Instance Segmentation (R2025b)*
