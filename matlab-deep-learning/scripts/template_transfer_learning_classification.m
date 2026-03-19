%% Template: Transfer Learning for Medical Image Classification
% Fine-tune a pretrained network (ResNet-50 or EfficientNet-b0) for
% medical image classification tasks such as chest X-ray pathology.
% MATLAB R2025b | Deep Learning Toolbox
%
% Usage:
%   1. Fill in all TODO sections with your data
%   2. Run section-by-section or as complete script
%
% Requirements:
%   - Deep Learning Toolbox
%   - Deep Learning Toolbox Model for ResNet-50 Network (or EfficientNet-b0)

%% TODO: Configure your data paths and parameters
dataDir    = '';   % TODO: Path to your image dataset (organized in subfolders per class)
outputDir  = '';   % TODO: Path to save trained model and results
inputSize  = [224 224 3];  % Input size for ResNet-50; adjust if using EfficientNet-b0
backbone   = "resnet50";   % TODO: Choose "resnet50" or "efficientnetb0"
numEpochs  = 10;
miniBatchSize = 16;
initialLR  = 1e-4;
validationSplit = 0.2;     % Fraction of data for validation

%% Step 1: Load and split image data
imds = imageDatastore(dataDir, ...
    'IncludeSubfolders', true, ...
    'LabelSource', 'foldernames');

% Split into training and validation sets
[imdsTrain, imdsVal] = splitEachLabel(imds, 1 - validationSplit, 'randomized');

numClasses = numel(categories(imdsTrain.Labels));
fprintf('Dataset: %d training, %d validation images across %d classes.\n', ...
    numel(imdsTrain.Files), numel(imdsVal.Files), numClasses);

%% Step 2: Load pretrained network and modify for new task
if backbone == "resnet50"
    net = imagePretrainedNetwork(backbone, NumClasses=numClasses);
elseif backbone == "efficientnetb0"
    net = imagePretrainedNetwork(backbone, NumClasses=numClasses);
end

%% Step 3: Freeze early layers for stable transfer learning
% Freeze the first ~75% of learnable layers so only the head trains initially
learnableIdx = find(arrayfun(@(L) ~isempty(L.Learnables), net.Layers));
numFreeze = round(0.75 * numel(learnableIdx));
for i = 1:numFreeze
    layerName = net.Layers(learnableIdx(i)).Name;
    net = setLearnRateFactor(net, layerName, "Weights", 0);
    net = setLearnRateFactor(net, layerName, "Bias", 0);
end
fprintf('Froze %d of %d learnable layers.\n', numFreeze, numel(learnableIdx));

%% Step 4: Set up data augmentation
augmenter = imageDataAugmenter( ...
    'RandRotation', [-15 15], ...
    'RandXReflection', true, ...
    'RandYReflection', false, ...
    'RandXTranslation', [-10 10], ...
    'RandYTranslation', [-10 10], ...
    'RandScale', [0.9 1.1]);

dsTrain = augmentedImageDatastore(inputSize(1:2), imdsTrain, ...
    'DataAugmentation', augmenter, ...
    'ColorPreprocessing', 'gray2rgb');

dsVal = augmentedImageDatastore(inputSize(1:2), imdsVal, ...
    'ColorPreprocessing', 'gray2rgb');

%% Step 5: Configure training options
options = trainingOptions("adam", ...
    InitialLearnRate=initialLR, ...
    MaxEpochs=numEpochs, ...
    MiniBatchSize=miniBatchSize, ...
    ValidationData=dsVal, ...
    ValidationFrequency=30, ...
    Shuffle="every-epoch", ...
    Verbose=true, ...
    Plots="training-progress");

%% Step 6: Train the network using trainnet (R2025b)
trainedNet = trainnet(dsTrain, net, "crossentropy", options);

%% Step 7: Evaluate on validation set
scores = minibatchpredict(trainedNet, dsVal);
YPred  = scores2label(scores, categories(imdsTrain.Labels));
YTrue  = imdsVal.Labels;

accuracy = mean(YPred == YTrue);
fprintf('Validation accuracy: %.2f%%\n', accuracy * 100);

% Confusion matrix
figure;
confusionchart(YTrue, YPred);
title(sprintf('Transfer Learning — %s (Accuracy: %.1f%%)', backbone, accuracy*100));

%% Step 8: Save trained model
if ~isfolder(outputDir), mkdir(outputDir); end
save(fullfile(outputDir, 'trainedClassificationNet.mat'), 'trainedNet');
fprintf('Model saved to %s\n', outputDir);
