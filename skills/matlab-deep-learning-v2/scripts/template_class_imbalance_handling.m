%% Template: Handling Class Imbalance in Medical Image Classification
% Strategies for addressing severe class imbalance common in medical
% datasets: weighted cross-entropy, oversampling, and custom loss functions.
% MATLAB R2025b | Deep Learning Toolbox
%
% Usage:
%   1. Fill in all TODO sections with your data
%   2. Run section-by-section or as complete script
%
% Requirements:
%   - Deep Learning Toolbox

%% TODO: Configure your data paths and parameters
dataDir    = '';   % TODO: Path to image dataset (subfolders per class)
outputDir  = '';   % TODO: Path to save results
inputSize  = [224 224 3];
backbone   = "resnet50";  % TODO: Choose pretrained backbone
numEpochs  = 20;
miniBatchSize = 16;
initialLR  = 1e-4;

%% Step 1: Load data and analyze class distribution
imds = imageDatastore(dataDir, ...
    'IncludeSubfolders', true, ...
    'LabelSource', 'foldernames');

classCounts = countEachLabel(imds);
disp(classCounts);

numClasses  = height(classCounts);
classNames  = classCounts.Label;
totalImages = sum(classCounts.Count);

fprintf('\nClass imbalance ratio (max/min): %.1f:1\n', ...
    max(classCounts.Count) / min(classCounts.Count));

figure;
bar(classCounts.Label, classCounts.Count);
title('Original Class Distribution');
ylabel('Number of Images');

%% =========================================================================
%%  Strategy 1: Weighted Cross-Entropy Loss
%% =========================================================================

%% Step 2: Compute class weights (inverse frequency)
classFreq = classCounts.Count / totalImages;
classWeights = 1 ./ classFreq;
classWeights = classWeights / sum(classWeights) * numClasses;  % Normalize
fprintf('Class weights: %s\n', mat2str(classWeights', 3));

%% Step 3: Train with weighted loss using custom training loop
[imdsTrain, imdsVal] = splitEachLabel(imds, 0.8, 'randomized');

net = imagePretrainedNetwork(backbone, NumClasses=numClasses);

% Create minibatch queue
dsTrain = augmentedImageDatastore(inputSize(1:2), imdsTrain, ...
    'ColorPreprocessing', 'gray2rgb');
dsVal   = augmentedImageDatastore(inputSize(1:2), imdsVal, ...
    'ColorPreprocessing', 'gray2rgb');

mbqTrain = minibatchqueue( ...
    combine(dsTrain, arrayDatastore(imdsTrain.Labels)), 2, ...
    MiniBatchSize=miniBatchSize, ...
    MiniBatchFcn=@(x,y) preprocessClassBatch(x, y, numClasses), ...
    MiniBatchFormat=["SSCB", "CB"]);

% Adam optimizer state
[avgGrad, avgSqGrad] = deal([]);
iteration = 0;
weightsArr = dlarray(single(classWeights'), 'CB');

for epoch = 1:numEpochs
    shuffle(mbqTrain);
    epochLoss = 0;
    numIter = 0;

    while hasdata(mbqTrain)
        iteration = iteration + 1;
        numIter = numIter + 1;
        [dlX, dlY] = next(mbqTrain);

        [loss, gradients] = dlfeval(@weightedCELoss, net, dlX, dlY, weightsArr);
        [net, avgGrad, avgSqGrad] = adamupdate(net, gradients, ...
            avgGrad, avgSqGrad, iteration, initialLR);

        epochLoss = epochLoss + double(extractdata(loss));
    end

    if mod(epoch, 5) == 0
        fprintf('Epoch %d/%d — Weighted CE Loss: %.4f\n', ...
            epoch, numEpochs, epochLoss/numIter);
    end
    reset(mbqTrain);
end

%% =========================================================================
%%  Strategy 2: Random Oversampling
%% =========================================================================

%% Step 4: Oversample minority classes
maxCount = max(classCounts.Count);
oversampledFiles  = {};
oversampledLabels = categorical([]);

for c = 1:numClasses
    classIdx = find(imds.Labels == classNames(c));
    classFiles = imds.Files(classIdx);
    numToAdd = maxCount - numel(classIdx);

    if numToAdd > 0
        % Randomly duplicate from this class
        dupIdx = randsample(numel(classFiles), numToAdd, true);
        classFiles = [classFiles; classFiles(dupIdx)]; %#ok<AGROW>
    end

    oversampledFiles  = [oversampledFiles; classFiles]; %#ok<AGROW>
    oversampledLabels = [oversampledLabels; repmat(classNames(c), numel(classFiles), 1)]; %#ok<AGROW>
end

imdsOversampled = imageDatastore(oversampledFiles);
imdsOversampled.Labels = oversampledLabels;

fprintf('\nAfter oversampling: %d images (was %d)\n', ...
    numel(imdsOversampled.Files), totalImages);
disp(countEachLabel(imdsOversampled));

%% =========================================================================
%%  Strategy 3: Focal Loss (Custom dlarray Loss)
%% =========================================================================

%% Step 5: Focal loss implementation for hard example mining
% Focal loss reduces the relative loss for well-classified examples,
% focusing training on hard, misclassified samples
gamma = 2.0;  % TODO: Focusing parameter (0 = standard CE, 2 = common choice)
alpha = classWeights / sum(classWeights);  % Per-class balancing

fprintf('\nFocal loss parameters: gamma=%.1f, alpha=%s\n', ...
    gamma, mat2str(alpha', 3));

% TODO: Use focalLoss function in your custom training loop (Step 3 pattern)
%   [loss, gradients] = dlfeval(@focalLossModel, net, dlX, dlY, alpha, gamma);

%% Step 6: Evaluate class-wise performance
scores = minibatchpredict(net, dsVal);
YPred = scores2label(scores, classNames);
YTrue = imdsVal.Labels;

accuracy = mean(YPred == YTrue);
fprintf('\nOverall accuracy: %.2f%%\n', accuracy * 100);

% Per-class recall (sensitivity) — critical for medical diagnosis
for c = 1:numClasses
    classTrue = YTrue == classNames(c);
    classPred = YPred == classNames(c);
    recall = sum(classTrue & classPred) / sum(classTrue);
    precision = sum(classTrue & classPred) / max(sum(classPred), 1);
    fprintf('  %s — Recall: %.2f%%, Precision: %.2f%%\n', ...
        classNames(c), recall*100, precision*100);
end

figure;
confusionchart(YTrue, YPred, Normalization='row-normalized');
title('Normalized Confusion Matrix (Row = True Class)');

%% Step 7: Save model
if ~isfolder(outputDir), mkdir(outputDir); end
save(fullfile(outputDir, 'trainedImbalanceNet.mat'), 'net');
fprintf('Model saved to %s\n', outputDir);

%% ---- Local Functions ----

function [loss, gradients] = weightedCELoss(net, dlX, dlY, weights)
    dlYPred = forward(net, dlX);
    dlYPred = softmax(dlYPred);
    loss = -sum(weights .* dlY .* log(dlYPred + 1e-8), 1);
    loss = mean(loss);
    gradients = dlgradient(loss, net.Learnables);
end

function [loss, gradients] = focalLossModel(net, dlX, dlY, alpha, gamma)
    dlYPred = forward(net, dlX);
    pt = softmax(dlYPred);
    alphaT = dlarray(single(alpha(:)), 'CB');
    focalWeight = (1 - pt) .^ gamma;
    loss = -mean(alphaT .* focalWeight .* dlY .* log(pt + 1e-8), 'all');
    gradients = dlgradient(loss, net.Learnables);
end

function [X, Y] = preprocessClassBatch(images, labels, numClasses)
    X = cat(4, images{:});
    X = single(X);
    Y = onehotencode(cat(1, labels{:}), 2)';
    Y = single(Y);
end
