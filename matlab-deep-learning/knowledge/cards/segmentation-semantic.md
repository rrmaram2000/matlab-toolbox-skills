# Semantic Segmentation

> ⚠️ **R2024b+ API Changes:** `unetLayers` → `unet` (returns dlnetwork), `trainNetwork` → `trainnet`. Code below shows legacy syntax; see SKILL.md for modern equivalents.

Semantic segmentation assigns a class label to every pixel in an image. Essential for organ segmentation, lesion delineation, and tissue classification in medical imaging.

## Network Architectures

| Architecture | Function | Strengths | Medical Use |
|--------------|----------|-----------|-------------|
| **U-Net** | `unetLayers` | Skip connections, detail preservation | Organ/lesion segmentation |
| **U-Net 3D** | `unet3dLayers` | Volumetric data | CT/MRI volumes |
| **DeepLabv3+** | `deeplabv3plusLayers` | Atrous convolution, multi-scale | Boundary precision |
| **SegNet** | `segnetLayers` | Encoder-decoder | Real-time applications |

## U-Net Architecture

U-Net is the gold standard for medical image segmentation.

### Create U-Net

```matlab
% Basic U-Net
imageSize = [256 256 1];  % Grayscale input
numClasses = 2;           % Background + Foreground

lgraph = unetLayers(imageSize, numClasses);

% Customized U-Net
lgraph = unetLayers(imageSize, numClasses, ...
    'EncoderDepth', 4, ...              % Depth of encoder (default: 4)
    'NumFirstEncoderFilters', 64, ...   % Filters in first encoder (default: 64)
    'FilterSize', 3, ...                % Convolution filter size
    'ConvolutionPadding', 'same', ...   % Padding mode
    'Activation', 'relu');              % Activation function

% Analyze network
analyzeNetwork(lgraph);
```

### 3D U-Net for Volumetric Data

```matlab
% For CT/MRI volumes
imageSize = [128 128 64 1];  % H×W×D×C
numClasses = 3;              % Background, Organ1, Organ2

lgraph = unet3dLayers(imageSize, numClasses, ...
    'EncoderDepth', 3, ...              % Shallower for memory
    'NumFirstEncoderFilters', 32);      % Fewer filters for 3D

% Memory warning: 3D U-Net is memory-intensive
% Use smaller patch sizes and batch size
```

## DeepLabv3+

Superior boundary delineation through atrous convolution.

```matlab
% Create DeepLabv3+
imageSize = [512 512 3];
numClasses = 5;

lgraph = deeplabv3plusLayers(imageSize, numClasses, ...
    'resnet50', ...                     % Backbone network
    'DownsamplingFactor', 16);          % Output stride (8 or 16)

% For medical grayscale: modify input layer
lgraph = replaceLayer(lgraph, lgraph.Layers(1).Name, ...
    imageInputLayer([512 512 1], 'Name', 'input', 'Normalization', 'zscore'));
```

## Data Preparation

### Pixel Label Datastore

```matlab
% Create image datastore
imds = imageDatastore('images/', ...
    'FileExtensions', '.png');

% Define classes
classNames = ["Background", "Tumor", "Healthy"];
pixelLabelIDs = [0, 1, 2];  % Label values in mask images

% Create pixel label datastore
pxds = pixelLabelDatastore('masks/', classNames, pixelLabelIDs);

% Combine for training
cds = combine(imds, pxds);

% Check class distribution
tbl = countEachLabel(pxds);
disp(tbl);
```

### Data Augmentation for Segmentation

```matlab
% Custom augmentation function (must transform both image AND mask)
function [imgOut, maskOut] = augmentImageAndMask(img, mask)
    % Random rotation
    angle = (rand - 0.5) * 30;  % ±15 degrees
    img = imrotate(img, angle, 'bilinear', 'crop');
    mask = imrotate(mask, angle, 'nearest', 'crop');

    % Random horizontal flip
    if rand > 0.5
        img = fliplr(img);
        mask = fliplr(mask);
    end

    % Random intensity (image only)
    img = img * (0.8 + rand * 0.4);  % [0.8, 1.2]

    imgOut = img;
    maskOut = mask;
end

% Apply to combined datastore
augDs = transform(cds, @(data) augmentImageAndMask(data{1}, data{2}));
```

### Resizing for Network Input

```matlab
% Resize images and masks to network input size
targetSize = [256 256];

function [imgOut, maskOut] = resizeData(img, mask)
    imgOut = imresize(img, targetSize);
    maskOut = imresize(mask, targetSize, 'nearest');  % CRITICAL: nearest for masks!
end

resizedDs = transform(cds, @(data) resizeData(data{1}, data{2}));
```

## Loss Functions

### Cross-Entropy (Default)

```matlab
% Standard pixel-wise cross-entropy
lgraph = unetLayers([256 256 1], 2);
options = trainingOptions('adam', ...
    'MaxEpochs', 50, ...
    'MiniBatchSize', 8);
net = trainNetwork(trainDs, lgraph, options);
```

### Weighted Cross-Entropy (Class Imbalance)

```matlab
% Compute class weights from label distribution
tbl = countEachLabel(pxds);
totalPixels = sum(tbl.PixelCount);
classWeights = totalPixels ./ (numel(tbl.Name) * tbl.PixelCount);
classWeights = classWeights / sum(classWeights) * numel(classWeights);

% Create weighted classification layer
pxLayer = pixelClassificationLayer('Name', 'output', ...
    'Classes', tbl.Name, ...
    'ClassWeights', classWeights);

% Replace in network
lgraph = replaceLayer(lgraph, 'Segmentation-Layer', pxLayer);
```

### Dice Loss (Custom Training)

```matlab
% Dice loss is excellent for segmentation with class imbalance
function loss = diceLoss(Y, T)
    % Y: predictions (softmax probabilities), size: H×W×C×B
    % T: targets (one-hot encoded), size: H×W×C×B

    smooth = 1e-6;

    % Compute dice per class
    intersection = sum(Y .* T, [1 2]);  % Sum over spatial dims
    cardinality = sum(Y, [1 2]) + sum(T, [1 2]);

    dicePerClass = (2 * intersection + smooth) ./ (cardinality + smooth);

    % Mean dice across classes and batch
    loss = 1 - mean(dicePerClass, 'all');
end

% Use in custom training loop
function [loss, gradients, state] = modelLoss(net, X, T)
    [Y, state] = forward(net, X);
    loss = diceLoss(Y, T);
    gradients = dlgradient(loss, net.Learnables);
end
```

### Combined Loss (Dice + Cross-Entropy)

```matlab
function loss = combinedLoss(Y, T, alpha)
    % alpha: weight for dice loss (typically 0.5)
    ce = crossentropy(Y, T);
    dice = diceLoss(Y, T);
    loss = alpha * dice + (1 - alpha) * ce;
end
```

### Focal Loss for Hard Examples

```matlab
function loss = focalLoss(Y, T, gamma)
    % gamma: focusing parameter (typically 2)
    pt = sum(Y .* T, 3);  % Probability of true class
    loss = -mean((1 - pt).^gamma .* log(pt + 1e-8), 'all');
end
```

## Training

### Standard Training

```matlab
% Training options
options = trainingOptions('adam', ...
    'MaxEpochs', 100, ...
    'MiniBatchSize', 8, ...
    'InitialLearnRate', 1e-3, ...
    'LearnRateSchedule', 'piecewise', ...
    'LearnRateDropFactor', 0.5, ...
    'LearnRateDropPeriod', 20, ...
    'ValidationData', valDs, ...
    'ValidationFrequency', 50, ...
    'Shuffle', 'every-epoch', ...
    'Plots', 'training-progress', ...
    'ExecutionEnvironment', 'gpu');

net = trainNetwork(trainDs, lgraph, options);
```

### Custom Training with Dice Loss

```matlab
% Convert to dlnetwork for custom training
net = dlnetwork(lgraph);

% Training parameters
numEpochs = 100;
learnRate = 1e-3;
miniBatchSize = 8;

% Create minibatch queue
mbq = minibatchqueue(trainDs, ...
    'MiniBatchSize', miniBatchSize, ...
    'MiniBatchFormat', {'SSCB', 'SSCB'}, ...
    'OutputAsDlarray', [true, true]);

% Initialize Adam state
[avgGrad, avgSqGrad] = deal([]);
iteration = 0;

% Training loop
for epoch = 1:numEpochs
    shuffle(mbq);

    while hasdata(mbq)
        iteration = iteration + 1;
        [X, T] = next(mbq);

        % One-hot encode targets if needed
        T = onehotencode(T, 3, 'ClassNames', classNames);

        % Compute loss and gradients
        [loss, gradients, state] = dlfeval(@modelLoss, net, X, T);
        net.State = state;

        % Update parameters
        [net, avgGrad, avgSqGrad] = adamupdate(net, gradients, ...
            avgGrad, avgSqGrad, iteration, learnRate);

        % Display progress
        if mod(iteration, 10) == 0
            fprintf('Epoch %d, Iteration %d, Loss: %.4f\n', ...
                epoch, iteration, extractdata(loss));
        end
    end
end
```

## Inference

### Single Image Segmentation

```matlab
% Load and preprocess
img = imread('test_image.png');
img = im2single(img);
img = imresize(img, [256 256]);

% Segment
mask = semanticseg(img, net);

% Visualize
figure;
subplot(1,2,1); imshow(img); title('Input');
subplot(1,2,2); imshow(labeloverlay(img, mask)); title('Segmentation');
```

### Batch Segmentation

```matlab
% Segment multiple images
testDs = imageDatastore('test_images/');
testDs = transform(testDs, @(x) imresize(im2single(x), [256 256]));

pxdsResults = semanticseg(testDs, net, ...
    'MiniBatchSize', 16, ...
    'WriteLocation', 'results/', ...
    'Verbose', true);
```

### Patch-Based Segmentation (Large Images)

```matlab
% For images larger than GPU memory
function mask = patchBasedSegmentation(img, net, patchSize, overlap)
    [H, W, ~] = size(img);
    mask = zeros(H, W, 'categorical');

    stride = patchSize - overlap;
    counts = zeros(H, W);  % For averaging overlapping predictions

    for y = 1:stride:(H - patchSize + 1)
        for x = 1:stride:(W - patchSize + 1)
            patch = img(y:y+patchSize-1, x:x+patchSize-1, :);
            patchMask = semanticseg(patch, net);

            % Accumulate (simple for categorical, weighted for probabilities)
            mask(y:y+patchSize-1, x:x+patchSize-1) = patchMask;
            counts(y:y+patchSize-1, x:x+patchSize-1) = ...
                counts(y:y+patchSize-1, x:x+patchSize-1) + 1;
        end
    end
end
```

## Evaluation

### Metrics Computation

```matlab
% Evaluate on test set
pxdsResults = semanticseg(testDs, net, ...
    'MiniBatchSize', 8);

metrics = evaluateSemanticSegmentation(pxdsResults, pxdsTest);

% Display results
disp('Class-wise metrics:');
disp(metrics.ClassMetrics);

disp('Dataset metrics:');
disp(metrics.DataSetMetrics);

% Key metrics:
% - GlobalAccuracy: Overall pixel accuracy
% - MeanAccuracy: Mean of per-class accuracies
% - MeanIoU: Mean Intersection-over-Union (most important)
% - WeightedIoU: IoU weighted by class frequency
```

### IoU Visualization

```matlab
% Plot IoU per class
classNames = metrics.ClassMetrics.Properties.RowNames;
iouScores = metrics.ClassMetrics.IoU;

bar(categorical(classNames), iouScores);
ylabel('IoU');
title('Per-Class IoU');
ylim([0 1]);

% Add mean IoU line
hold on;
yline(metrics.DataSetMetrics.MeanIoU, 'r--', sprintf('Mean IoU: %.3f', ...
    metrics.DataSetMetrics.MeanIoU));
```

### Confusion Matrix

```matlab
% Normalized confusion matrix
confMat = metrics.NormalizedConfusionMatrix.Variables;
figure;
confusionchart(confMat, classNames, ...
    'Normalization', 'row-normalized', ...
    'Title', 'Normalized Confusion Matrix');
```

## Complete Medical Segmentation Example

```matlab
% Brain tumor segmentation from MRI
% Assume data: images/ and masks/ folders

% 1. Load data
imds = imageDatastore('images/', 'FileExtensions', '.png');
classNames = ["Background", "Tumor"];
pixelLabelIDs = [0, 255];
pxds = pixelLabelDatastore('masks/', classNames, pixelLabelIDs);

% 2. Split data
[trainImds, valImds, testImds] = splitEachLabel(imds, 0.7, 0.15, 0.15);
[trainPxds, valPxds, testPxds] = splitEachLabel(pxds, 0.7, 0.15, 0.15);

trainDs = combine(trainImds, trainPxds);
valDs = combine(valImds, valPxds);

% 3. Data augmentation
function data = augmentData(data)
    img = data{1};
    mask = data{2};

    % Resize
    img = imresize(img, [256 256]);
    mask = imresize(mask, [256 256], 'nearest');

    % Random augmentation
    if rand > 0.5
        img = fliplr(img);
        mask = fliplr(mask);
    end
    angle = (rand - 0.5) * 20;
    img = imrotate(img, angle, 'bilinear', 'crop');
    mask = imrotate(mask, angle, 'nearest', 'crop');

    data = {im2single(img), mask};
end

trainDs = transform(trainDs, @augmentData);
valDs = transform(valDs, @(d) {imresize(im2single(d{1}), [256 256]), ...
    imresize(d{2}, [256 256], 'nearest')});

% 4. Create U-Net with class weights
tbl = countEachLabel(pxds);
classWeights = 1 ./ tbl.PixelCount;
classWeights = classWeights / sum(classWeights) * 2;

lgraph = unetLayers([256 256 1], 2, ...
    'EncoderDepth', 4, ...
    'NumFirstEncoderFilters', 32);

pxLayer = pixelClassificationLayer('Name', 'output', ...
    'Classes', classNames, ...
    'ClassWeights', classWeights);
lgraph = replaceLayer(lgraph, 'Segmentation-Layer', pxLayer);

% 5. Train
options = trainingOptions('adam', ...
    'MaxEpochs', 50, ...
    'MiniBatchSize', 8, ...
    'InitialLearnRate', 1e-3, ...
    'ValidationData', valDs, ...
    'ValidationFrequency', 50, ...
    'Plots', 'training-progress', ...
    'ExecutionEnvironment', 'gpu');

net = trainNetwork(trainDs, lgraph, options);

% 6. Evaluate
testDs = combine(testImds, testPxds);
testDs = transform(testDs, @(d) {imresize(im2single(d{1}), [256 256]), ...
    imresize(d{2}, [256 256], 'nearest')});

pxdsResults = semanticseg(testDs, net, 'MiniBatchSize', 8);
metrics = evaluateSemanticSegmentation(pxdsResults, testPxds);

fprintf('Mean IoU: %.4f\n', metrics.DataSetMetrics.MeanIoU);
fprintf('Tumor IoU: %.4f\n', metrics.ClassMetrics.IoU('Tumor'));
```

---

*Source: Deep Learning Toolbox Documentation - Semantic Segmentation (R2025b)*
