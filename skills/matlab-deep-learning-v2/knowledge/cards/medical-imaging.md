# Medical Imaging Deep Learning (CRITICAL Card)

Medical imaging workflows require specific considerations for data handling, preprocessing, and model design. All examples use the modern R2025b API.

## Modality-Specific Preprocessing

### CT Images

```matlab
% CT scans are stored in Hounsfield Units (HU)
% Range: -1024 (air) to +3000 (dense bone)

% Load DICOM with Medical Imaging Toolbox
V = medicalVolume('ct_scan.dcm');
hu = double(V.Voxels);  % Already in HU

% Window/Level for different tissues
function windowed = applyWindow(hu, center, width)
    minVal = center - width/2;
    maxVal = center + width/2;
    windowed = (hu - minVal) / (maxVal - minVal);
    windowed = max(0, min(1, windowed));
end

% Common windows
lungWindow = applyWindow(hu, -600, 1500);    % Lung
softTissue = applyWindow(hu, 40, 400);       % Abdomen
boneWindow = applyWindow(hu, 400, 1800);     % Bone

% For deep learning: normalize to [0, 1]
% Using soft tissue window for most tasks
normalized = applyWindow(hu, 40, 400);
```

### MRI Images

```matlab
% MRI has arbitrary intensity scale per scan
% Requires per-volume normalization

V = medicalVolume('brain_mri.nii');
mri = double(V.Voxels);

% Z-score normalization (recommended)
mask = mri > 0;  % Exclude background
mri_norm = (mri - mean(mri(mask))) / std(mri(mask));
mri_norm(~mask) = 0;

% Percentile normalization (robust to outliers)
p1 = prctile(mri(mask), 1);
p99 = prctile(mri(mask), 99);
mri_norm = (mri - p1) / (p99 - p1);
mri_norm = max(0, min(1, mri_norm));

% N4 bias field correction (before normalization)
% Requires toolbox or external tool
```

### X-ray Images

```matlab
% X-rays are typically 12-16 bit DICOM
img = dicomread('chest_xray.dcm');
info = dicominfo('chest_xray.dcm');

% Apply DICOM rescale
img = double(img) * info.RescaleSlope + info.RescaleIntercept;

% Normalize to [0, 1]
img = mat2gray(img);

% CLAHE for contrast enhancement (IPT)
img = adapthisteq(img, 'NumTiles', [8 8], 'ClipLimit', 0.02);
```

### Ultrasound Images

```matlab
% Ultrasound has speckle noise and variable brightness

% Load
us = im2double(imread('ultrasound.png'));

% Speckle reduction (use Wavelet Toolbox `wdenoise2`)
logUs = log(us + eps);
denoised = wdenoise2(logUs, 'DenoisingMethod', 'Bayes');
usClean = exp(denoised);

% Normalize
usNorm = mat2gray(usClean);
```

## DICOM/NIfTI Integration

### Loading Medical Volumes

```matlab
% Use Medical Imaging Toolbox for proper spatial referencing

% NIfTI
V = medicalVolume('brain.nii');

% DICOM series
V = medicalVolume('dicom_folder/');

% Access properties
voxels = V.Voxels;                    % 3D array
spacing = V.VoxelSpacing;             % [x, y, z] in mm
geometry = V.VolumeGeometry;          % Spatial referencing

% Extract slices in patient coordinates
slice = extractSlice(V, 50, 'transverse');
```

### Creating Training Data from Volumes

```matlab
% Slice-by-slice extraction for 2D networks
function extractSlicesForTraining(V, outputDir, label)
    mkdir(fullfile(outputDir, 'images'));
    mkdir(fullfile(outputDir, 'masks'));

    for k = 1:V.NumTransverseSlices
        slice = extractSlice(V, k, 'transverse');
        slice = mat2gray(slice);

        % Save
        imwrite(slice, fullfile(outputDir, 'images', ...
            sprintf('%s_slice%03d.png', label, k)));
    end
end

% For 3D networks: patch extraction
function patches = extract3DPatches(V, patchSize, stride)
    vol = single(V.Voxels);
    [H, W, D] = size(vol);
    patches = {};

    for z = 1:stride:(D - patchSize(3) + 1)
        for y = 1:stride:(H - patchSize(1) + 1)
            for x = 1:stride:(W - patchSize(2) + 1)
                patch = vol(y:y+patchSize(1)-1, ...
                           x:x+patchSize(2)-1, ...
                           z:z+patchSize(3)-1);
                patches{end+1} = patch;
            end
        end
    end
end
```

## 3D Volumetric Networks

### 3D U-Net

```matlab
% 3D U-Net for volumetric segmentation
imageSize = [128 128 64 1];  % H*W*D*C
numClasses = 3;

% Modern API (R2024b+) -- returns dlnetwork directly
net = unet3d(imageSize, numClasses, ...
    EncoderDepth=3, ...               % Reduce for memory
    NumFirstEncoderFilters=32);       % CRITICAL: Default is 64, reduce to 32 for 3D

% Memory-efficient training
opts = trainingOptions('adam', ...
    'MaxEpochs', 100, ...
    'MiniBatchSize', 2, ...           % Small batch for 3D
    'InitialLearnRate', 1e-4, ...
    'ExecutionEnvironment', 'gpu');
net = trainnet(ds, net, "crossentropy", opts);
```

### Patch-Based 3D Training

```matlab
% For large volumes that don't fit in memory
patchSize = [64 64 64];
stride = [32 32 32];  % 50% overlap

% Create patch datastore
function ds = create3DPatchDatastore(volPath, maskPath, patchSize, stride)
    V = medicalVolume(volPath);
    M = medicalVolume(maskPath);

    % Extract patches
    volPatches = extract3DPatches(V.Voxels, patchSize, stride);
    maskPatches = extract3DPatches(M.Voxels, patchSize, stride);

    % Filter empty patches (all background)
    valid = cellfun(@(m) any(m(:) > 0), maskPatches);
    volPatches = volPatches(valid);
    maskPatches = maskPatches(valid);

    % Create arrayDatastore
    volDs = arrayDatastore(cat(5, volPatches{:}), 'IterationDimension', 5);
    maskDs = arrayDatastore(cat(5, maskPatches{:}), 'IterationDimension', 5);
    ds = combine(volDs, maskDs);
end
```

### 2.5D Approach (Multi-Slice)

```matlab
% Use adjacent slices as channels (compromise between 2D and 3D)
function multiSlice = extract25D(vol, sliceIdx, numSlices)
    % Extract numSlices centered at sliceIdx
    halfN = floor(numSlices / 2);
    startIdx = max(1, sliceIdx - halfN);
    endIdx = min(size(vol, 3), sliceIdx + halfN);

    multiSlice = vol(:, :, startIdx:endIdx);

    % Pad if necessary
    if size(multiSlice, 3) < numSlices
        padding = numSlices - size(multiSlice, 3);
        if sliceIdx <= halfN
            multiSlice = cat(3, zeros(size(vol,1), size(vol,2), padding), multiSlice);
        else
            multiSlice = cat(3, multiSlice, zeros(size(vol,1), size(vol,2), padding));
        end
    end
end

% Network for 2.5D input
imageSize = [256 256 5];  % 5 adjacent slices
net = unet(imageSize, 2, EncoderDepth=4);
```

## Medical-Specific Augmentation

```matlab
function [imgOut, maskOut] = medicalAugmentation(img, mask)
    % Rotation (small angles for medical)
    if rand > 0.5
        angle = (rand - 0.5) * 30;  % ±15°
        img = imrotate(img, angle, 'bilinear', 'crop');
        mask = imrotate(mask, angle, 'nearest', 'crop');
    end

    % Horizontal flip (depends on anatomy)
    if rand > 0.5
        img = fliplr(img);
        mask = fliplr(mask);
    end

    % Elastic deformation (tissue-like deformation)
    if rand > 0.5
        [img, mask] = elasticDeformation(img, mask, 8, 0.08);
    end

    % Intensity augmentation (image only)
    if rand > 0.5
        % Gamma correction
        gamma = 0.7 + rand * 0.6;  % [0.7, 1.3]
        img = img .^ gamma;
    end

    if rand > 0.5
        % Gaussian noise
        img = imnoise(img, 'gaussian', 0, 0.01);
    end

    if rand > 0.5
        % Brightness shift
        shift = (rand - 0.5) * 0.2;
        img = img + shift;
        img = max(0, min(1, img));
    end

    imgOut = img;
    maskOut = mask;
end

% Elastic deformation helper
function [imgDef, maskDef] = elasticDeformation(img, mask, gridSize, magnitude)
    [H, W] = size(img);

    % Random displacement field
    dx = imgaussfilt(randn(gridSize, gridSize), 1) * magnitude * W;
    dy = imgaussfilt(randn(gridSize, gridSize), 1) * magnitude * H;

    % Upsample to image size
    dx = imresize(dx, [H, W]);
    dy = imresize(dy, [H, W]);

    % Create sampling grid
    [X, Y] = meshgrid(1:W, 1:H);
    Xdef = X + dx;
    Ydef = Y + dy;

    % Apply deformation
    imgDef = interp2(double(img), Xdef, Ydef, 'linear', 0);
    maskDef = interp2(double(mask), Xdef, Ydef, 'nearest', 0);
end
```

## Cross-Toolbox Workflow

### Complete Medical DL Pipeline

```matlab
% Brain tumor segmentation pipeline
% Combines MIT + IPT + DL Toolbox

%% 1. LOAD DATA (Medical Imaging Toolbox)
V = medicalVolume('brain_t1.nii');
voxels = double(V.Voxels);
fprintf('Volume size: %s, Spacing: %s mm\n', ...
    mat2str(size(voxels)), mat2str(V.VoxelSpacing));

%% 2. PREPROCESS (Image Processing Toolbox)
% Normalize
voxels = (voxels - mean(voxels(:))) / std(voxels(:));

% Denoise (optional)
for k = 1:size(voxels, 3)
    voxels(:,:,k) = imgaussfilt(voxels(:,:,k), 0.5);
end

%% 3. SEGMENT (Deep Learning Toolbox)
% Assume trained 2D U-Net
segmentation = zeros(size(voxels));

for k = 1:size(voxels, 3)
    slice = mat2gray(voxels(:,:,k));
    slice = imresize(slice, [256 256]);

    % Segment
    mask = semanticseg(slice, net);

    % Resize back
    mask = imresize(double(mask == 'Tumor'), size(voxels, [1 2]), 'nearest');
    segmentation(:,:,k) = mask;
end

%% 4. POST-PROCESS (Image Processing Toolbox)
% Remove small objects
segmentation = bwareaopen(segmentation, 500);

% Fill holes
for k = 1:size(segmentation, 3)
    segmentation(:,:,k) = imfill(segmentation(:,:,k), 'holes');
end

% Morphological closing
se = strel('sphere', 3);
segmentation = imclose(segmentation, se);

%% 5. SAVE RESULT (Medical Imaging Toolbox)
segVol = medicalVolume(uint8(segmentation), V.VolumeGeometry);
segVol.Modality = 'SEG';
write(segVol, 'tumor_segmentation.nii');

%% 6. VISUALIZE
figure;
sliceViewer(V);

figure;
% labelvolshow REMOVED in R2025b - use volshow with OverlayData
volshow(voxels, OverlayData=segmentation, ...
    OverlayColormap=[1 0 0], BackgroundColor='k');
```

## Performance Optimization

### GPU Memory for Medical Images

```matlab
% Medical images are often large - manage GPU memory carefully

% Check available memory
gpu = gpuDevice;
availableGB = gpu.AvailableMemory / 1e9;
fprintf('Available GPU memory: %.2f GB\n', availableGB);

% Estimate network memory requirement
inputSize = [512 512 1 8];  % H×W×C×Batch
bytesPerPixel = 4;  % single precision
inputMB = prod(inputSize) * bytesPerPixel / 1e6;
fprintf('Input batch: %.1f MB\n', inputMB);

% Rule of thumb: network needs ~3-5x input size for gradients
% So for 512×512 with batch=8: ~100-150 MB just for input

% Strategies for large images:
% 1. Reduce batch size
% 2. Use mixed precision (16-bit)
% 3. Use gradient checkpointing
% 4. Process patches instead of full images
```

### Mixed Precision Training

```matlab
% Use half precision to reduce memory and speed up training
options = trainingOptions('adam', ...
    'MaxEpochs', 50, ...
    'MiniBatchSize', 16, ...
    'ExecutionEnvironment', 'gpu', ...
    'ResetInputNormalization', false);

% For custom training loop
X = dlarray(single(data), 'SSCB');
X = gpuArray(X);
% Gradients will be computed in single precision
```

### Batch Size Selection

```matlab
% Find maximum batch size that fits in GPU memory
function maxBatch = findMaxBatchSize(net, inputSize)
    maxBatch = 1;
    for bs = [1, 2, 4, 8, 16, 32, 64]
        try
            reset(gpuDevice);
            X = dlarray(randn([inputSize bs], 'single'), 'SSCB');
            X = gpuArray(X);
            Y = predict(net, X);
            maxBatch = bs;
        catch ME
            if contains(ME.message, 'memory')
                break;
            else
                rethrow(ME);
            end
        end
    end
    fprintf('Maximum batch size: %d\n', maxBatch);
end
```

## Evaluation Metrics for Medical Imaging

### Dice Score (Sørensen–Dice Coefficient)

```matlab
function dice = diceScore(pred, truth)
    % pred, truth: binary masks
    intersection = sum(pred(:) & truth(:));
    total = sum(pred(:)) + sum(truth(:));
    dice = 2 * intersection / (total + eps);
end

% Volume-wise Dice
diceScores = zeros(numTestCases, 1);
for i = 1:numTestCases
    pred = load predictions...
    truth = load ground truth...
    diceScores(i) = diceScore(pred, truth);
end
fprintf('Mean Dice: %.4f ± %.4f\n', mean(diceScores), std(diceScores));
```

### Hausdorff Distance (Boundary Accuracy)

```matlab
function hd = hausdorffDistance(pred, truth)
    % Find boundary points
    predBoundary = bwperim(pred);
    truthBoundary = bwperim(truth);

    [py, px] = find(predBoundary);
    [ty, tx] = find(truthBoundary);

    if isempty(py) || isempty(ty)
        hd = NaN;
        return;
    end

    % Compute directed Hausdorff distances
    predPts = [px, py];
    truthPts = [tx, ty];

    d1 = max(min(pdist2(predPts, truthPts), [], 2));  % pred → truth
    d2 = max(min(pdist2(truthPts, predPts), [], 2));  % truth → pred

    hd = max(d1, d2);
end
```

### Surface Distance Metrics

```matlab
function [asd, hd95] = surfaceDistances(pred, truth, spacing)
    % Average Surface Distance and 95th percentile Hausdorff

    predSurf = bwperim(pred);
    truthSurf = bwperim(truth);

    [py, px, pz] = ind2sub(size(pred), find(predSurf));
    [ty, tx, tz] = ind2sub(size(truth), find(truthSurf));

    % Scale by voxel spacing
    predPts = [px * spacing(1), py * spacing(2), pz * spacing(3)];
    truthPts = [tx * spacing(1), ty * spacing(2), tz * spacing(3)];

    % Compute distances
    d1 = min(pdist2(predPts, truthPts), [], 2);
    d2 = min(pdist2(truthPts, predPts), [], 2);

    allDist = [d1; d2];
    asd = mean(allDist);
    hd95 = prctile(allDist, 95);
end
```

---

*Verified against MATLAB R2025b*
*See also: Medical Imaging Toolbox (`medicalVolume`, `dicomread`), Image Processing Toolbox (`imgaussfilt`, `imbinarize`)*
