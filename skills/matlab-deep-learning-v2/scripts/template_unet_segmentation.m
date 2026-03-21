%% Template: U-Net Semantic Segmentation for Organ/Tumor
% Train a U-Net for 2D semantic segmentation of medical images such as
% organ boundaries or tumor regions from CT/MRI slices.
% MATLAB R2025b | Deep Learning Toolbox | Computer Vision Toolbox
%
% Usage:
%   1. Fill in all TODO sections with your data
%   2. Run section-by-section or as complete script
%
% Requirements:
%   - Deep Learning Toolbox
%   - Computer Vision Toolbox

%% TODO: Configure your data paths and parameters
imageDir   = '';   % TODO: Folder containing input images
labelDir   = '';   % TODO: Folder containing pixel label images
outputDir  = '';   % TODO: Path to save trained model
inputSize  = [256 256 1];  % TODO: Adjust channels (1=grayscale, 3=RGB)
numClasses = 2;            % TODO: Number of segmentation classes (including background)
classNames = ["background", "tumor"];  % TODO: Your class names
numEpochs  = 30;
miniBatchSize = 8;
initialLR  = 1e-3;

%% Step 1: Create image and pixel label datastores
imds = imageDatastore(imageDir);

% Define pixel label IDs that correspond to each class in label images
pixelLabelIDs = 0:(numClasses - 1);  % TODO: Adjust if your labels use different IDs
pxds = pixelLabelDatastore(labelDir, classNames, pixelLabelIDs);

%% Step 2: Split data into training and validation
numImages = numel(imds.Files);
idx = randperm(numImages);
splitIdx = round(0.8 * numImages);

imdsTrain = subset(imds, idx(1:splitIdx));
pxdsTrain = subset(pxds, idx(1:splitIdx));
imdsVal   = subset(imds, idx(splitIdx+1:end));
pxdsVal   = subset(pxds, idx(splitIdx+1:end));

dsTrain = combine(imdsTrain, pxdsTrain);
dsVal   = combine(imdsVal, pxdsVal);

fprintf('Training: %d images | Validation: %d images\n', splitIdx, numImages - splitIdx);

%% Step 3: Create U-Net (R2025b — returns dlnetwork directly)
% unet default NumFirstEncoderFilters = 64
net = unet(inputSize, numClasses);

%% Step 4: Compute class weights for imbalanced data (optional)
tbl = countEachLabel(pxds);
totalPixels = sum(tbl.PixelCount);
classWeights = totalPixels ./ (numClasses * tbl.PixelCount);
fprintf('Class weights: %s\n', mat2str(classWeights', 3));

%% Step 5: Configure training options
options = trainingOptions("adam", ...
    InitialLearnRate=initialLR, ...
    MaxEpochs=numEpochs, ...
    MiniBatchSize=miniBatchSize, ...
    ValidationData=dsVal, ...
    ValidationFrequency=50, ...
    Shuffle="every-epoch", ...
    Verbose=true, ...
    Plots="training-progress");

%% Step 6: Train using trainnet with cross-entropy loss
trainedNet = trainnet(dsTrain, net, "crossentropy", options);

%% Step 7: Run inference using semanticseg
testImage = imread(imds.Files{1});  % TODO: Replace with your test image
if size(testImage, 3) == 3 && inputSize(3) == 1
    testImage = im2gray(testImage);
end
testImage = imresize(testImage, inputSize(1:2));

segResult = semanticseg(testImage, trainedNet, Classes=classNames);

%% Step 8: Visualize results
figure;
tiledlayout(1, 3);

nexttile; imshow(testImage, []);
title('Input Image');

nexttile; imshow(labeloverlay(mat2gray(testImage), segResult, Transparency=0.3));
title('Segmentation Overlay');

nexttile; imshow(segResult == classNames(2));
title(sprintf('Binary Mask — %s', classNames(2)));

%% Step 9: Evaluate with IoU metrics
pxdsResults = semanticseg(imdsVal, trainedNet, ...
    Classes=classNames, ...
    WriteLocation=tempdir);
metrics = evaluateSemanticSegmentation(pxdsResults, pxdsVal);
disp(metrics.ClassMetrics);

%% Step 10: Save model
if ~isfolder(outputDir), mkdir(outputDir); end
save(fullfile(outputDir, 'trainedUNet.mat'), 'trainedNet');
fprintf('U-Net model saved to %s\n', outputDir);
