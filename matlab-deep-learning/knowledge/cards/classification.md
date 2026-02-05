# Image Classification & Transfer Learning

> ⚠️ **R2024b+ API Changes:** `trainNetwork` → `trainnet`, `classificationLayer` → use `trainnet` with `"crossentropy"` loss. Code below shows legacy syntax for reference; see SKILL.md for modern equivalents.

Transfer learning is the most effective approach for medical image classification with limited data.

## Pretrained Networks

| Network | Function | Input Size | Params | Top-1 Acc | Best For |
|---------|----------|------------|--------|-----------|----------|
| ResNet-50 | `resnet50` | 224×224 | 25.6M | 76.1% | General purpose |
| ResNet-101 | `resnet101` | 224×224 | 44.5M | 77.4% | Higher capacity |
| VGG-16 | `vgg16` | 224×224 | 138M | 71.5% | Feature extraction |
| VGG-19 | `vgg19` | 224×224 | 143M | 72.4% | Feature extraction |
| EfficientNet-B0 | `efficientnetb0` | 224×224 | 5.3M | 77.1% | Efficient inference |
| Inception-v3 | `inceptionv3` | 299×299 | 23.8M | 77.9% | Fine details |
| DenseNet-201 | `densenet201` | 224×224 | 20M | 77.0% | Dense features |
| MobileNet-v2 | `mobilenetv2` | 224×224 | 3.5M | 71.8% | Mobile/edge |
| NASNet-Large | `nasnetlarge` | 331×331 | 88.9M | 82.5% | Highest accuracy |

## Transfer Learning Strategies

### Strategy 1: Feature Extraction (Frozen Backbone)

```matlab
% Use pretrained network as fixed feature extractor
net = resnet50;
lgraph = layerGraph(net);

% Freeze all layers except final
for i = 1:numel(lgraph.Layers)-3
    if isprop(lgraph.Layers(i), 'WeightLearnRateFactor')
        lgraph = setLearnRateFactor(lgraph, lgraph.Layers(i).Name, ...
            'Weights', 0, 'Bias', 0);
    end
end

% Replace classification head
numClasses = 4;
lgraph = removeLayers(lgraph, {'fc1000', 'fc1000_softmax', 'ClassificationLayer_fc1000'});
newLayers = [
    fullyConnectedLayer(numClasses, 'Name', 'fc_new', ...
        'WeightLearnRateFactor', 10, 'BiasLearnRateFactor', 10)
    softmaxLayer('Name', 'softmax_new')
    classificationLayer('Name', 'output')];
lgraph = addLayers(lgraph, newLayers);
lgraph = connectLayers(lgraph, 'avg_pool', 'fc_new');

% Train only new layers
options = trainingOptions('adam', ...
    'MaxEpochs', 5, ...
    'MiniBatchSize', 32, ...
    'InitialLearnRate', 1e-3);  % Higher LR for new layers
net = trainNetwork(trainDs, lgraph, options);
```

### Strategy 2: Fine-Tuning (Gradual Unfreezing)

```matlab
% Two-phase training: first head, then backbone
net = resnet50;
lgraph = layerGraph(net);

% Phase 1: Train head only (as above)
% ... (frozen backbone training)

% Phase 2: Unfreeze and fine-tune entire network
lgraph = layerGraph(trainedNet);

% Lower learning rate for pretrained layers
options = trainingOptions('adam', ...
    'MaxEpochs', 10, ...
    'MiniBatchSize', 16, ...
    'InitialLearnRate', 1e-5, ...  % Very low for fine-tuning
    'LearnRateSchedule', 'piecewise', ...
    'LearnRateDropFactor', 0.1, ...
    'LearnRateDropPeriod', 5);

netFineTuned = trainNetwork(trainDs, lgraph, options);
```

### Strategy 3: Discriminative Learning Rates

```matlab
% Different learning rates for different layer depths
net = resnet50;
lgraph = layerGraph(net);

% Get layer names by depth
layerNames = {lgraph.Layers.Name};
numLayers = numel(layerNames);

% Set learning rates: lower for early layers, higher for later
for i = 1:numLayers
    layer = lgraph.Layers(i);
    if isprop(layer, 'WeightLearnRateFactor')
        depth = i / numLayers;  % 0 to 1
        lrFactor = 0.1 + 0.9 * depth;  % 0.1 to 1.0
        lgraph = setLearnRateFactor(lgraph, layer.Name, 'Weights', lrFactor);
    end
end
```

## Data Preparation

### ImageDatastore for Classification

```matlab
% Folder structure: data/class1/, data/class2/, etc.
imds = imageDatastore('data/', ...
    'IncludeSubfolders', true, ...
    'LabelSource', 'foldernames');

% Check class distribution
disp(countEachLabel(imds));

% Split into train/validation/test
[trainImds, valImds, testImds] = splitEachLabel(imds, 0.7, 0.15, 0.15, 'randomized');
```

### Data Augmentation for Medical Images

```matlab
% Medical-appropriate augmentation (conservative)
augmenter = imageDataAugmenter(...
    'RandRotation', [-15 15], ...           % Small rotations
    'RandXReflection', true, ...            % Horizontal flip (if appropriate)
    'RandYReflection', false, ...           % Usually NOT for medical
    'RandXScale', [0.9 1.1], ...            % Slight scaling
    'RandYScale', [0.9 1.1], ...
    'RandXTranslation', [-10 10], ...       % Small translations
    'RandYTranslation', [-10 10]);

% Create augmented datastore
inputSize = [224 224 3];
trainDs = augmentedImageDatastore(inputSize, trainImds, ...
    'DataAugmentation', augmenter, ...
    'ColorPreprocessing', 'gray2rgb');  % For grayscale medical images

valDs = augmentedImageDatastore(inputSize, valImds, ...
    'ColorPreprocessing', 'gray2rgb');  % No augmentation for validation
```

### Handling Grayscale Images

```matlab
% Option 1: Replicate to 3 channels
augDs = augmentedImageDatastore(inputSize, imds, ...
    'ColorPreprocessing', 'gray2rgb');

% Option 2: Modify network input layer
lgraph = layerGraph(resnet50);
newInput = imageInputLayer([224 224 1], 'Name', 'input_gray', ...
    'Normalization', 'zscore');
lgraph = replaceLayer(lgraph, 'input_1', newInput);

% Modify first conv layer to accept 1 channel
firstConv = lgraph.Layers(2);  % Usually conv1
newConv = convolution2dLayer(firstConv.FilterSize, ...
    firstConv.NumFilters, ...
    'Stride', firstConv.Stride, ...
    'Padding', firstConv.PaddingSize, ...
    'Name', firstConv.Name);
lgraph = replaceLayer(lgraph, firstConv.Name, newConv);
% Note: This resets weights, so fine-tuning is essential
```

## Class Imbalance Handling

### Oversampling Minority Classes

```matlab
% Replicate minority class samples
counts = countEachLabel(imds);
maxCount = max(counts.Count);

% Oversample
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

### Class Weights in Loss

```matlab
% Compute class weights (inverse frequency)
counts = countEachLabel(imds);
totalSamples = sum(counts.Count);
classWeights = totalSamples ./ (numel(counts.Count) * counts.Count);
classWeights = classWeights / sum(classWeights) * numel(classWeights);

% Use weighted classification layer
wclayer = classificationLayer('Classes', counts.Label, ...
    'ClassWeights', classWeights, ...
    'Name', 'weighted_output');

% Replace final layer
lgraph = replaceLayer(lgraph, 'output', wclayer);
```

### Focal Loss (Custom)

```matlab
% Focal loss for hard examples
function loss = focalLoss(Y, T, gamma, alpha)
    % Y: predictions (after softmax)
    % T: targets (one-hot)
    % gamma: focusing parameter (typically 2)
    % alpha: class weights

    pt = sum(Y .* T, 1);  % Probability of true class
    loss = -alpha .* (1 - pt).^gamma .* log(pt + 1e-8);
    loss = mean(loss, 'all');
end
```

## Evaluation Metrics

### Confusion Matrix and Metrics

```matlab
% Predict on test set
[YPred, scores] = classify(net, testDs);
YTest = testImds.Labels;

% Confusion matrix
confMat = confusionmat(YTest, YPred);
confusionchart(YTest, YPred);

% Per-class metrics
accuracy = sum(diag(confMat)) / sum(confMat, 'all');
precision = diag(confMat) ./ sum(confMat, 2);
recall = diag(confMat) ./ sum(confMat, 1)';
f1 = 2 * precision .* recall ./ (precision + recall);

fprintf('Overall Accuracy: %.2f%%\n', accuracy * 100);
fprintf('Per-class F1: %s\n', mat2str(f1, 3));
```

### ROC Curve and AUC

```matlab
% For binary classification
[~, scores] = classify(net, testDs);
positiveScores = scores(:, 2);  % Score for positive class
trueLabels = double(testImds.Labels == 'positive');

[X, Y, T, AUC] = perfcurve(trueLabels, positiveScores, 1);
plot(X, Y);
xlabel('False Positive Rate');
ylabel('True Positive Rate');
title(sprintf('ROC Curve (AUC = %.3f)', AUC));

% For multiclass: one-vs-all ROC
classNames = categories(testImds.Labels);
figure;
hold on;
for i = 1:numel(classNames)
    [X, Y, ~, auc] = perfcurve(testImds.Labels, scores(:,i), classNames{i});
    plot(X, Y, 'DisplayName', sprintf('%s (AUC=%.3f)', classNames{i}, auc));
end
legend('Location', 'southeast');
```

## Complete Medical Image Classification Example

```matlab
% X-ray pneumonia classification
% Folder structure: data/normal/, data/pneumonia/

% 1. Load data
imds = imageDatastore('chest_xray/', ...
    'IncludeSubfolders', true, ...
    'LabelSource', 'foldernames');

% 2. Split data
[trainImds, valImds, testImds] = splitEachLabel(imds, 0.7, 0.15, 'randomized');

% 3. Create augmented datastores
inputSize = [224 224 3];
augmenter = imageDataAugmenter(...
    'RandRotation', [-10 10], ...
    'RandXReflection', true, ...
    'RandXScale', [0.95 1.05]);

trainDs = augmentedImageDatastore(inputSize, trainImds, ...
    'DataAugmentation', augmenter, ...
    'ColorPreprocessing', 'gray2rgb');
valDs = augmentedImageDatastore(inputSize, valImds, ...
    'ColorPreprocessing', 'gray2rgb');

% 4. Setup transfer learning
net = resnet50;
lgraph = layerGraph(net);
lgraph = removeLayers(lgraph, {'fc1000', 'fc1000_softmax', 'ClassificationLayer_fc1000'});
newLayers = [
    fullyConnectedLayer(2, 'Name', 'fc_binary')
    softmaxLayer('Name', 'softmax')
    classificationLayer('Name', 'output')];
lgraph = addLayers(lgraph, newLayers);
lgraph = connectLayers(lgraph, 'avg_pool', 'fc_binary');

% 5. Training options
options = trainingOptions('adam', ...
    'MaxEpochs', 15, ...
    'MiniBatchSize', 32, ...
    'InitialLearnRate', 1e-4, ...
    'LearnRateSchedule', 'piecewise', ...
    'LearnRateDropFactor', 0.1, ...
    'LearnRateDropPeriod', 10, ...
    'ValidationData', valDs, ...
    'ValidationFrequency', 50, ...
    'Plots', 'training-progress', ...
    'ExecutionEnvironment', 'gpu');

% 6. Train
trainedNet = trainNetwork(trainDs, lgraph, options);

% 7. Evaluate
testDs = augmentedImageDatastore(inputSize, testImds, ...
    'ColorPreprocessing', 'gray2rgb');
[YPred, scores] = classify(trainedNet, testDs);

accuracy = mean(YPred == testImds.Labels);
fprintf('Test Accuracy: %.2f%%\n', accuracy * 100);

confusionchart(testImds.Labels, YPred);
```

## Common Issues

### Issue: Poor convergence with pretrained network

```matlab
% Solution: Check input preprocessing
% ImageNet networks expect specific normalization
img = imread('test.png');
img = im2single(img);
img = imresize(img, [224 224]);

% ImageNet mean/std normalization
meanRGB = [0.485, 0.456, 0.406];
stdRGB = [0.229, 0.224, 0.225];
img = (img - reshape(meanRGB, 1, 1, 3)) ./ reshape(stdRGB, 1, 1, 3);
```

### Issue: Overfitting on small dataset

```matlab
% Solutions:
% 1. Use feature extraction (freeze backbone)
% 2. Add dropout before final FC
lgraph = addLayers(lgraph, dropoutLayer(0.5, 'Name', 'dropout'));
lgraph = connectLayers(lgraph, 'avg_pool', 'dropout');
lgraph = connectLayers(lgraph, 'dropout', 'fc_new');

% 3. Stronger augmentation
% 4. Early stopping with validation monitoring
options = trainingOptions('adam', ...
    'ValidationPatience', 5, ...  % Stop if no improvement for 5 epochs
    'OutputFcn', @(info) stopIfAccuracyNotImproving(info, 5));
```

### Issue: Class imbalance causing biased predictions

```matlab
% Check if model predicts majority class for everything
unique(YPred)  % Should show all classes

% Solutions:
% 1. Use class weights (shown above)
% 2. Oversample minority classes
% 3. Use focal loss
% 4. Stratified sampling in datastore
```

---

*Source: Deep Learning Toolbox Documentation - Transfer Learning (R2025b)*
