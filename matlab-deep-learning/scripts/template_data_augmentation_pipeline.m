%% Template: Medical Image Data Augmentation Pipeline
% Comprehensive augmentation strategies for 2D and 3D medical imaging
% data to improve model generalization and handle limited training data.
% MATLAB R2025b | Deep Learning Toolbox | Image Processing Toolbox
%
% Usage:
%   1. Fill in all TODO sections with your data
%   2. Run section-by-section or as complete script
%
% Requirements:
%   - Deep Learning Toolbox
%   - Image Processing Toolbox

%% TODO: Configure your data paths and parameters
imageDir2D = '';   % TODO: Folder with 2D training images
labelDir2D = '';   % TODO: Folder with 2D label images (for segmentation)
outputDir  = '';   % TODO: Path to save augmented previews
inputSize  = [256 256 3];  % TODO: Target image size

%% =========================================================================
%%  PART A: 2D Data Augmentation
%% =========================================================================

%% Step 1: Basic augmentation using imageDataAugmenter
basicAugmenter = imageDataAugmenter( ...
    'RandRotation', [-20 20], ...
    'RandXReflection', true, ...
    'RandYReflection', true, ...
    'RandXTranslation', [-15 15], ...
    'RandYTranslation', [-15 15], ...
    'RandScale', [0.85 1.15], ...
    'RandXShear', [-10 10], ...
    'RandYShear', [-10 10]);

%% Step 2: Create augmented image datastore for classification
imds = imageDatastore(imageDir2D, ...
    'IncludeSubfolders', true, ...
    'LabelSource', 'foldernames');

augDS = augmentedImageDatastore(inputSize(1:2), imds, ...
    'DataAugmentation', basicAugmenter, ...
    'ColorPreprocessing', 'gray2rgb');

%% Step 3: Preview augmented samples
figure('Name', '2D Augmentation Preview');
tiledlayout(3, 4, TileSpacing='compact');
sampleImg = readimage(imds, 1);
for i = 1:12
    nexttile;
    batch = read(augDS);
    imshow(batch.input{1});
    if i == 1, title('Augmented Samples'); end
end
sgtitle('imageDataAugmenter — Random Transforms');
reset(augDS);

%% Step 4: Custom augmentation with transform (intensity-based)
% Medical images often benefit from intensity augmentation
imdsCustom = transform(imds, @(data) applyMedicalAugmentation(data));

function out = applyMedicalAugmentation(data)
    img = data;
    if iscell(img), img = img{1}; end
    img = im2single(img);

    % Random brightness shift
    img = img + (rand() * 0.2 - 0.1);

    % Random contrast adjustment
    contrastFactor = 0.8 + rand() * 0.4;  % [0.8, 1.2]
    img = (img - mean(img, 'all')) * contrastFactor + mean(img, 'all');

    % Random Gaussian noise (simulating acquisition noise)
    if rand() > 0.5
        img = imnoise(im2uint8(img), 'gaussian', 0, 0.005);
        img = im2single(img);
    end

    % Random Gaussian blur (simulating motion/defocus)
    if rand() > 0.7
        sigma = 0.5 + rand() * 1.0;
        img = imgaussfilt(img, sigma);
    end

    img = max(0, min(1, img));
    out = img;
end

%% Step 5: Paired augmentation for segmentation (image + label together)
pxds = pixelLabelDatastore(labelDir2D, ...
    ["background", "foreground"], [0 1]);  % TODO: Adjust classes

dsSegTrain = combine(imds, pxds);
dsSegAug   = transform(dsSegTrain, @(data) augmentPair(data));

function out = augmentPair(data)
    img   = data{1};
    label = data{2};

    % Apply identical spatial transforms to both
    tform = randomAffine2d( ...
        Rotation=[-15 15], ...
        XReflection=true, ...
        Scale=[0.9 1.1], ...
        XTranslation=[-10 10], ...
        YTranslation=[-10 10]);

    rout = affineOutputView(size(img), tform, BoundsStyle='centerOutput');
    imgAug   = imwarp(img, tform, OutputView=rout);
    labelAug = imwarp(label, tform, OutputView=rout, Interp='nearest');

    out = {imgAug, labelAug};
end

%% =========================================================================
%%  PART B: 3D Data Augmentation
%% =========================================================================

%% Step 6: 3D augmentation using randomPatchExtractionDatastore
% For volumetric data, patch extraction + transform provides augmentation
patchSize3D = [64 64 64];

% TODO: Create your 3D datastores (volDS, labelDS) here
% volDS   = imageDatastore(..., ReadFcn=@loadVolumeFcn);
% labelDS = pixelLabelDatastore(...);
%
% dsPatch3D = randomPatchExtractionDatastore(volDS, labelDS, patchSize3D, ...
%     PatchesPerImage=16);
%
% dsAug3D = transform(dsPatch3D, @(data) augment3DPatch(data));

%% Step 7: 3D augmentation helper
function out = augment3DPatch(data)
    img   = data.InputImage{1};
    label = data.ResponsePixelLabelImage{1};

    % Random 3D flips
    if rand() > 0.5, img = flip(img, 1); label = flip(label, 1); end
    if rand() > 0.5, img = flip(img, 2); label = flip(label, 2); end
    if rand() > 0.5, img = flip(img, 3); label = flip(label, 3); end

    % Random 90-degree rotations in axial plane
    k = randi(4) - 1;
    img   = rot90(img, k);
    label = rot90(label, k);

    % Random intensity scaling
    img = img * (0.9 + 0.2 * rand());

    out = {img, label};
end

%% Step 8: Summary of augmentation strategies
fprintf('\n=== Medical Image Augmentation Summary ===\n');
fprintf('2D Spatial:   rotation, reflection, translation, scale, shear\n');
fprintf('2D Intensity: brightness, contrast, noise, blur\n');
fprintf('2D Paired:    synchronized transforms for image + label\n');
fprintf('3D Spatial:   random flips, 90-deg rotations, patch extraction\n');
fprintf('3D Intensity: random intensity scaling\n');
fprintf('================================================\n');
