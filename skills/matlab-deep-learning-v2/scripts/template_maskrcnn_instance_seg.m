%% Template: Mask R-CNN for Cell/Nuclei Instance Segmentation
% Train a Mask R-CNN for instance segmentation of cells, nuclei, or
% glands in histopathology and fluorescence microscopy images.
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
imageDir   = '';   % TODO: Folder containing microscopy/histopathology images
outputDir  = '';   % TODO: Path to save trained model
inputSize  = [512 512 3];
classNames = ["cell"];  % TODO: Your instance classes (no background needed)
numEpochs  = 20;
miniBatchSize = 2;      % Mask R-CNN is memory-intensive
initialLR  = 1e-4;

%% Step 1: Prepare training data
% Mask R-CNN requires a table with columns:
%   - imageFilename: full path to each image
%   - <className>: M-by-4 bounding boxes [x y w h] for each instance
%   - masks: M-by-1 cell array of binary masks (H x W logical)
%
% TODO: Load your annotations — typically from a labeled dataset or
% exported from Image Labeler / Ground Truth Labeler
%
% Example:
%   load('cellAnnotations.mat', 'trainingData');
%   trainingData = table with columns: imageFilename, cell, masks

trainingData = table();  % TODO: Replace with your annotation table

%% Step 2: Validate training data format
assert(ismember('imageFilename', trainingData.Properties.VariableNames), ...
    'Table must contain imageFilename column.');
assert(ismember('masks', trainingData.Properties.VariableNames), ...
    'Table must contain masks column for instance segmentation.');

fprintf('Training data: %d images with %d instance class(es).\n', ...
    height(trainingData), numel(classNames));

% Count instances per image
totalInstances = 0;
for i = 1:height(trainingData)
    if iscell(trainingData.masks{i})
        totalInstances = totalInstances + numel(trainingData.masks{i});
    end
end
fprintf('Total instances across dataset: %d\n', totalInstances);

%% Step 3: Split into training and validation
idx = randperm(height(trainingData));
splitIdx = round(0.8 * height(trainingData));
trainData = trainingData(idx(1:splitIdx), :);
valData   = trainingData(idx(splitIdx+1:end), :);

fprintf('Training: %d images | Validation: %d images\n', ...
    height(trainData), height(valData));

%% Step 4: Create Mask R-CNN detector
% maskrcnn creates a detector with a ResNet-50-FPN backbone
detector = maskrcnn("resnet50-coco", classNames, InputSize=inputSize);

%% Step 5: Configure training options
options = trainingOptions("adam", ...
    InitialLearnRate=initialLR, ...
    MaxEpochs=numEpochs, ...
    MiniBatchSize=miniBatchSize, ...
    ValidationData=valData, ...
    ValidationFrequency=100, ...
    LearnRateSchedule="piecewise", ...
    LearnRateDropPeriod=10, ...
    LearnRateDropFactor=0.1, ...
    Shuffle="every-epoch", ...
    Verbose=true, ...
    Plots="training-progress");

%% Step 6: Train Mask R-CNN
[trainedDetector, info] = trainMaskRCNN(trainData, detector, options);

%% Step 7: Run inference on a test image
testImg = imread(valData.imageFilename{1});  % TODO: Replace with test image
testImg = imresize(testImg, inputSize(1:2));

[masks, labels, scores, bboxes] = segmentObjects(trainedDetector, testImg, ...
    Threshold=0.5);

fprintf('Detected %d instances in test image.\n', numel(scores));

%% Step 8: Visualize instance segmentation results
figure('Position', [100 100 1200 400]);
tiledlayout(1, 3);

% Original image
nexttile;
imshow(testImg);
title('Input Image');

% Bounding boxes with scores
nexttile;
if ~isempty(bboxes)
    annotatedImg = insertObjectAnnotation(testImg, 'rectangle', bboxes, ...
        compose("%s %.2f", string(labels), scores), ...
        LineWidth=2, FontSize=12);
    imshow(annotatedImg);
else
    imshow(testImg);
end
title('Detected Instances');

% Instance mask overlay
nexttile;
if ~isempty(masks)
    overlayImg = testImg;
    colorMap = lines(size(masks, 3));
    for k = 1:size(masks, 3)
        mask = masks(:,:,k);
        for ch = 1:3
            channel = overlayImg(:,:,ch);
            channel(mask) = uint8(double(channel(mask)) * 0.5 + ...
                colorMap(k, ch) * 255 * 0.5);
            overlayImg(:,:,ch) = channel;
        end
    end
    imshow(overlayImg);
else
    imshow(testImg);
end
title('Instance Masks');

%% Step 9: Quantitative evaluation
% Run detection on all validation images
allResults = table(Size=[height(valData), 4], ...
    VariableTypes=["cell", "cell", "cell", "cell"], ...
    VariableNames=["Masks", "Labels", "Scores", "Boxes"]);

for i = 1:height(valData)
    img = imread(valData.imageFilename{i});
    img = imresize(img, inputSize(1:2));
    [m, l, s, b] = segmentObjects(trainedDetector, img, Threshold=0.3);
    allResults.Masks{i}  = m;
    allResults.Labels{i}  = l;
    allResults.Scores{i} = s;
    allResults.Boxes{i}  = b;
end

% Compute mean AP for bounding box detection
fprintf('\n=== Detection Performance ===\n');
fprintf('Total validation images: %d\n', height(valData));
fprintf('Mean detections per image: %.1f\n', ...
    mean(cellfun(@numel, allResults.Scores)));

%% Step 10: Save trained detector
if ~isfolder(outputDir), mkdir(outputDir); end
save(fullfile(outputDir, 'trainedMaskRCNN.mat'), 'trainedDetector', 'info');
fprintf('Mask R-CNN saved to %s\n', outputDir);
