%% Template: Ground Truth Labeling Workflow
% Set up labeling workflow for medical image annotation. Define labels,
% launch labeler apps, export annotations for deep learning training.
% MATLAB R2025b | Medical Imaging Toolbox
%
% Usage:
%   1. Fill in all TODO sections with your data
%   2. Run section-by-section or as complete script
%
% Requirements:
%   - Medical Imaging Toolbox
%   - Image Processing Toolbox
%   - Computer Vision Toolbox (for imageLabeler)

%% TODO: Configure your data paths and parameters
imageDir = '';    % TODO: Path to directory of 2D images (e.g., '/data/slices/')
volumeDir = '';   % TODO: Path to directory of 3D volumes (e.g., '/data/volumes/')
outputDir = '';   % TODO: Path to save labeled data and exports

%% Step 1: Prepare the image datastore
% TODO: Adjust file extensions to match your data format
imds = imageDatastore(imageDir, ...
    'FileExtensions', {'.png', '.jpg', '.tif', '.dcm'}, ...
    'ReadFcn', @(x) im2gray(imread(x)));
fprintf('Image datastore created with %d images\n', numel(imds.Files));

%% Step 2: Define label definitions for 2D labeling
% TODO: Customize labels for your annotation task
labelDefs = labelDefinitionCreator();
addLabel(labelDefs, 'Background', 'PixelLabel', 'Description', 'Background tissue');
addLabel(labelDefs, 'Lesion', 'PixelLabel', 'Description', 'Pathological region');
addLabel(labelDefs, 'Organ', 'PixelLabel', 'Description', 'Target organ boundary');
addLabel(labelDefs, 'Nodule', 'Rectangle', 'Description', 'Detected nodule');
% TODO: Add more labels as needed
fprintf('Label definitions created\n');

%% Step 3: Launch 2D Image Labeler
% TODO: Uncomment to launch the interactive labeler app
% imageLabeler(imds, labelDefs);
fprintf('To launch labeler: uncomment imageLabeler(imds, labelDefs)\n');

%% Step 4: Launch 3D Volume Labeler (optional)
% TODO: Uncomment for 3D volume labeling
% volFiles = dir(fullfile(volumeDir, '*.nii.gz'));
% if ~isempty(volFiles)
%     V = niftiread(fullfile(volFiles(1).folder, volFiles(1).name));
%     volumeLabeler(V);
% end

%% Step 5: Export labeled data from saved session
% TODO: Set path to your exported ground truth MAT file
gtSessionFile = '';  % TODO: Path to saved ground truth

if ~isempty(gtSessionFile) && isfile(gtSessionFile)
    gtData = load(gtSessionFile);
    gTruth = gtData.gTruth;  % TODO: Adjust variable name
    fprintf('Ground truth loaded: %d labeled images\n', height(gTruth.LabelData));
else
    fprintf('No ground truth session specified.\n');
    gTruth = [];
end

%% Step 6: Convert ground truth to training-ready format
if ~isempty(gTruth)
    trainImageDir = fullfile(outputDir, 'train', 'images');
    trainLabelDir = fullfile(outputDir, 'train', 'labels');
    if ~isfolder(trainImageDir), mkdir(trainImageDir); end
    if ~isfolder(trainLabelDir), mkdir(trainLabelDir); end

    imageFiles = gTruth.DataSource.Source;
    for i = 1:height(gTruth.LabelData)
        [~, fname, ext] = fileparts(imageFiles{i});
        copyfile(imageFiles{i}, fullfile(trainImageDir, [fname, ext]));
        labelMap = readLabelImage(gTruth, i);
        imwrite(uint8(labelMap), fullfile(trainLabelDir, [fname, '_label.png']));
    end
    fprintf('Exported %d labeled images\n', height(gTruth.LabelData));
end

%% Step 7: Create pixelLabelDatastore for deep learning
% TODO: Adjust class names and pixel label IDs to match your labels
classNames = ["Background", "Lesion", "Organ"];
pixelLabelIDs = [0, 1, 2];

if isfolder(fullfile(outputDir, 'train', 'labels'))
    trainImds = imageDatastore(fullfile(outputDir, 'train', 'images'));
    trainPxds = pixelLabelDatastore(fullfile(outputDir, 'train', 'labels'), ...
        classNames, pixelLabelIDs);
    trainingData = combine(trainImds, trainPxds);
    fprintf('Training data ready: %d images, classes: %s\n', ...
        numel(trainImds.Files), strjoin(classNames, ', '));
end

%% Step 8: Compute class balance and weights
if isfolder(fullfile(outputDir, 'train', 'labels'))
    labelFiles = dir(fullfile(outputDir, 'train', 'labels', '*.png'));
    classCounts = zeros(1, length(classNames));
    for i = 1:length(labelFiles)
        L = imread(fullfile(labelFiles(i).folder, labelFiles(i).name));
        for c = 1:length(pixelLabelIDs)
            classCounts(c) = classCounts(c) + nnz(L == pixelLabelIDs(c));
        end
    end
    classFreqs = classCounts / sum(classCounts);
    classWeights = (1 ./ classFreqs) / sum(1 ./ classFreqs) * length(classNames);

    fprintf('\n=== Class Balance ===\n');
    for c = 1:length(classNames)
        fprintf('  %s: %.1f%% (weight: %.2f)\n', ...
            classNames(c), 100*classFreqs(c), classWeights(c));
    end
end

disp('=== Labeling Workflow Complete ===');
