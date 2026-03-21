%% Template: DeepLabv3+ for Histopathology Segmentation
% Train DeepLabv3+ with a ResNet-50 backbone for pathology tissue
% segmentation (e.g., glands, stroma, epithelium in H&E images).
% MATLAB R2025b | Deep Learning Toolbox | Computer Vision Toolbox
%
% Usage:
%   1. Fill in all TODO sections with your data
%   2. Run section-by-section or as complete script
%
% Requirements:
%   - Deep Learning Toolbox
%   - Computer Vision Toolbox
%   - Deep Learning Toolbox Model for ResNet-50 Network

%% TODO: Configure your data paths and parameters
imageDir   = '';   % TODO: Folder containing H&E histopathology images
labelDir   = '';   % TODO: Folder containing pixel label images
outputDir  = '';   % TODO: Path to save trained model
inputSize  = [512 512 3];  % TODO: Typical histopathology patch size
numClasses = 3;            % TODO: e.g., background, epithelium, stroma
classNames = ["background", "epithelium", "stroma"];  % TODO: Your classes
numEpochs  = 20;
miniBatchSize = 4;
initialLR  = 5e-4;

%% Step 1: Create datastores
imds = imageDatastore(imageDir);

pixelLabelIDs = 0:(numClasses - 1);  % TODO: Match IDs in your label images
pxds = pixelLabelDatastore(labelDir, classNames, pixelLabelIDs);

%% Step 2: Analyze class distribution
tbl = countEachLabel(pxds);
disp(tbl);
classFreq = tbl.PixelCount ./ sum(tbl.PixelCount);
classWeights = median(classFreq) ./ classFreq;
fprintf('Inverse-frequency class weights: %s\n', mat2str(classWeights', 3));

%% Step 3: Split into training and validation
numImages = numel(imds.Files);
idx = randperm(numImages);
splitIdx = round(0.8 * numImages);

dsTrain = combine(subset(imds, idx(1:splitIdx)), ...
                  subset(pxds, idx(1:splitIdx)));
dsVal   = combine(subset(imds, idx(splitIdx+1:end)), ...
                  subset(pxds, idx(splitIdx+1:end)));

fprintf('Training: %d | Validation: %d\n', splitIdx, numImages - splitIdx);

%% Step 4: Create DeepLabv3+ network with ResNet-50 backbone
% deeplabv3plus returns dlnetwork directly (R2024a+)
% Note: deeplabv3plusLayers is deprecated and scheduled for removal
net = deeplabv3plus(inputSize, numClasses, "resnet50");

%% Step 5: Configure training options
options = trainingOptions("adam", ...
    InitialLearnRate=initialLR, ...
    MaxEpochs=numEpochs, ...
    MiniBatchSize=miniBatchSize, ...
    ValidationData=dsVal, ...
    ValidationFrequency=50, ...
    LearnRateSchedule="piecewise", ...
    LearnRateDropPeriod=10, ...
    LearnRateDropFactor=0.3, ...
    L2Regularization=1e-4, ...
    Shuffle="every-epoch", ...
    Verbose=true, ...
    Plots="training-progress");

%% Step 6: Train with trainnet (R2025b)
trainedNet = trainnet(dsTrain, net, "crossentropy", options);

%% Step 7: Inference on a test image
testImg = imread(imds.Files{end});  % TODO: Replace with your test image
testImg = imresize(testImg, inputSize(1:2));
segResult = semanticseg(testImg, trainedNet, Classes=classNames);

%% Step 8: Visualize segmentation
figure;
tiledlayout(1, 3);

nexttile; imshow(testImg);
title('H&E Input');

nexttile; imshow(labeloverlay(testImg, segResult, Transparency=0.4));
title('DeepLabv3+ Overlay');

cmap = lines(numClasses);
nexttile; imshow(label2rgb(uint8(segResult), cmap));
title('Label Map');

%% Step 9: Quantitative evaluation
pxdsResults = semanticseg(subset(imds, idx(splitIdx+1:end)), trainedNet, ...
    Classes=classNames, ...
    WriteLocation=tempdir);
metrics = evaluateSemanticSegmentation(pxdsResults, subset(pxds, idx(splitIdx+1:end)));
disp(metrics.ClassMetrics);
disp(metrics.DataSetMetrics);

%% Step 10: Save model
if ~isfolder(outputDir), mkdir(outputDir); end
save(fullfile(outputDir, 'trainedDeepLabv3Plus.mat'), 'trainedNet');
fprintf('DeepLabv3+ model saved to %s\n', outputDir);
