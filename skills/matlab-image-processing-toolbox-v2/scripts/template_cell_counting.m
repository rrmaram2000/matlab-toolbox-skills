%% Template: Automated Cell Counting Pipeline
% Segment and count cells from microscopy images using adaptive thresholding,
% morphological cleanup, watershed separation, and regionprops measurement.
% MATLAB R2025b | Image Processing Toolbox
%
% Usage:
%   1. Fill in all TODO sections with your data
%   2. Run section-by-section or as complete script
%
% Requirements:
%   - Image Processing Toolbox

%% TODO: Configure your data paths and parameters
inputPath  = '';    % TODO: Path to microscopy image
outputDir  = '';    % TODO: Path to save results
minCellArea = 100;  % TODO: Minimum cell area in pixels (removes debris)
maxCellArea = 5000; % TODO: Maximum cell area in pixels (removes clumps)

%% Step 1: Load and Convert Image
img = imread(inputPath);
if size(img, 3) == 3
    grayImg = rgb2gray(img);
else
    grayImg = img;
end
grayImg = im2double(grayImg);
fprintf('Image loaded: %d x %d pixels\n', size(grayImg, 1), size(grayImg, 2));

%% Step 2: Preprocessing — Enhance Contrast and Reduce Noise
% Apply CLAHE for uneven illumination correction
enhanced = adapthisteq(grayImg, 'ClipLimit', 0.02, 'NumTiles', [8 8]);

% Gaussian smoothing to reduce noise (R2025b: 'replicate' padding by default)
smoothed = imgaussfilt(enhanced, 1.5);  % TODO: Adjust sigma

%% Step 3: Adaptive Thresholding
% Use adaptive thresholding for uneven background
bw = imbinarize(smoothed, 'adaptive', ...
    'ForegroundPolarity', 'dark', ...   % TODO: 'dark' for dark cells, 'bright' for bright
    'Sensitivity',        0.45);        % TODO: Adjust sensitivity (0–1)

% Invert if cells are dark on bright background
bw = ~bw;  % TODO: Remove this line if cells are bright on dark background

%% Step 4: Morphological Cleanup
% Opening: remove small noise
seOpen = strel("disk", 2);  % TODO: Adjust radius
bw = imopen(bw, seOpen);

% Fill holes inside cells
bw = imfill(bw, 'holes');

% Remove objects smaller than minimum area
bw = bwareaopen(bw, minCellArea);

%% Step 5: Watershed Separation of Touching Cells
% Distance transform to find cell centers
D = -bwdist(~bw);

% Suppress shallow minima to reduce over-segmentation
D = imhmin(D, 2);  % TODO: Adjust h-minima depth

% Compute watershed
L = watershed(D);

% Combine watershed lines with binary mask
bwSeparated = bw;
bwSeparated(L == 0) = false;

%% Step 6: Filter by Size and Measure Properties
% Connected component analysis
cc = bwconncomp(bwSeparated);

% Measure properties using table output (R2025b standard)
stats = regionprops("table", cc, ...
    "Area", "Centroid", "Eccentricity", "MajorAxisLength", "MinorAxisLength");

% Filter by area range
validIdx = stats.Area >= minCellArea & stats.Area <= maxCellArea;
stats = stats(validIdx, :);

% Build filtered mask
filteredMask = false(size(bw));
validPixels = cc.PixelIdxList(validIdx);
for k = 1:numel(validPixels)
    filteredMask(validPixels{k}) = true;
end

cellCount = sum(validIdx);
fprintf('Detected %d cells\n', cellCount);

%% Step 7: Label and Overlay on Original Image
% Create labeled image for visualization
ccFinal = bwconncomp(filteredMask);
labelImg = labelmatrix(ccFinal);
rgbLabel = label2rgb(labelImg, 'jet', 'k', 'shuffle');

% Overlay boundaries on original
boundaries = bwperim(filteredMask);
overlayImg = img;
if size(overlayImg, 3) == 1
    overlayImg = repmat(overlayImg, [1 1 3]);
end
overlayImg(repmat(boundaries, [1 1 1])) = 255;

%% Step 8: Visualize Results
figure('Name', 'Cell Counting Pipeline', 'Position', [50 50 1400 400]);

subplot(1, 4, 1);
imshow(img);
title('Original');

subplot(1, 4, 2);
imshow(bw);
title('Binary Mask');

subplot(1, 4, 3);
imshow(bwSeparated);
title('Watershed Separated');

subplot(1, 4, 4);
imshow(rgbLabel);
title(sprintf('Counted: %d cells', cellCount));

sgtitle('Automated Cell Counting');

%% Step 9: Save Results
if ~isempty(outputDir)
    if ~isfolder(outputDir), mkdir(outputDir); end
    imwrite(filteredMask, fullfile(outputDir, 'cell_mask.png'));
    imwrite(rgbLabel, fullfile(outputDir, 'cell_labels.png'));
    writetable(stats, fullfile(outputDir, 'cell_measurements.csv'));
    fprintf('Results saved to: %s\n', outputDir);
end

%% Summary Statistics
fprintf('\n--- Cell Counting Summary ---\n');
fprintf('Total cells detected: %d\n', cellCount);
fprintf('Mean cell area:       %.1f pixels\n', mean(stats.Area));
fprintf('Std cell area:        %.1f pixels\n', std(stats.Area));
fprintf('Mean eccentricity:    %.3f\n', mean(stats.Eccentricity));
