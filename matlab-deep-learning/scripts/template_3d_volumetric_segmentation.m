%% Template: 3D U-Net for Volumetric CT/MRI Segmentation
% Train a 3D U-Net for organ or tumor segmentation in volumetric medical
% data using patch-based training with randomPatchExtractionDatastore.
% MATLAB R2025b | Deep Learning Toolbox | Computer Vision Toolbox
%
% Usage:
%   1. Fill in all TODO sections with your data
%   2. Run section-by-section or as complete script
%
% Requirements:
%   - Deep Learning Toolbox
%   - Computer Vision Toolbox
%   - Medical Imaging Toolbox (optional, for DICOM/NIfTI loading)

%% TODO: Configure your data paths and parameters
volumeDir  = '';   % TODO: Folder containing 3D volumes (.mat or .nii)
labelDir   = '';   % TODO: Folder containing 3D label volumes
outputDir  = '';   % TODO: Path to save trained model
patchSize  = [64 64 64];   % TODO: 3D patch size (adjust to GPU memory)
numChannels = 1;            % TODO: Number of input channels
numClasses  = 2;            % TODO: Number of classes (including background)
classNames  = ["background", "organ"];  % TODO: Your class names
numEpochs   = 50;
miniBatchSize = 2;          % 3D patches are memory-intensive
initialLR   = 1e-3;
patchesPerImage = 16;       % Number of random patches per volume per epoch

%% Step 1: Load volumes into arrays
% TODO: Adapt this loading section to your data format
volFiles   = dir(fullfile(volumeDir, '*.mat'));  % TODO: Adjust extension
labelFiles = dir(fullfile(labelDir, '*.mat'));

volumes = cell(numel(volFiles), 1);
labels  = cell(numel(volFiles), 1);
for i = 1:numel(volFiles)
    data = load(fullfile(volFiles(i).folder, volFiles(i).name));
    volumes{i} = single(data.vol);       % TODO: Adjust field name
    ldata = load(fullfile(labelFiles(i).folder, labelFiles(i).name));
    labels{i}  = categorical(ldata.seg); % TODO: Adjust field name
end
fprintf('Loaded %d volumes.\n', numel(volumes));

%% Step 2: Create image and pixel label datastores for 3D data
volDS   = imageDatastore(fullfile(volumeDir, {volFiles.name}), ...
    ReadFcn=@(f) loadVolume(f));
labelDS = pixelLabelDatastore( ...
    fullfile(labelDir, {labelFiles.name}), ...
    classNames, 0:(numClasses-1), ...
    ReadFcn=@(f) loadLabel(f));

%% Step 3: Split into training and validation
numVol = numel(volDS.Files);
idx = randperm(numVol);
splitIdx = round(0.8 * numVol);

volTrain   = subset(volDS, idx(1:splitIdx));
labelTrain = subset(labelDS, idx(1:splitIdx));
volVal     = subset(volDS, idx(splitIdx+1:end));
labelVal   = subset(labelDS, idx(splitIdx+1:end));

%% Step 4: Create random patch extraction datastores
dsTrain = randomPatchExtractionDatastore(volTrain, labelTrain, patchSize, ...
    PatchesPerImage=patchesPerImage);

dsVal = randomPatchExtractionDatastore(volVal, labelVal, patchSize, ...
    PatchesPerImage=patchesPerImage);

%% Step 5: Create 3D U-Net (R2025b — returns dlnetwork directly)
inputSize3D = [patchSize numChannels];
net = unet3d(inputSize3D, numClasses);

%% Step 6: Configure training options
options = trainingOptions("adam", ...
    InitialLearnRate=initialLR, ...
    MaxEpochs=numEpochs, ...
    MiniBatchSize=miniBatchSize, ...
    ValidationData=dsVal, ...
    ValidationFrequency=100, ...
    LearnRateSchedule="piecewise", ...
    LearnRateDropPeriod=20, ...
    LearnRateDropFactor=0.5, ...
    Shuffle="every-epoch", ...
    Verbose=true, ...
    Plots="training-progress");

%% Step 7: Train with trainnet
trainedNet = trainnet(dsTrain, net, "crossentropy", options);

%% Step 8: Inference on a test volume (patch-based sliding window)
testVol = volumes{end};  % TODO: Replace with your test volume
segResult = semanticseg(testVol, trainedNet, Classes=classNames);

%% Step 9: Visualize a representative slice
midSlice = round(size(testVol, 3) / 2);
figure;
tiledlayout(1, 3);

nexttile; imshow(testVol(:,:,midSlice), []);
title(sprintf('Input — Slice %d', midSlice));

nexttile; imshow(labeloverlay(mat2gray(testVol(:,:,midSlice)), ...
    segResult(:,:,midSlice), Transparency=0.4));
title('Segmentation Overlay');

nexttile; imshow(segResult(:,:,midSlice) == classNames(2));
title(sprintf('Binary Mask — %s', classNames(2)));

%% Step 10: Save model
if ~isfolder(outputDir), mkdir(outputDir); end
save(fullfile(outputDir, 'trained3DUNet.mat'), 'trainedNet');
fprintf('3D U-Net saved to %s\n', outputDir);

%% Local helper functions
function vol = loadVolume(filename)
    data = load(filename);
    fn = fieldnames(data);
    vol = single(data.(fn{1}));
end

function seg = loadLabel(filename)
    data = load(filename);
    fn = fieldnames(data);
    seg = categorical(data.(fn{1}));
end
