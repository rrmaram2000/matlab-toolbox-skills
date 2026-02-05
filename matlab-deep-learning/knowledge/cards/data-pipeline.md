# Data Pipeline & Augmentation

> ⚠️ **R2024b+ API Changes:** `trainNetwork` → `trainnet`. See SKILL.md for modern syntax.

Efficient data loading and augmentation are critical for training deep learning models, especially with large medical imaging datasets.

## Datastores

### imageDatastore

```matlab
% Basic usage - folder structure determines labels
imds = imageDatastore('data/', ...
    'IncludeSubfolders', true, ...
    'LabelSource', 'foldernames');

% With file patterns
imds = imageDatastore('data/', ...
    'FileExtensions', {'.png', '.jpg', '.dcm'}, ...
    'IncludeSubfolders', true);

% Custom label assignment
imds = imageDatastore('images/*.png');
imds.Labels = categorical(readtable('labels.csv').class);

% Check label distribution
tbl = countEachLabel(imds);
disp(tbl);
```

### pixelLabelDatastore (Segmentation)

```matlab
% For semantic segmentation masks
classNames = ["Background", "Tumor", "Healthy"];
pixelLabelIDs = [0, 1, 2];  % Values in mask images

pxds = pixelLabelDatastore('masks/', classNames, pixelLabelIDs);

% Combine with images
imds = imageDatastore('images/');
cds = combine(imds, pxds);

% Check class distribution
tbl = countEachLabel(pxds);
disp(tbl);
```

### boxLabelDatastore (Detection)

```matlab
% Ground truth table: ImagePath | Class1 | Class2 | ...
% Each cell contains Nx4 array of [x y w h] bboxes

load('groundTruth.mat', 'gTruth');
blds = boxLabelDatastore(gTruth(:, 2:end));

% Combine with images
imds = imageDatastore(gTruth.imageFilename);
cds = combine(imds, blds);
```

### Custom Datastore

```matlab
% For custom data formats (e.g., HDF5, MATLAB files)
classdef customDatastore < matlab.io.Datastore & ...
        matlab.io.datastore.Shuffleable

    properties
        Files
        CurrentIndex
    end

    methods
        function ds = customDatastore(folder)
            ds.Files = dir(fullfile(folder, '*.mat'));
            ds.CurrentIndex = 1;
        end

        function tf = hasdata(ds)
            tf = ds.CurrentIndex <= numel(ds.Files);
        end

        function [data, info] = read(ds)
            file = fullfile(ds.Files(ds.CurrentIndex).folder, ...
                           ds.Files(ds.CurrentIndex).name);
            loaded = load(file);
            data = {loaded.image, loaded.label};
            info.Filename = file;
            ds.CurrentIndex = ds.CurrentIndex + 1;
        end

        function reset(ds)
            ds.CurrentIndex = 1;
        end

        function ds = shuffle(ds)
            idx = randperm(numel(ds.Files));
            ds.Files = ds.Files(idx);
        end
    end
end
```

## Combining Datastores

```matlab
% Combine multiple datastores
imds = imageDatastore('images/');
labelDs = arrayDatastore(labels);
cds = combine(imds, labelDs);

% Read returns cell array
data = read(cds);  % {image, label}

% Multiple sources
imds1 = imageDatastore('modality1/');
imds2 = imageDatastore('modality2/');
labelDs = arrayDatastore(labels);
cds = combine(imds1, imds2, labelDs);
data = read(cds);  % {img1, img2, label}
```

## Transform Operations

### Basic Transform

```matlab
% Apply transformation to datastore
function data = preprocessImage(data)
    img = data{1};
    img = imresize(img, [224 224]);
    img = im2single(img);
    data{1} = img;
end

transformedDs = transform(cds, @preprocessImage);
```

### Preprocessing for Different Networks

```matlab
% ImageNet preprocessing (ResNet, VGG, etc.)
function img = preprocessImageNet(img)
    img = imresize(img, [224 224]);
    img = im2single(img);

    % Convert grayscale to RGB
    if size(img, 3) == 1
        img = repmat(img, 1, 1, 3);
    end

    % ImageNet normalization
    meanRGB = [0.485, 0.456, 0.406];
    stdRGB = [0.229, 0.224, 0.225];
    img = (img - reshape(meanRGB, 1, 1, 3)) ./ reshape(stdRGB, 1, 1, 3);
end

% Medical image preprocessing
function img = preprocessMedical(img, modality)
    switch modality
        case 'CT'
            % Window/level
            img = (img - (-100)) / 400;  % Soft tissue window
            img = max(0, min(1, img));
        case 'MRI'
            % Z-score normalization
            mask = img > 0;
            img = (img - mean(img(mask))) / std(img(mask));
            img = img / 4 + 0.5;  % Scale to ~[0,1]
            img = max(0, min(1, img));
        case 'Xray'
            % Histogram equalization
            img = adapthisteq(mat2gray(img));
    end

    img = imresize(img, [256 256]);
    img = im2single(img);
end
```

## Data Augmentation

### imageDataAugmenter (Classification)

```matlab
% Built-in augmenter for classification
augmenter = imageDataAugmenter(...
    'RandRotation', [-15 15], ...           % Rotation ±15°
    'RandXReflection', true, ...            % Horizontal flip
    'RandYReflection', false, ...           % Vertical flip (usually off)
    'RandXScale', [0.9 1.1], ...            % Scale 90-110%
    'RandYScale', [0.9 1.1], ...
    'RandXTranslation', [-10 10], ...       % Translation ±10 pixels
    'RandYTranslation', [-10 10], ...
    'RandXShear', [-5 5], ...               % Shear ±5°
    'RandYShear', [-5 5]);

% Create augmented datastore
augDs = augmentedImageDatastore([224 224 3], imds, ...
    'DataAugmentation', augmenter, ...
    'ColorPreprocessing', 'gray2rgb');
```

### Custom Augmentation (Segmentation)

```matlab
% For segmentation: MUST apply same transform to image AND mask
function data = augmentSegmentation(data)
    img = data{1};
    mask = data{2};

    % Random rotation
    if rand > 0.5
        angle = (rand - 0.5) * 30;  % ±15°
        img = imrotate(img, angle, 'bilinear', 'crop');
        mask = imrotate(mask, angle, 'nearest', 'crop');  % NEAREST for masks!
    end

    % Random flip
    if rand > 0.5
        img = fliplr(img);
        mask = fliplr(mask);
    end

    % Random crop (keep center 80-100%)
    if rand > 0.5
        scale = 0.8 + rand * 0.2;
        img = randomCropAndResize(img, scale);
        mask = randomCropAndResize(mask, scale, 'nearest');
    end

    % Intensity augmentation (image only!)
    if rand > 0.5
        img = img * (0.8 + rand * 0.4);  % Brightness
    end
    if rand > 0.5
        img = img + (rand - 0.5) * 0.2;  % Contrast
    end

    % Gaussian noise (image only)
    if rand > 0.3
        img = imnoise(img, 'gaussian', 0, 0.01);
    end

    data = {im2single(img), mask};
end

augDs = transform(cds, @augmentSegmentation);
```

### Advanced Augmentation Techniques

```matlab
% Cutout (random rectangular masks)
function img = applyCutout(img, patchSize)
    [H, W, ~] = size(img);
    x = randi(W - patchSize + 1);
    y = randi(H - patchSize + 1);
    img(y:y+patchSize-1, x:x+patchSize-1, :) = 0;
end

% MixUp (blend two images)
function [imgMix, labelMix] = applyMixup(img1, label1, img2, label2, alpha)
    lambda = betarnd(alpha, alpha);
    imgMix = lambda * img1 + (1 - lambda) * img2;
    labelMix = lambda * label1 + (1 - lambda) * label2;
end

% GridMask
function img = applyGridMask(img, ratio, gridSize)
    [H, W, C] = size(img);
    mask = ones(H, W);

    for i = 0:gridSize:(H-1)
        for j = 0:gridSize:(W-1)
            if rand < ratio
                mask(i+1:min(i+gridSize,H), j+1:min(j+gridSize,W)) = 0;
            end
        end
    end

    img = img .* mask;
end

% Elastic deformation (medical imaging)
function [img, mask] = elasticDeform(img, mask, alpha, sigma)
    [H, W] = size(img, [1 2]);

    % Random displacement field
    dx = imgaussfilt(randn(H, W), sigma) * alpha;
    dy = imgaussfilt(randn(H, W), sigma) * alpha;

    [X, Y] = meshgrid(1:W, 1:H);
    img = interp2(double(img), X+dx, Y+dy, 'linear', 0);
    mask = interp2(double(mask), X+dx, Y+dy, 'nearest', 0);
end
```

## Minibatch Queue (Custom Training)

### Basic Usage

```matlab
% Create minibatch queue for custom training
mbq = minibatchqueue(ds, ...
    'MiniBatchSize', 32, ...
    'MiniBatchFormat', {'SSCB', 'CB'}, ...  % Image: H×W×C×Batch, Label: C×Batch
    'OutputAsDlarray', [true, true], ...
    'OutputEnvironment', 'auto');           % GPU if available

% Training loop
while hasdata(mbq)
    [X, T] = next(mbq);
    % ... training step
end

% Reset for next epoch
reset(mbq);
shuffle(mbq);
```

### Configuration Options

```matlab
mbq = minibatchqueue(ds, ...
    'MiniBatchSize', 16, ...
    'MiniBatchFormat', {'SSCB', 'CB'}, ...
    'OutputAsDlarray', [true, true], ...
    'OutputEnvironment', 'gpu', ...         % 'cpu', 'gpu', 'auto'
    'OutputCast', {'single', 'single'}, ...
    'PartialMiniBatch', 'discard', ...      % 'return' or 'discard'
    'PreprocessingEnvironment', 'parallel', ... % 'serial', 'parallel', 'background'
    'DispatchInBackground', true);          % Prefetch next batch
```

### Preprocessing in Minibatch Queue

```matlab
% Define preprocessing function
function [img, label] = preprocessMiniBatch(imgCell, labelCell)
    % imgCell is a cell array of images in the mini-batch

    % Concatenate images into 4D array
    img = cat(4, imgCell{:});

    % Normalize
    img = single(img) / 255;

    % One-hot encode labels
    label = onehotencode(cat(1, labelCell{:}), 2);
end

% Create datastore with preprocessing
mbq = minibatchqueue(ds, 2, ...
    'MiniBatchFcn', @preprocessMiniBatch, ...
    'MiniBatchFormat', {'SSCB', 'CB'});
```

## Large Dataset Strategies

### Parallel Datastore

```matlab
% Use parallel pool for preprocessing
if isempty(gcp('nocreate'))
    parpool('local', 4);
end

% Parallel reading
mbq = minibatchqueue(ds, ...
    'MiniBatchSize', 32, ...
    'PreprocessingEnvironment', 'parallel');
```

### Memory-Mapped Files

```matlab
% For very large datasets, use memory-mapped files
% Save data to matfile
matObj = matfile('large_data.mat', 'Writable', true);
matObj.images = zeros(256, 256, 1, 10000, 'single');
matObj.labels = zeros(10000, 1, 'uint8');

% Write in chunks
for i = 1:100:10000
    batch = loadBatch(i:i+99);
    matObj.images(:,:,:,i:i+99) = batch.images;
    matObj.labels(i:i+99) = batch.labels;
end

% Read on-demand
matObj = matfile('large_data.mat');
img = matObj.images(:,:,:,1:32);  % Only loads requested slices
```

### Blocked Image (Very Large Images)

```matlab
% For gigapixel images (whole slide imaging)
bim = blockedImage('whole_slide.tif');

% Access block
block = getBlock(bim, [1000 2000], [512 512]);

% Create datastore of blocks
blds = blockedImageDatastore(bim, 'BlockSize', [512 512 3]);

% Process blocks
while hasdata(blds)
    [block, info] = read(blds);
    % Process block
end
```

## Data Splitting

### Random Split

```matlab
% Split into train/val/test
[trainImds, valImds, testImds] = splitEachLabel(imds, 0.7, 0.15, 0.15, 'randomized');

% Stratified split (maintains class proportions)
[trainImds, testImds] = splitEachLabel(imds, 0.8, 'randomized');
```

### K-Fold Cross-Validation

```matlab
% Create k-fold partitions
k = 5;
cv = cvpartition(imds.Labels, 'KFold', k);

results = cell(k, 1);
for fold = 1:k
    trainIdx = training(cv, fold);
    testIdx = test(cv, fold);

    trainDs = subset(imds, trainIdx);
    testDs = subset(imds, testIdx);

    % Train and evaluate
    net = trainNetwork(trainDs, lgraph, options);
    results{fold} = classify(net, testDs);
end

% Aggregate results
allPreds = vertcat(results{:});
accuracy = mean(allPreds == imds.Labels);
```

### Leave-One-Out (Small Datasets)

```matlab
% For very small datasets
n = numel(imds.Files);
predictions = categorical(zeros(n, 1));

for i = 1:n
    trainIdx = setdiff(1:n, i);
    testIdx = i;

    trainDs = subset(imds, trainIdx);
    testDs = subset(imds, testIdx);

    net = trainNetwork(trainDs, lgraph, options);
    predictions(i) = classify(net, testDs);
end

accuracy = mean(predictions == imds.Labels);
```

## Performance Optimization

### Prefetching

```matlab
% Enable background dispatching
mbq = minibatchqueue(ds, ...
    'MiniBatchSize', 32, ...
    'DispatchInBackground', true, ...
    'PreprocessingEnvironment', 'parallel');

% Data is loaded while GPU processes current batch
```

### Caching

```matlab
% Cache preprocessed data to disk
cacheDir = 'preprocessed_cache/';
if ~exist(cacheDir, 'dir')
    mkdir(cacheDir);

    % Preprocess and save
    while hasdata(ds)
        [img, label] = read(ds);
        img = preprocess(img);
        save(fullfile(cacheDir, sprintf('%05d.mat', i)), 'img', 'label');
    end
end

% Load from cache
cachedDs = fileDatastore(cacheDir, ...
    'ReadFcn', @load, ...
    'FileExtensions', '.mat');
```

### Data Format Optimization

```matlab
% Use single precision (half memory of double)
img = single(img);

% Use uint8 for labels when possible
labels = uint8(labels);

% Store one-hot encoded labels as sparse
labels = sparse(onehotencode(labels, 2));
```

---

*Source: Deep Learning Toolbox Documentation - Data Pipelines (R2025b)*
