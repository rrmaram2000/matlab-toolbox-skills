# Data Pipeline -- Advanced Patterns

Advanced data pipeline patterns for medical deep learning. Covers custom datastores, medical preprocessing, advanced augmentation, large dataset strategies, and performance optimization. For basic imageDatastore/combine/transform/minibatchqueue usage, the model already has foundational knowledge.

## Medical Image Preprocessing

```matlab
function img = preprocessMedical(img, modality)
    switch modality
        case 'CT'
            % Window/level (Hounsfield Units)
            img = (img - (-100)) / 400;  % Soft tissue window
            img = max(0, min(1, img));
        case 'MRI'
            % Z-score normalization (per-volume, mandatory)
            mask = img > 0;
            img = (img - mean(img(mask))) / std(img(mask));
            img = img / 4 + 0.5;
            img = max(0, min(1, img));
        case 'Xray'
            img = adapthisteq(mat2gray(img));
    end
    img = im2single(img);
end
```

## Custom Datastore (HDF5/MAT Files)

```matlab
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

## Advanced Augmentation Techniques

```matlab
% Elastic deformation (medical imaging -- tissue-like deformation)
function [img, mask] = elasticDeform(img, mask, alpha, sigma)
    [H, W] = size(img, [1 2]);
    dx = imgaussfilt(randn(H, W), sigma) * alpha;
    dy = imgaussfilt(randn(H, W), sigma) * alpha;
    [X, Y] = meshgrid(1:W, 1:H);
    img = interp2(double(img), X+dx, Y+dy, 'linear', 0);
    mask = interp2(double(mask), X+dx, Y+dy, 'nearest', 0);
end

% MixUp (blend two images -- label smoothing effect)
function [imgMix, labelMix] = applyMixup(img1, label1, img2, label2, alpha)
    lambda = betarnd(alpha, alpha);
    imgMix = lambda * img1 + (1 - lambda) * img2;
    labelMix = lambda * label1 + (1 - lambda) * label2;
end

% Cutout (random rectangular occlusion)
function img = applyCutout(img, patchSize)
    [H, W, ~] = size(img);
    x = randi(W - patchSize + 1);
    y = randi(H - patchSize + 1);
    img(y:y+patchSize-1, x:x+patchSize-1, :) = 0;
end
```

## Large Dataset Strategies

### Memory-Mapped Files

```matlab
matObj = matfile('large_data.mat', 'Writable', true);
matObj.images = zeros(256, 256, 1, 10000, 'single');

% Read on-demand (only loads requested slices)
img = matObj.images(:,:,:,1:32);
```

### Blocked Image (Whole Slide Imaging)

```matlab
bim = blockedImage('whole_slide.tif');
blds = blockedImageDatastore(bim, 'BlockSize', [512 512 3]);
while hasdata(blds)
    [block, info] = read(blds);
end
```

### K-Fold Cross-Validation

```matlab
k = 5;
cv = cvpartition(imds.Labels, 'KFold', k);
results = cell(k, 1);
for fold = 1:k
    trainDs = subset(imds, training(cv, fold));
    testDs = subset(imds, test(cv, fold));
    net = trainnet(trainDs, dlnetwork(lgraph), "crossentropy", opts);
    results{fold} = classify(net, testDs);
end
```

## Performance Optimization

```matlab
% Background dispatch + parallel preprocessing
mbq = minibatchqueue(ds, ...
    'MiniBatchSize', 32, ...
    'DispatchInBackground', true, ...
    'PreprocessingEnvironment', 'parallel');

% Cache preprocessed data to disk for repeated experiments
cacheDir = 'preprocessed_cache/';
cachedDs = fileDatastore(cacheDir, 'ReadFcn', @load, 'FileExtensions', '.mat');
```

---

*Source: Deep Learning Toolbox Documentation - Data Pipelines (R2025b)*
