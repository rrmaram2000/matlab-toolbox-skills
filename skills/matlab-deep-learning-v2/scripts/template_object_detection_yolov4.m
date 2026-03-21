%% Template: YOLOv4 Object Detection for Nodule/Lesion Detection
% Train a YOLOv4 detector for localizing nodules, lesions, or other
% structures in medical images with bounding box annotations.
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
dataDir    = '';   % TODO: Folder containing training images
outputDir  = '';   % TODO: Path to save trained detector
inputSize  = [416 416 3];
classNames = ["nodule"];  % TODO: Your object classes
numEpochs  = 30;
miniBatchSize = 8;
initialLR  = 1e-3;

%% Step 1: Load ground truth bounding box data
% TODO: Load your bounding box annotations into a table
% The table must have columns: imageFilename (char), plus one column per
% class containing M-by-4 bounding boxes [x y w h]
%
% Example:
%   gTruth = objectDetectorTrainingData(groundTruthObj);
%   or load from a MAT file:
%   load('annotations.mat', 'trainingData');
trainingData = table();  % TODO: Replace with your actual data table

%% Step 2: Verify data format
assert(ismember('imageFilename', trainingData.Properties.VariableNames), ...
    'Table must have an imageFilename column.');
for c = 1:numel(classNames)
    assert(ismember(classNames(c), trainingData.Properties.VariableNames), ...
        sprintf('Table must have a column for class: %s', classNames(c)));
end
fprintf('Loaded %d annotated images with %d classes.\n', ...
    height(trainingData), numel(classNames));

%% Step 3: Split into training and validation
idx = randperm(height(trainingData));
splitIdx = round(0.8 * height(trainingData));
trainData = trainingData(idx(1:splitIdx), :);
valData   = trainingData(idx(splitIdx+1:end), :);

%% Step 4: Estimate anchor boxes from training data
allBoxes = [];
for c = 1:numel(classNames)
    boxes = vertcat(trainData.(classNames(c)){:});
    allBoxes = [allBoxes; boxes]; %#ok<AGROW>
end
numAnchors = 6;  % TODO: Adjust (typically 6-9 for YOLOv4)
[anchorBoxes, meanIoU] = estimateAnchorBoxes(allBoxes, numAnchors);
fprintf('Estimated %d anchor boxes (mean IoU: %.3f)\n', numAnchors, meanIoU);

%% Step 5: Create YOLOv4 object detector
detector = yolov4ObjectDetector("csp-darknet53-coco", classNames, ...
    anchorBoxes, InputSize=inputSize);

%% Step 6: Configure training options
options = trainingOptions("adam", ...
    InitialLearnRate=initialLR, ...
    MaxEpochs=numEpochs, ...
    MiniBatchSize=miniBatchSize, ...
    ValidationData=valData, ...
    ValidationFrequency=100, ...
    LearnRateSchedule="piecewise", ...
    LearnRateDropPeriod=15, ...
    LearnRateDropFactor=0.1, ...
    Shuffle="every-epoch", ...
    Verbose=true, ...
    Plots="training-progress");

%% Step 7: Train the YOLOv4 detector
[trainedDetector, info] = trainYOLOv4ObjectDetector(trainData, detector, options);

%% Step 8: Run detection on a test image
testImg = imread(valData.imageFilename{1});  % TODO: Replace with your test image
[bboxes, scores, labels] = detect(trainedDetector, testImg, Threshold=0.5);

%% Step 9: Visualize detections with NMS
% Non-maximum suppression is handled internally by detect, but you can
% apply additional filtering:
if ~isempty(bboxes)
    [selectedBboxes, selectedScores] = selectStrongestBboxMulticlass( ...
        bboxes, scores, labels, ...
        RatioType="Min", OverlapThreshold=0.5);

    detImg = insertObjectAnnotation(testImg, 'rectangle', selectedBboxes, ...
        compose("%s %.2f", string(labels), selectedScores));
else
    detImg = testImg;
    fprintf('No detections above threshold.\n');
end

figure;
imshow(detImg);
title('YOLOv4 Detection Results');

%% Step 10: Evaluate with Average Precision
results = detect(trainedDetector, valData, Threshold=0.3);
[ap, recall, precision] = evaluateObjectDetection(results, valData, 0.5);
fprintf('Average Precision (AP@0.5): %.3f\n', ap);

figure;
plot(recall{1}, precision{1}, 'LineWidth', 2);
xlabel('Recall'); ylabel('Precision');
title(sprintf('Precision-Recall Curve (AP=%.3f)', ap));
grid on;

%% Step 11: Save trained detector
if ~isfolder(outputDir), mkdir(outputDir); end
save(fullfile(outputDir, 'trainedYOLOv4.mat'), 'trainedDetector', 'info');
fprintf('YOLOv4 detector saved to %s\n', outputDir);
