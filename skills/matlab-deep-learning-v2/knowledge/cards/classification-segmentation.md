# Classification & Semantic Segmentation

Focused reference for image classification and semantic segmentation. Covers transfer learning strategies, U-Net/DeepLabv3+ configuration, loss functions, and evaluation -- emphasizing gotchas and medical-specific patterns the model may not handle correctly on its own.

## Transfer Learning Strategies

### Feature Extraction (Frozen Backbone)

```matlab
net = resnet50;
lgraph = layerGraph(net);

% Freeze all layers except final
for i = 1:numel(lgraph.Layers)-3
    if isprop(lgraph.Layers(i), 'WeightLearnRateFactor')
        lgraph = setLearnRateFactor(lgraph, lgraph.Layers(i).Name, ...
            'Weights', 0, 'Bias', 0);
    end
end

% Replace classification head (modern API -- no classificationLayer)
numClasses = 4;
lgraph = removeLayers(lgraph, {'fc1000', 'fc1000_softmax', 'ClassificationLayer_fc1000'});
newLayers = [
    fullyConnectedLayer(numClasses, 'Name', 'fc_new', ...
        'WeightLearnRateFactor', 10, 'BiasLearnRateFactor', 10)
    softmaxLayer('Name', 'softmax_new')];
lgraph = addLayers(lgraph, newLayers);
lgraph = connectLayers(lgraph, 'avg_pool', 'fc_new');

net = dlnetwork(lgraph);
net = trainnet(trainDs, net, "crossentropy", opts);
```

### Discriminative Learning Rates

```matlab
% Different learning rates for different layer depths
layerNames = {lgraph.Layers.Name};
numLayers = numel(layerNames);

for i = 1:numLayers
    layer = lgraph.Layers(i);
    if isprop(layer, 'WeightLearnRateFactor')
        depth = i / numLayers;  % 0 to 1
        lrFactor = 0.1 + 0.9 * depth;  % 0.1 to 1.0
        lgraph = setLearnRateFactor(lgraph, layer.Name, 'Weights', lrFactor);
    end
end
```

### Handling Grayscale Medical Images

```matlab
% Option 1: Replicate to 3 channels (simplest)
augDs = augmentedImageDatastore(inputSize, imds, ...
    'ColorPreprocessing', 'gray2rgb');

% Option 2: Modify network input layer (preserves pretrained weights better)
lgraph = layerGraph(resnet50);
newInput = imageInputLayer([224 224 1], 'Name', 'input_gray', ...
    'Normalization', 'zscore');
lgraph = replaceLayer(lgraph, 'input_1', newInput);
% Note: First conv layer resets weights -- fine-tuning essential
```

## U-Net Configuration

### CRITICAL: NumFirstEncoderFilters Default

```matlab
% Default NumFirstEncoderFilters is 64 (NOT 32)
net = unet([256 256 1], 2);  % Modern API, returns dlnetwork

% Customized U-Net
net = unet([256 256 1], 2, ...
    EncoderDepth=4, ...
    NumFirstEncoderFilters=64, ...  % Default is 64
    FilterSize=3, ...
    ConvolutionPadding='same');
```

### DeepLabv3+

```matlab
net = deeplabv3plus([512 512 3], 5, 'resnet50', ...
    DownsamplingFactor=16);

% For medical grayscale: modify input layer
lgraph = layerGraph(net);
lgraph = replaceLayer(lgraph, lgraph.Layers(1).Name, ...
    imageInputLayer([512 512 1], 'Name', 'input', 'Normalization', 'zscore'));
net = dlnetwork(lgraph);
```

## Loss Functions for Segmentation

### Dice Loss (Handles Class Imbalance)

```matlab
function loss = diceLoss(Y, T)
    smooth = 1e-6;
    intersection = sum(Y .* T, [1 2]);
    cardinality = sum(Y.^2, [1 2]) + sum(T.^2, [1 2]);
    dice = (2 * intersection + smooth) ./ (cardinality + smooth);
    loss = 1 - mean(dice, 'all');
end
```

### Tversky Loss (Control FP/FN Trade-Off)

```matlab
function loss = tverskyLoss(Y, T, alpha, beta)
    % alpha: weight for false positives
    % beta: weight for false negatives
    smooth = 1e-6;
    TP = sum(Y .* T, [1 2]);
    FP = sum(Y .* (1 - T), [1 2]);
    FN = sum((1 - Y) .* T, [1 2]);
    tversky = (TP + smooth) ./ (TP + alpha*FP + beta*FN + smooth);
    loss = 1 - mean(tversky, 'all');
end
```

### Combined Dice + Cross-Entropy

```matlab
function loss = combinedLoss(Y, T, alpha)
    ce = crossentropy(Y, T);
    dice = diceLoss(Y, T);
    loss = alpha * dice + (1 - alpha) * ce;
end
```

### Focal Loss (Hard Examples)

```matlab
function loss = focalLoss(Y, T, gamma)
    pt = sum(Y .* T, 3);
    loss = -mean((1 - pt).^gamma .* log(pt + 1e-8), 'all');
end
```

### Class Weights for Imbalanced Segmentation

```matlab
tbl = countEachLabel(pxds);
totalPixels = sum(tbl.PixelCount);
classWeights = totalPixels ./ (numel(tbl.Name) * tbl.PixelCount);
classWeights = classWeights / sum(classWeights) * numel(classWeights);
```

## Class Imbalance for Classification

```matlab
% Focal loss for hard examples (classification)
function loss = focalLossClassification(Y, T, gamma, alpha)
    pt = sum(Y .* T, 1);
    loss = -alpha .* (1 - pt).^gamma .* log(pt + 1e-8);
    loss = mean(loss, 'all');
end

% Oversampling minority classes
counts = countEachLabel(imds);
maxCount = max(counts.Count);
imdsBalanced = imds;
for i = 1:height(counts)
    if counts.Count(i) < maxCount
        classIdx = find(imds.Labels == counts.Label(i));
        numToAdd = maxCount - counts.Count(i);
        addIdx = classIdx(randi(numel(classIdx), numToAdd, 1));
        imdsBalanced.Files = [imdsBalanced.Files; imds.Files(addIdx)];
        imdsBalanced.Labels = [imdsBalanced.Labels; imds.Labels(addIdx)];
    end
end
```

## Segmentation Augmentation (CRITICAL: Must Apply Same Transform to Image AND Mask)

```matlab
function data = augmentSegmentation(data)
    img = data{1};
    mask = data{2};

    if rand > 0.5
        angle = (rand - 0.5) * 30;
        img = imrotate(img, angle, 'bilinear', 'crop');
        mask = imrotate(mask, angle, 'nearest', 'crop');  % NEAREST for masks!
    end

    if rand > 0.5
        img = fliplr(img);
        mask = fliplr(mask);
    end

    % Intensity augmentation (image only!)
    if rand > 0.5
        img = img * (0.8 + rand * 0.4);
    end

    data = {im2single(img), mask};
end
```

## Evaluation

### Segmentation Metrics

```matlab
pxdsResults = semanticseg(testDs, net, 'MiniBatchSize', 8);
metrics = evaluateSemanticSegmentation(pxdsResults, pxdsTest);

% Key metrics:
% - MeanIoU: Most important for segmentation
% - GlobalAccuracy, MeanAccuracy, WeightedIoU
disp(metrics.ClassMetrics);
disp(metrics.DataSetMetrics);
```

### Classification Metrics

```matlab
[YPred, scores] = classify(net, testDs);
confusionchart(YTest, YPred);
accuracy = mean(YPred == YTest);

% ROC/AUC (binary)
[X, Y, ~, AUC] = perfcurve(trueLabels, positiveScores, 1);
```

### Patch-Based Segmentation (Large Images)

```matlab
function mask = patchBasedSegmentation(img, net, patchSize, overlap)
    [H, W, ~] = size(img);
    mask = zeros(H, W, 'categorical');
    stride = patchSize - overlap;

    for y = 1:stride:(H - patchSize + 1)
        for x = 1:stride:(W - patchSize + 1)
            patch = img(y:y+patchSize-1, x:x+patchSize-1, :);
            patchMask = semanticseg(patch, net);
            mask(y:y+patchSize-1, x:x+patchSize-1) = patchMask;
        end
    end
end
```

### Common Issue: Poor Convergence with Pretrained Network

```matlab
% ImageNet networks expect specific normalization
img = im2single(img);
img = imresize(img, [224 224]);
meanRGB = [0.485, 0.456, 0.406];
stdRGB = [0.229, 0.224, 0.225];
img = (img - reshape(meanRGB, 1, 1, 3)) ./ reshape(stdRGB, 1, 1, 3);
```

---

*Verified against MATLAB R2025b*
