# Deep Learning: Semantic Segmentation

> ⚠️ **R2024b+ API Changes:** `unetLayers` → `unet`, `trainNetwork` → `trainnet`. See Deep Learning Toolbox SKILL.md for modern syntax.

Deep learning approaches for image segmentation using MATLAB's Deep Learning Toolbox integration with Image Processing Toolbox.

## Key Functions

| Function | Purpose |
|----------|---------|
| `semanticseg` | Apply trained network to segment images |
| `unetLayers` | Create U-Net architecture |
| `deeplabv3plusLayers` | Create DeepLabv3+ architecture |
| `segnetLayers` | Create SegNet architecture |
| `pixelLabelDatastore` | Datastore for labeled training data |
| `trainNetwork` | Train segmentation network |

## Using Pre-trained Networks

### Basic Inference with `semanticseg`

```matlab
% Load pre-trained network
net = load('trained_unet.mat').net;

% Read and preprocess image
img = imread('medical_image.png');
img = imresize(img, net.Layers(1).InputSize(1:2));

% Normalize (CRITICAL for DL)
img = im2single(img);
if size(img, 3) == 1
    img = repmat(img, [1 1 3]);  % Expand grayscale to 3 channels
end

% Segment
segmented = semanticseg(img, net);

% Display
figure;
subplot(1,2,1); imshow(img); title('Input');
subplot(1,2,2); imshow(labeloverlay(img, segmented)); title('Segmentation');
```

### Batch Processing
```matlab
% Process multiple images efficiently
imds = imageDatastore('test_images/*.png');

% Resize all images to network input size
imds.ReadFcn = @(x) imresize(im2single(imread(x)), [256 256]);

% Segment all
results = semanticseg(imds, net, ...
    'MiniBatchSize', 8, ...
    'WriteLocation', 'output_folder');
```

## Creating U-Net Architecture

U-Net is the standard architecture for medical image segmentation.

```matlab
function lgraph = create_unet(inputSize, numClasses)
    % Create U-Net for semantic segmentation
    %
    % inputSize  - [height, width, channels]
    % numClasses - Number of segmentation classes

    % Option 1: Use built-in unetLayers (R2020a+)
    lgraph = unetLayers(inputSize, numClasses, ...
        'EncoderDepth', 4, ...
        'NumFirstEncoderFilters', 32);

    % Option 2: Manual construction for more control
    % (See detailed example below)
end
```

### Custom U-Net with More Control
```matlab
function lgraph = create_custom_unet(inputSize, numClasses)
    % Manual U-Net construction for full control

    % Encoder (contracting path)
    layers = [
        imageInputLayer(inputSize, 'Name', 'input', 'Normalization', 'none')

        % Block 1
        convolution2dLayer(3, 64, 'Padding', 'same', 'Name', 'enc1_conv1')
        batchNormalizationLayer('Name', 'enc1_bn1')
        reluLayer('Name', 'enc1_relu1')
        convolution2dLayer(3, 64, 'Padding', 'same', 'Name', 'enc1_conv2')
        batchNormalizationLayer('Name', 'enc1_bn2')
        reluLayer('Name', 'enc1_relu2')
        maxPooling2dLayer(2, 'Stride', 2, 'Name', 'enc1_pool')

        % Block 2
        convolution2dLayer(3, 128, 'Padding', 'same', 'Name', 'enc2_conv1')
        batchNormalizationLayer('Name', 'enc2_bn1')
        reluLayer('Name', 'enc2_relu1')
        convolution2dLayer(3, 128, 'Padding', 'same', 'Name', 'enc2_conv2')
        batchNormalizationLayer('Name', 'enc2_bn2')
        reluLayer('Name', 'enc2_relu2')
        maxPooling2dLayer(2, 'Stride', 2, 'Name', 'enc2_pool')

        % Block 3 (bottleneck)
        convolution2dLayer(3, 256, 'Padding', 'same', 'Name', 'bottleneck_conv1')
        batchNormalizationLayer('Name', 'bottleneck_bn1')
        reluLayer('Name', 'bottleneck_relu1')
        convolution2dLayer(3, 256, 'Padding', 'same', 'Name', 'bottleneck_conv2')
        batchNormalizationLayer('Name', 'bottleneck_bn2')
        reluLayer('Name', 'bottleneck_relu2')

        % Decoder Block 1
        transposedConv2dLayer(2, 128, 'Stride', 2, 'Name', 'dec1_upconv')
    ];

    lgraph = layerGraph(layers);

    % Add skip connections (requires layerGraph manipulation)
    % ... concatenation layers connecting encoder to decoder ...

    % Final classification layer
    finalLayers = [
        convolution2dLayer(1, numClasses, 'Name', 'final_conv')
        softmaxLayer('Name', 'softmax')
        pixelClassificationLayer('Name', 'output')
    ];

    lgraph = addLayers(lgraph, finalLayers);
    lgraph = connectLayers(lgraph, 'dec1_upconv', 'final_conv');
end
```

## Training Pipeline

### Prepare Training Data
```matlab
% Image datastore
imds = imageDatastore('training_images/*.png');

% Pixel label datastore (ground truth masks)
classNames = ["background", "tumor", "normal_tissue"];
labelIDs = [0, 1, 2];
pxds = pixelLabelDatastore('labels/*.png', classNames, labelIDs);

% Combine into single datastore
trainingData = combine(imds, pxds);

% Check class balance
tbl = countEachLabel(pxds);
disp(tbl);
```

### Data Augmentation
```matlab
% Create augmenter
augmenter = imageDataAugmenter(...
    'RandXReflection', true, ...
    'RandYReflection', true, ...
    'RandRotation', [-20, 20], ...
    'RandScale', [0.8, 1.2], ...
    'RandXTranslation', [-10, 10], ...
    'RandYTranslation', [-10, 10]);

% Create augmented training datastore
inputSize = [256 256 3];
augmentedTrainingData = pixelLabelImageDatastore(imds, pxds, ...
    'DataAugmentation', augmenter, ...
    'OutputSize', inputSize);
```

### Handle Class Imbalance
```matlab
% Calculate class weights (inverse frequency)
tbl = countEachLabel(pxds);
totalPixels = sum(tbl.PixelCount);
classWeights = totalPixels ./ tbl.PixelCount;
classWeights = classWeights / sum(classWeights);  % Normalize

% Use in training
pxLayer = pixelClassificationLayer('Classes', classNames, ...
    'ClassWeights', classWeights, ...
    'Name', 'output');
```

### Training Options
```matlab
options = trainingOptions('adam', ...
    'InitialLearnRate', 1e-3, ...
    'LearnRateSchedule', 'piecewise', ...
    'LearnRateDropFactor', 0.5, ...
    'LearnRateDropPeriod', 10, ...
    'MaxEpochs', 50, ...
    'MiniBatchSize', 8, ...
    'Shuffle', 'every-epoch', ...
    'ValidationData', validationData, ...
    'ValidationFrequency', 50, ...
    'Plots', 'training-progress', ...
    'Verbose', true, ...
    'ExecutionEnvironment', 'auto');  % Uses GPU if available

% Train
[net, info] = trainNetwork(augmentedTrainingData, lgraph, options);

% Save
save('trained_segmentation_net.mat', 'net', 'info');
```

## Patch-Based Training for Large Images

For histology and other large images that don't fit in memory:

```matlab
function train_with_patches(imageFolder, labelFolder, patchSize, numClasses)
    % Train on patches extracted from large images

    % Create blocked image datastores
    bimds = blockedImageDatastore(imageFolder, 'BlockSize', patchSize);
    bpxds = blockedImageDatastore(labelFolder, 'BlockSize', patchSize);

    % Or use randomPatchExtractionDatastore
    imds = imageDatastore(imageFolder);
    pxds = pixelLabelDatastore(labelFolder, classNames, labelIDs);

    patchDs = randomPatchExtractionDatastore(imds, pxds, patchSize, ...
        'PatchesPerImage', 16);  % 16 random patches per image

    % Create network for patch size
    lgraph = unetLayers([patchSize 3], numClasses);

    % Train
    options = trainingOptions('adam', ...
        'MaxEpochs', 30, ...
        'MiniBatchSize', 4);

    net = trainNetwork(patchDs, lgraph, options);
end
```

### Inference on Large Images
```matlab
function segmented = segment_large_image(img, net, patchSize, overlap)
    % Segment large image using overlapping patches

    arguments
        img
        net
        patchSize = [256 256]
        overlap = 32  % Overlap to reduce edge artifacts
    end

    [H, W, C] = size(img);
    segmented = zeros(H, W, 'uint8');
    counts = zeros(H, W);  % For averaging overlapping regions

    stepSize = patchSize - overlap;

    for y = 1:stepSize(1):H
        for x = 1:stepSize(2):W
            % Extract patch
            y_end = min(y + patchSize(1) - 1, H);
            x_end = min(x + patchSize(2) - 1, W);

            patch = img(y:y_end, x:x_end, :);

            % Pad if necessary
            if size(patch, 1) < patchSize(1) || size(patch, 2) < patchSize(2)
                patch = padarray(patch, ...
                    [patchSize(1)-size(patch,1), patchSize(2)-size(patch,2)], ...
                    0, 'post');
            end

            % Segment patch
            patch = im2single(patch);
            seg_patch = semanticseg(patch, net);
            seg_patch = uint8(seg_patch);

            % Place in output (crop if padded)
            patch_h = y_end - y + 1;
            patch_w = x_end - x + 1;
            segmented(y:y_end, x:x_end) = seg_patch(1:patch_h, 1:patch_w);
            counts(y:y_end, x:x_end) = counts(y:y_end, x:x_end) + 1;
        end
    end

    % Average overlapping regions (for soft labels)
    % For hard labels, just use the result as-is
end
```

## Evaluation Metrics

```matlab
function metrics = evaluate_segmentation(predicted, groundTruth, classNames)
    % Calculate segmentation metrics

    % Confusion matrix
    confMat = segmentationConfusionMatrix(predicted, groundTruth);

    % Per-class metrics
    metrics.iou = jaccard(predicted, groundTruth);  % IoU per class
    metrics.dice = dice(predicted, groundTruth);    % Dice per class

    % Mean metrics
    metrics.meanIoU = mean(metrics.iou);
    metrics.meanDice = mean(metrics.dice);

    % Pixel accuracy
    metrics.pixelAccuracy = sum(diag(confMat)) / sum(confMat(:));

    % Display
    fprintf('Pixel Accuracy: %.2f%%\n', metrics.pixelAccuracy * 100);
    fprintf('Mean IoU: %.4f\n', metrics.meanIoU);
    fprintf('Mean Dice: %.4f\n', metrics.meanDice);

    for i = 1:length(classNames)
        fprintf('%s - IoU: %.4f, Dice: %.4f\n', ...
            classNames(i), metrics.iou(i), metrics.dice(i));
    end
end
```

## Common Pitfalls

### 1. Incorrect Input Normalization
```matlab
% WRONG: Network expects [0,1] but got [0,255]
img = imread('image.png');  % uint8 [0,255]
seg = semanticseg(img, net);  % Poor results!

% CORRECT: Normalize to single [0,1]
img = im2single(imread('image.png'));
seg = semanticseg(img, net);
```

### 2. Wrong Number of Input Channels
```matlab
% WRONG: Network expects 3 channels but got 1
gray_img = im2single(rgb2gray(imread('image.png')));
seg = semanticseg(gray_img, net);  % Error!

% CORRECT: Expand grayscale to 3 channels
gray_img = repmat(gray_img, [1 1 3]);
seg = semanticseg(gray_img, net);
```

### 3. Class Imbalance (Background Dominates)
```matlab
% WRONG: Training without class weighting
% Result: Network predicts everything as background

% CORRECT: Use class weighting or focal loss
classWeights = [0.1, 5.0, 3.0];  % Low weight for background
pxLayer = pixelClassificationLayer('ClassWeights', classWeights);
```

### 4. Not Using Data Augmentation
```matlab
% Medical imaging datasets are often small
% ALWAYS use augmentation

augmenter = imageDataAugmenter(...
    'RandXReflection', true, ...
    'RandRotation', [-15, 15], ...
    'RandScale', [0.9, 1.1]);
```

## Recommended Architectures

| Architecture | Best For | MATLAB Function |
|--------------|----------|-----------------|
| U-Net | Medical imaging, small datasets | `unetLayers` |
| DeepLabv3+ | General segmentation, accuracy | `deeplabv3plusLayers` |
| SegNet | Real-time applications | `segnetLayers` |
| FCN | Baseline, simple tasks | Manual construction |

---
*Source: MathWorks Deep Learning Toolbox + IPT Documentation (R2024b)*
