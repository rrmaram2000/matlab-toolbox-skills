%% Mask R-CNN Instance Segmentation for Cell Nuclei in H&E Histopathology
% Train a Mask R-CNN to detect and segment individual cell nuclei in
% H&E-stained histopathology images, with inference and visualization.
%
% MATLAB R2025b | Deep Learning Toolbox | Computer Vision Toolbox
%
% Requirements:
%   - Deep Learning Toolbox
%   - Computer Vision Toolbox

%% Step 1: Configure data paths and parameters
imageDir      = '';     % Path to H&E histopathology images
annotationFile = '';    % Path to annotation MAT file
outputDir     = '';     % Path to save trained model
inputSize     = [512 512 3];
numClasses    = 1;      % nucleus
numEpochs     = 20;
miniBatchSize = 2;
initialLR     = 1e-4;

%% Step 2: Load and prepare training data
% Load annotations (table with: imageFilename, nucleus, masks)
load(annotationFile, 'trainingData');

fprintf("Training data: %d images\n", height(trainingData));

%% Step 3: Split into training and validation
rng(42);
idx = randperm(height(trainingData));
splitIdx = round(0.8 * height(trainingData));
trainData = trainingData(idx(1:splitIdx), :);
valData   = trainingData(idx(splitIdx+1:end), :);

fprintf("Training: %d | Validation: %d\n", height(trainData), height(valData));

%% Step 4: Create Mask R-CNN Object Detector
% Use the trainMaskRCNNObjectDetector function to create and train
% the Mask R-CNN model in one step

% First, define the network backbone
backbone = resnet50();

% Configure the Mask R-CNN detector
options = trainingOptions("adam", ...
    InitialLearnRate=initialLR, ...
    MaxEpochs=numEpochs, ...
    MiniBatchSize=miniBatchSize, ...
    Shuffle="every-epoch", ...
    Verbose=true, ...
    Plots="training-progress");

%% Step 5: Train Mask R-CNN with trainMaskRCNNObjectDetector
% This function handles detector creation and training together
trainedDetector = trainMaskRCNNObjectDetector(trainData, backbone, options, ...
    "InputSize", inputSize, ...
    "NumClasses", numClasses, ...
    "NegativeOverlapRange", [0 0.3], ...
    "PositiveOverlapRange", [0.5 1]);

fprintf("Training complete.\n");

%% Step 6: Run inference on a test image
testImg = imread(valData.imageFilename{1});
testImg = imresize(testImg, inputSize(1:2));

% Detect objects and get instance masks
[bboxes, scores, labels, masks] = detect(trainedDetector, testImg, ...
    "Threshold", 0.5);

fprintf("Detected %d nuclei\n", numel(scores));

%% Step 7: Visualize results
figure("Name", "Mask R-CNN Nuclei Detection", "Position", [50 50 1200 400]);

% Original
subplot(1, 3, 1);
imshow(testImg);
title("Input H&E Image");

% Bounding boxes
subplot(1, 3, 2);
if ~isempty(bboxes)
    annotatedImg = insertObjectAnnotation(testImg, "rectangle", bboxes, ...
        compose("%.0f%%", scores * 100), LineWidth=2);
    imshow(annotatedImg);
else
    imshow(testImg);
end
title(sprintf("Detected: %d nuclei", numel(scores)));

% Instance masks
subplot(1, 3, 3);
if ~isempty(masks)
    overlayImg = testImg;
    cmap = lines(size(masks, 3));
    for k = 1:size(masks, 3)
        m = masks(:,:,k);
        for ch = 1:3
            c = overlayImg(:,:,ch);
            c(m) = uint8(double(c(m)) * 0.5 + cmap(k,ch) * 255 * 0.5);
            overlayImg(:,:,ch) = c;
        end
    end
    imshow(overlayImg);
else
    imshow(testImg);
end
title("Instance Masks");

sgtitle("Mask R-CNN Cell Nuclei Instance Segmentation");

%% Step 8: Compute basic metrics
fprintf("\n--- Detection Metrics ---\n");
fprintf("Mean confidence: %.3f\n", mean(scores));
fprintf("Total detections: %d\n", numel(scores));

%% Step 9: Save model
if ~isfolder(outputDir), mkdir(outputDir); end
save(fullfile(outputDir, "trainedMaskRCNN.mat"), "trainedDetector");
fprintf("Model saved to: %s\n", outputDir);
