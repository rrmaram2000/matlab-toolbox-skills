%% Template: Custom Training Loop with Dice + Cross-Entropy Loss
% Implement a manual training loop using dlarray, dlfeval, dlgradient,
% and adamupdate for full control over loss functions and training logic.
% MATLAB R2025b | Deep Learning Toolbox
%
% Usage:
%   1. Fill in all TODO sections with your data
%   2. Run section-by-section or as complete script
%
% Requirements:
%   - Deep Learning Toolbox
%   - Computer Vision Toolbox (for U-Net creation)

%% TODO: Configure your data paths and parameters
imageDir   = '';   % TODO: Folder containing training images
labelDir   = '';   % TODO: Folder containing label images
outputDir  = '';   % TODO: Path to save trained model
inputSize  = [256 256 1];   % TODO: Adjust for your data
numClasses = 2;
classNames = ["background", "tumor"];  % TODO: Your class names
numEpochs  = 50;
miniBatchSize = 4;
initialLR  = 1e-3;
diceWeight = 0.5;   % Weight for Dice loss (CE weight = 1 - diceWeight)
useGPU     = canUseGPU();

%% Step 1: Create datastores
imds = imageDatastore(imageDir);
pixelLabelIDs = 0:(numClasses - 1);
pxds = pixelLabelDatastore(labelDir, classNames, pixelLabelIDs);
dsTrain = combine(imds, pxds);

mbq = minibatchqueue(dsTrain, 2, ...
    MiniBatchSize=miniBatchSize, ...
    MiniBatchFcn=@preprocessMiniBatch, ...
    MiniBatchFormat=["SSCB", "SSCB"]);

%% Step 2: Build network
net = unet(inputSize, numClasses);

%% Step 3: Initialize Adam optimizer state
[avgGrad, avgSqGrad] = deal([]);
iteration = 0;

%% Step 4: Training loop
lossHistory = zeros(numEpochs, 1);
fprintf('Starting custom training loop (%d epochs)...\n', numEpochs);

for epoch = 1:numEpochs
    shuffle(mbq);
    epochLoss = 0;
    numIter = 0;

    while hasdata(mbq)
        iteration = iteration + 1;
        numIter = numIter + 1;

        [dlX, dlY] = next(mbq);

        % Compute gradients using dlfeval + dlgradient
        [loss, gradients] = dlfeval(@modelLoss, net, dlX, dlY, ...
            numClasses, diceWeight);

        % Update parameters with Adam
        [net, avgGrad, avgSqGrad] = adamupdate(net, gradients, ...
            avgGrad, avgSqGrad, iteration, initialLR);

        epochLoss = epochLoss + double(extractdata(loss));
    end

    lossHistory(epoch) = epochLoss / numIter;

    if mod(epoch, 5) == 0 || epoch == 1
        fprintf('Epoch %3d/%d — Loss: %.4f\n', epoch, numEpochs, lossHistory(epoch));
    end

    reset(mbq);
end

%% Step 5: Plot training loss
figure;
plot(1:numEpochs, lossHistory, 'b-', 'LineWidth', 2);
xlabel('Epoch'); ylabel('Combined Dice + CE Loss');
title('Custom Training Loop — Loss Curve');
grid on;

%% Step 6: Inference
testImg = imread(imds.Files{1});  % TODO: Replace with your test image
testImg = imresize(testImg, inputSize(1:2));
dlTest  = dlarray(single(testImg), 'SSCB');
if useGPU, dlTest = gpuArray(dlTest); end

dlPred  = predict(net, dlTest);
predMask = onehotdecode(dlPred, classNames, 3);

figure;
tiledlayout(1, 2);
nexttile; imshow(testImg, []); title('Input');
nexttile; imshow(labeloverlay(mat2gray(testImg), predMask, Transparency=0.3));
title('Prediction Overlay');

%% Step 7: Save model
if ~isfolder(outputDir), mkdir(outputDir); end
save(fullfile(outputDir, 'customTrainedNet.mat'), 'net', 'lossHistory');
fprintf('Model saved to %s\n', outputDir);

%% ---- Local Functions ----

function [loss, gradients] = modelLoss(net, dlX, dlY, numClasses, diceWeight)
    % Forward pass
    dlYPred = forward(net, dlX);

    % Cross-entropy loss
    ceLoss = crossentropy(dlYPred, dlY, TargetCategories="independent");

    % Dice loss
    smooth = 1e-6;
    intersection = sum(dlYPred .* dlY, [1 2]);
    diceCoeff = (2 * intersection + smooth) ./ ...
                (sum(dlYPred, [1 2]) + sum(dlY, [1 2]) + smooth);
    diceLoss = 1 - mean(diceCoeff, "all");

    % Combined loss
    loss = diceWeight * diceLoss + (1 - diceWeight) * ceLoss;

    % Compute gradients
    gradients = dlgradient(loss, net.Learnables);
end

function [X, Y] = preprocessMiniBatch(images, labels)
    % Concatenate and normalize images
    X = cat(4, images{:});
    X = single(X) / 255;

    % One-hot encode labels
    Y = cat(4, labels{:});
    Y = onehotencode(Y, 3);
end
