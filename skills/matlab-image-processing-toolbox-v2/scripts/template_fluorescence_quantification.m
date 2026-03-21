%% Template: Fluorescence Microscopy Quantification
% Multi-channel fluorescence analysis: channel separation, background
% subtraction, per-cell intensity measurement, and statistical reporting.
% MATLAB R2025b | Image Processing Toolbox
%
% Usage:
%   1. Fill in all TODO sections with your data
%   2. Run section-by-section or as complete script
%
% Requirements:
%   - Image Processing Toolbox

%% TODO: Configure your data paths and parameters
inputPath   = '';      % TODO: Path to multi-channel fluorescence image (RGB or multi-page TIFF)
outputDir   = '';      % TODO: Path to save results
channelNames = {'DAPI', 'GFP', 'RFP'};  % TODO: Channel names (match your staining)
minCellArea  = 100;    % TODO: Minimum cell/nucleus area in pixels
bgRadius     = 50;     % TODO: Rolling ball radius for background estimation

%% Step 1: Load Multi-Channel Image
img = imread(inputPath);
fprintf('Image loaded: %d x %d\n', size(img, 1), size(img, 2));

% Separate channels
if size(img, 3) >= 3
    channels = cell(1, 3);
    channels{1} = im2double(img(:, :, 1));  % Red / Channel 1
    channels{2} = im2double(img(:, :, 2));  % Green / Channel 2
    channels{3} = im2double(img(:, :, 3));  % Blue / Channel 3
    numChannels = 3;
else
    % Single-channel image
    channels = {im2double(img)};
    numChannels = 1;
    channelNames = {'Channel1'};
end

%% Step 2: Background Subtraction (Rolling Ball Method)
bgSubtracted = cell(1, numChannels);
backgrounds  = cell(1, numChannels);

for ch = 1:numChannels
    % Estimate background using morphological opening (rolling ball)
    seRoll = strel("disk", bgRadius);
    backgrounds{ch} = imopen(channels{ch}, seRoll);

    % Subtract background and clip negatives
    bgSubtracted{ch} = channels{ch} - backgrounds{ch};
    bgSubtracted{ch} = max(bgSubtracted{ch}, 0);

    fprintf('%s background range: [%.4f, %.4f]\n', ...
        channelNames{ch}, min(backgrounds{ch}(:)), max(backgrounds{ch}(:)));
end

%% Step 3: Nuclear Segmentation from DAPI/Reference Channel
% TODO: Adjust nuclearCh to match your DAPI or nuclear stain channel index
nuclearCh = 3;  % TODO: Channel index for nuclear stain (e.g., 3 for blue/DAPI)

nuclearImg = bgSubtracted{nuclearCh};

% Enhance contrast
nuclearEnhanced = adapthisteq(nuclearImg, 'ClipLimit', 0.03, 'NumTiles', [8 8]);

% Smooth before thresholding (R2025b: 'replicate' padding by default)
nuclearSmooth = imgaussfilt(nuclearEnhanced, 2.0);

% Threshold nuclei
nuclearMask = imbinarize(nuclearSmooth, 'adaptive', ...
    'ForegroundPolarity', 'bright', ...
    'Sensitivity',        0.5);  % TODO: Adjust sensitivity

% Morphological cleanup
se = strel("disk", 2);
nuclearMask = imopen(nuclearMask, se);
nuclearMask = imfill(nuclearMask, 'holes');
nuclearMask = bwareaopen(nuclearMask, minCellArea);

% Watershed to separate touching nuclei
D = -bwdist(~nuclearMask);
D = imhmin(D, 2);
L = watershed(D);
nuclearMask(L == 0) = false;

% Final labeling
cc = bwconncomp(nuclearMask);
labelMap = labelmatrix(cc);
numCells = cc.NumObjects;
fprintf('Detected %d nuclei/cells\n', numCells);

%% Step 4: Measure Fluorescence Intensity Per Cell Per Channel
% Pre-allocate results table
cellIDs = (1:numCells)';
resultsData = table(cellIDs, 'VariableNames', {'CellID'});

for ch = 1:numChannels
    chImg = bgSubtracted{ch};

    % Measure per-cell intensities
    chStats = regionprops("table", cc, chImg, ...
        "MeanIntensity", "MaxIntensity", "Area", "Centroid");

    % Add to results table
    meanName = sprintf('%s_MeanIntensity', channelNames{ch});
    maxName  = sprintf('%s_MaxIntensity', channelNames{ch});
    resultsData.(meanName) = chStats.MeanIntensity;
    resultsData.(maxName)  = chStats.MaxIntensity;
end

% Add area and centroid (from first channel measurement)
baseStats = regionprops("table", cc, "Area", "Centroid");
resultsData.Area = baseStats.Area;
resultsData.CentroidX = baseStats.Centroid(:, 1);
resultsData.CentroidY = baseStats.Centroid(:, 2);

%% Step 5: Compute Summary Statistics Per Channel
fprintf('\n--- Fluorescence Intensity Summary ---\n');
for ch = 1:numChannels
    meanCol = sprintf('%s_MeanIntensity', channelNames{ch});
    vals = resultsData.(meanCol);
    fprintf('%s:\n', channelNames{ch});
    fprintf('  Mean +/- SD: %.4f +/- %.4f\n', mean(vals), std(vals));
    fprintf('  Median:      %.4f\n', median(vals));
    fprintf('  Range:       [%.4f, %.4f]\n', min(vals), max(vals));
end

%% Step 6: Classify Cells by Expression Level (Optional)
% TODO: Define threshold for positive/negative classification
positiveThreshold = 0.1;  % TODO: Adjust based on your data
classifyCh = 2;           % TODO: Channel to classify (e.g., 2 for GFP)

classifyCol = sprintf('%s_MeanIntensity', channelNames{classifyCh});
isPositive = resultsData.(classifyCol) > positiveThreshold;
numPositive = sum(isPositive);
fprintf('\n%s positive cells: %d / %d (%.1f%%)\n', ...
    channelNames{classifyCh}, numPositive, numCells, 100 * numPositive / numCells);

%% Step 7: Visualize Multi-Channel Composite
% Create false-color composite
composite = zeros([size(channels{1}), 3]);
if numChannels >= 1
    composite(:, :, 1) = mat2gray(bgSubtracted{1});  % Red channel
end
if numChannels >= 2
    composite(:, :, 2) = mat2gray(bgSubtracted{2});  % Green channel
end
if numChannels >= 3
    composite(:, :, 3) = mat2gray(bgSubtracted{3});  % Blue channel
end

figure('Name', 'Fluorescence Channels', 'Position', [30 30 1400 500]);

for ch = 1:numChannels
    subplot(2, numChannels, ch);
    imshow(bgSubtracted{ch}, []);
    title(sprintf('%s (BG corrected)', channelNames{ch}));
end

subplot(2, numChannels, numChannels + 1);
imshow(composite);
title('Composite');

subplot(2, numChannels, numChannels + 2);
rgbLabels = label2rgb(labelMap, 'jet', 'k', 'shuffle');
imshow(rgbLabels);
title(sprintf('Segmented Cells (%d)', numCells));

if numChannels >= 3
    subplot(2, numChannels, numChannels + 3);
    % Heatmap of fluorescence intensity
    heatmap_img = zeros(size(nuclearMask));
    for k = 1:numCells
        heatmap_img(cc.PixelIdxList{k}) = resultsData.(sprintf('%s_MeanIntensity', ...
            channelNames{classifyCh}))(k);
    end
    imshow(heatmap_img, []);
    colormap(gca, hot);
    colorbar;
    title(sprintf('%s Intensity Map', channelNames{classifyCh}));
end

sgtitle('Fluorescence Microscopy Quantification');

%% Step 8: Intensity Distribution Plots
figure('Name', 'Intensity Distributions');
for ch = 1:numChannels
    subplot(1, numChannels, ch);
    meanCol = sprintf('%s_MeanIntensity', channelNames{ch});
    histogram(resultsData.(meanCol), 30);
    xlabel('Mean Intensity');
    ylabel('Cell Count');
    title(channelNames{ch});
end
sgtitle('Per-Cell Fluorescence Distributions');

%% Step 9: Save Results
if ~isempty(outputDir)
    if ~isfolder(outputDir), mkdir(outputDir); end
    writetable(resultsData, fullfile(outputDir, 'fluorescence_measurements.csv'));
    imwrite(composite, fullfile(outputDir, 'composite.png'));
    imwrite(uint8(nuclearMask * 255), fullfile(outputDir, 'nuclear_mask.png'));
    imwrite(rgbLabels, fullfile(outputDir, 'cell_labels.png'));
    fprintf('Results saved to: %s\n', outputDir);
end

%% Summary
fprintf('\n--- Fluorescence Quantification Summary ---\n');
fprintf('Total cells analyzed: %d\n', numCells);
fprintf('Channels processed:   %d\n', numChannels);
for ch = 1:numChannels
    meanCol = sprintf('%s_MeanIntensity', channelNames{ch});
    fprintf('  %s mean intensity: %.4f +/- %.4f\n', ...
        channelNames{ch}, mean(resultsData.(meanCol)), std(resultsData.(meanCol)));
end
