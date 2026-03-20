%% Mask R-CNN Instance Segmentation for Cell Nuclei in H&E Histopathology
% Train a Mask R-CNN to detect and segment individual cell nuclei in
% H&E-stained histopathology images, with inference and visualization.
%
% MATLAB R2025b | Deep Learning Toolbox | Computer Vision Toolbox
%
% Requirements:
%   - Deep Learning Toolbox
%   - Computer Vision Toolbox
%
% Workflow:
%   1. Load and prepare annotated training data
%   2. Create Mask R-CNN detector with ResNet-50-FPN backbone
%   3. Configure training options for instance segmentation
%   4. Train using trainMaskRCNN (correct R2025b API)
%   5. Run inference with segmentObjects
%   6. Visualize instance masks with per-nucleus coloring
%   7. Compute quantitative metrics (count, area distribution)

%% ---- USER CONFIGURATION ----
imageDir      = '';     % TODO: Folder with H&E histopathology images
annotationFile = '';    % TODO: Path to annotation MAT file (Ground Truth Labeler export)
outputDir     = '';     % TODO: Path to save trained model and results
inputSize     = [512 512 3];
classNames    = ["nucleus"];  % Instance class (no background class needed)
numEpochs     = 20;
miniBatchSize = 2;      % Mask R-CNN is memory-intensive; keep small
initialLR     = 1e-4;

%% Step 1: Load and prepare training data
% Mask R-CNN expects a table with columns:
%   - imageFilename: full path to each image
%   - <className>:   M-by-4 bounding boxes [x y w h] for each instance
%   - masks:         M-by-1 cell array of binary masks (H x W logical)
%
% Typically exported from Image Labeler or Ground Truth Labeler app.

load(annotationFile, 'trainingData');  % TODO: Replace with your data loading

assert(ismember('imageFilename', trainingData.Properties.VariableNames), ...
    'Table must contain imageFilename column.');
assert(ismember('masks', trainingData.Properties.VariableNames), ...
    'Table must contain masks column for instance segmentation.');

fprintf('Training data: %d images\n', height(trainingData));

% Count total nuclei instances
totalInstances = 0;
for i = 1:height(trainingData)
    if iscell(trainingData.masks{i})
        totalInstances = totalInstances + numel(trainingData.masks{i});
    end
end
fprintf('Total nuclei instances: %d\n', totalInstances);

%% Step 2: Split into training and validation sets
rng(42);  % Reproducibility
idx = randperm(height(trainingData));
splitIdx = round(0.8 * height(trainingData));
trainData = trainingData(idx(1:splitIdx), :);
valData   = trainingData(idx(splitIdx+1:end), :);

fprintf('Training: %d images | Validation: %d images\n', ...
    height(trainData), height(valData));

%% Step 3: Create Mask R-CNN detector
% maskrcnn() creates a Mask R-CNN detector with ResNet-50-FPN backbone
% This is the correct R2025b constructor — NOT trainMaskRCNNObjectDetector
detector = maskrcnn("resnet50-coco", classNames, InputSize=inputSize);

fprintf('Mask R-CNN detector created with ResNet-50-FPN backbone\n');
fprintf('  Input size: [%d x %d x %d]\n', inputSize);
fprintf('  Classes: %s\n', strjoin(classNames, ', '));

%% Step 4: Configure training options
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

%% Step 5: Train Mask R-CNN
% trainMaskRCNN is the correct training function in R2025b
% NOT trainMaskRCNNObjectDetector (which does not exist)
[trainedDetector, trainingInfo] = trainMaskRCNN(trainData, detector, options);

fprintf('Training complete.\n');
fprintf('  Final training loss: %.4f\n', trainingInfo.TrainingLoss(end));

%% Step 6: Run inference on a test image
testImg = imread(valData.imageFilename{1});  % TODO: Replace with your test image
testImg = imresize(testImg, inputSize(1:2));

% segmentObjects returns instance masks, labels, scores, and bounding boxes
[masks, labels, scores, bboxes] = segmentObjects(trainedDetector, testImg, ...
    Threshold=0.5);

fprintf('Detected %d nuclei in test image (threshold=0.5)\n', numel(scores));

%% Step 7: Visualize instance segmentation results
figure('Name', 'Mask R-CNN Nuclei Detection', 'Position', [50 50 1400 450]);
tiledlayout(1, 3, 'TileSpacing', 'compact');

% Panel 1: Original image
nexttile;
imshow(testImg);
title('Input H&E Image', 'FontSize', 12);

% Panel 2: Bounding boxes with confidence scores
nexttile;
if ~isempty(bboxes)
    annotatedImg = insertObjectAnnotation(testImg, 'rectangle', bboxes, ...
        compose("nucleus %.0f%%", scores * 100), ...
        LineWidth=2, FontSize=10, Color='green');
    imshow(annotatedImg);
else
    imshow(testImg);
end
title(sprintf('Detected Nuclei: %d', numel(scores)), 'FontSize', 12);

% Panel 3: Instance mask overlay with per-nucleus coloring
nexttile;
if ~isempty(masks)
    overlayImg = testImg;
    colorMap = lines(size(masks, 3));  % Distinct color per instance
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
title('Instance Masks (per-nucleus coloring)', 'FontSize', 12);

sgtitle('Mask R-CNN Cell Nuclei Instance Segmentation');

%% Step 8: Quantitative evaluation on validation set
fprintf('\n=== Validation Evaluation ===\n');
allScores = [];
allAreas  = [];

for i = 1:height(valData)
    img = imread(valData.imageFilename{i});
    img = imresize(img, inputSize(1:2));
    [m, ~, s, ~] = segmentObjects(trainedDetector, img, Threshold=0.3);
    allScores = [allScores; s(:)]; %#ok<AGROW>

    % Compute area of each detected nucleus
    for j = 1:size(m, 3)
        allAreas = [allAreas; nnz(m(:,:,j))]; %#ok<AGROW>
    end

    if mod(i, 10) == 0
        fprintf('  Processed %d/%d validation images\n', i, height(valData));
    end
end

fprintf('\nDetection Summary:\n');
fprintf('  Total detections: %d across %d images\n', numel(allScores), height(valData));
fprintf('  Mean confidence: %.3f\n', mean(allScores));
fprintf('  Mean nucleus area: %.1f pixels\n', mean(allAreas));
fprintf('  Median nucleus area: %.1f pixels\n', median(allAreas));

% Plot nucleus area distribution
figure('Name', 'Nucleus Area Distribution');
histogram(allAreas, 50, 'FaceColor', [0.2 0.6 0.9]);
xlabel('Nucleus Area (pixels)');
ylabel('Count');
title('Distribution of Detected Nucleus Areas');
grid on;

%% Step 9: Save trained detector and results
if ~isfolder(outputDir), mkdir(outputDir); end
save(fullfile(outputDir, 'trainedMaskRCNN.mat'), 'trainedDetector', 'trainingInfo');
fprintf('\nMask R-CNN saved to: %s\n', fullfile(outputDir, 'trainedMaskRCNN.mat'));

% Save visualization
saveas(gcf, fullfile(outputDir, 'nucleus_area_distribution.png'));
fprintf('Results saved to: %s\n', outputDir);

fprintf('\n=== Mask R-CNN Nuclei Segmentation Complete ===\n');
