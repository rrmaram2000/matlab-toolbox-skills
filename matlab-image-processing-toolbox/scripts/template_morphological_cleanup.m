%% Template: Binary Mask Morphological Cleanup Pipeline
% Step-by-step morphological operations to clean binary masks: opening,
% closing, hole filling, area filtering, bridging, and thinning.
% Visualizes before/after at each stage.
% MATLAB R2025b | Image Processing Toolbox
%
% Usage:
%   1. Fill in all TODO sections with your data
%   2. Run section-by-section or as complete script
%
% Requirements:
%   - Image Processing Toolbox

%% TODO: Configure your data paths and parameters
inputPath     = '';    % TODO: Path to input image (or binary mask)
outputDir     = '';    % TODO: Path to save results
openRadius    = 3;     % TODO: Disk radius for opening (removes small noise)
closeRadius   = 5;     % TODO: Disk radius for closing (fills small gaps)
minArea       = 200;   % TODO: Minimum object area in pixels to keep
bridgeIter    = 1;     % TODO: Number of bridging iterations

%% Step 1: Load Image and Create Initial Binary Mask
img = imread(inputPath);
if size(img, 3) == 3
    grayImg = rgb2gray(img);
else
    grayImg = img;
end
grayImg = im2double(grayImg);

% Create binary mask using Otsu thresholding
bwOriginal = imbinarize(grayImg);

% TODO: Invert if foreground is dark
% bwOriginal = ~bwOriginal;

fprintf('Initial mask: %d foreground pixels (%.1f%%)\n', ...
    sum(bwOriginal(:)), 100 * sum(bwOriginal(:)) / numel(bwOriginal));

%% Step 2: Opening — Remove Small Noise Specks
seOpen = strel("disk", openRadius);
bwOpened = imopen(bwOriginal, seOpen);
removedNoise = sum(bwOriginal(:)) - sum(bwOpened(:));
fprintf('Opening (r=%d): removed %d noise pixels\n', openRadius, removedNoise);

%% Step 3: Closing — Fill Small Gaps and Smooth Boundaries
seClose = strel("disk", closeRadius);
bwClosed = imclose(bwOpened, seClose);
filledGaps = sum(bwClosed(:)) - sum(bwOpened(:));
fprintf('Closing (r=%d): filled %d gap pixels\n', closeRadius, filledGaps);

%% Step 4: Fill Holes — Remove Internal Holes
bwFilled = imfill(bwClosed, 'holes');
filledHoles = sum(bwFilled(:)) - sum(bwClosed(:));
fprintf('Hole filling: filled %d hole pixels\n', filledHoles);

%% Step 5: Area Filtering — Remove Small Objects
bwAreaFiltered = bwareaopen(bwFilled, minArea);

% Count removed objects
ccBefore = bwconncomp(bwFilled);
ccAfter = bwconncomp(bwAreaFiltered);
removedObjects = ccBefore.NumObjects - ccAfter.NumObjects;
fprintf('Area filter (min=%d): removed %d small objects\n', minArea, removedObjects);

%% Step 6: Bridge Gaps Between Nearby Objects
bwBridged = bwmorph(bwAreaFiltered, 'bridge', bridgeIter);
bridgedPixels = sum(bwBridged(:)) - sum(bwAreaFiltered(:));
fprintf('Bridging (%d iter): added %d bridge pixels\n', bridgeIter, bridgedPixels);

%% Step 7: Thinning — Skeletonize Structures (Optional)
bwThinned = bwmorph(bwBridged, 'thin', Inf);
fprintf('Thinning: skeleton has %d pixels\n', sum(bwThinned(:)));

%% Step 8: Final Cleanup — Smooth Boundaries with Dilation/Erosion
seFinal = strel("disk", 1);
bwFinal = imdilate(bwBridged, seFinal);
bwFinal = imerode(bwFinal, seFinal);

%% Step 9: Measure Final Objects
ccFinal = bwconncomp(bwFinal);
stats = regionprops("table", ccFinal, "Area", "Perimeter", "Circularity", "Centroid");
fprintf('Final mask: %d objects\n', ccFinal.NumObjects);

%% Step 10: Visualize All Steps — Before/After Comparison
stages = {bwOriginal, bwOpened, bwClosed, bwFilled, bwAreaFiltered, bwBridged, bwFinal};
titles = {'Original Mask', 'After Opening', 'After Closing', ...
          'After Hole Fill', 'After Area Filter', 'After Bridging', 'Final Cleanup'};

nStages = numel(stages);
figure('Name', 'Morphological Cleanup Pipeline', 'Position', [30 30 250*nStages 350]);

for k = 1:nStages
    subplot(1, nStages, k);
    imshow(stages{k});
    title(titles{k}, 'FontSize', 8);
end
sgtitle('Morphological Cleanup — Step by Step');

%% Step 11: Side-by-Side Original vs Final
figure('Name', 'Before vs After Cleanup', 'Position', [100 100 900 400]);

subplot(1, 2, 1);
imshow(bwOriginal);
title(sprintf('Before: %d objects', bwconncomp(bwOriginal).NumObjects));

subplot(1, 2, 2);
imshow(bwFinal);
title(sprintf('After: %d objects', ccFinal.NumObjects));

sgtitle('Morphological Cleanup Result');

%% Step 12: Save Results
if ~isempty(outputDir)
    if ~isfolder(outputDir), mkdir(outputDir); end
    imwrite(bwFinal, fullfile(outputDir, 'mask_cleaned.png'));
    imwrite(bwThinned, fullfile(outputDir, 'mask_skeleton.png'));
    writetable(stats, fullfile(outputDir, 'object_measurements.csv'));
    % Save each stage for documentation
    for k = 1:nStages
        fname = sprintf('stage_%d_%s.png', k, strrep(lower(titles{k}), ' ', '_'));
        imwrite(stages{k}, fullfile(outputDir, fname));
    end
    fprintf('All results saved to: %s\n', outputDir);
end

%% Summary
fprintf('\n--- Morphological Cleanup Summary ---\n');
fprintf('Objects before cleanup: %d\n', bwconncomp(bwOriginal).NumObjects);
fprintf('Objects after cleanup:  %d\n', ccFinal.NumObjects);
fprintf('Foreground before: %.1f%%\n', 100 * sum(bwOriginal(:)) / numel(bwOriginal));
fprintf('Foreground after:  %.1f%%\n', 100 * sum(bwFinal(:)) / numel(bwFinal));
