%% Template: Multi-Level Adaptive Thresholding for Tissue Regions
% Compare global Otsu, adaptive local, and multi-level thresholding methods
% for segmenting tissue regions with uneven illumination.
% MATLAB R2025b | Image Processing Toolbox
%
% Usage:
%   1. Fill in all TODO sections with your data
%   2. Run section-by-section or as complete script
%
% Requirements:
%   - Image Processing Toolbox

%% TODO: Configure your data paths and parameters
inputPath  = '';   % TODO: Path to your tissue/histology image
outputDir  = '';   % TODO: Path to save results
numLevels  = 3;    % TODO: Number of threshold levels for multi-level
sensitivity = 0.5; % TODO: Adaptive threshold sensitivity (0–1)

%% Step 1: Load and Prepare Image
img = imread(inputPath);
if size(img, 3) == 3
    grayImg = rgb2gray(img);
else
    grayImg = img;
end
grayImg = im2double(grayImg);

% Light smoothing to reduce noise (R2025b: 'replicate' padding by default)
smoothed = imgaussfilt(grayImg, 1.0);

fprintf('Image loaded: %d x %d pixels, range [%.3f, %.3f]\n', ...
    size(grayImg, 1), size(grayImg, 2), min(grayImg(:)), max(grayImg(:)));

%% Step 2: Method 1 — Global Otsu Thresholding
bwOtsu = imbinarize(smoothed);
otsuThresh = graythresh(smoothed);
fprintf('Otsu threshold: %.4f\n', otsuThresh);

%% Step 3: Method 2 — Adaptive Local Thresholding
% Handles uneven illumination by computing local thresholds
bwAdaptive = imbinarize(smoothed, 'adaptive', ...
    'ForegroundPolarity', 'dark', ...  % TODO: 'dark' or 'bright'
    'Sensitivity',        sensitivity);

% Also try with 'bright' polarity for comparison
bwAdaptiveBright = imbinarize(smoothed, 'adaptive', ...
    'ForegroundPolarity', 'bright', ...
    'Sensitivity',        sensitivity);

%% Step 4: Method 3 — Multi-Level Thresholding with multithresh + imquantize
% Find optimal thresholds using Otsu's multi-level method
thresholds = multithresh(smoothed, numLevels);
quantized = imquantize(smoothed, thresholds);

% Normalize quantized image for display
quantizedDisplay = mat2gray(double(quantized));

fprintf('Multi-level thresholds (%d levels):\n', numLevels);
for k = 1:numel(thresholds)
    fprintf('  Level %d: %.4f\n', k, thresholds(k));
end

%% Step 5: Method 4 — Local Mean Thresholding (Manual Implementation)
% Compute local mean as threshold surface
localMean = imfilter(smoothed, fspecial('average', [31 31]), 'replicate');

% Threshold: pixel is foreground if darker than local mean minus offset
offset = 0.05;  % TODO: Adjust offset for sensitivity
bwLocalMean = smoothed < (localMean - offset);

%% Step 6: Method 5 — Illumination Correction + Global Threshold
% Estimate background illumination with morphological opening
seIllum = strel("disk", 30);  % TODO: Adjust radius (larger = smoother)
background = imopen(smoothed, seIllum);

% Correct illumination
corrected = smoothed - background;
corrected = mat2gray(corrected);

% Apply Otsu on corrected image
bwCorrected = imbinarize(corrected);
correctedThresh = graythresh(corrected);
fprintf('Corrected Otsu threshold: %.4f\n', correctedThresh);

%% Step 7: Compare Methods Visually
figure('Name', 'Thresholding Methods Comparison', 'Position', [30 30 1500 500]);

subplot(2, 4, 1);
imshow(grayImg, []);
title('Original');

subplot(2, 4, 2);
imshow(bwOtsu);
title(sprintf('Global Otsu (T=%.3f)', otsuThresh));

subplot(2, 4, 3);
imshow(bwAdaptive);
title(sprintf('Adaptive (dark, S=%.2f)', sensitivity));

subplot(2, 4, 4);
imshow(bwAdaptiveBright);
title(sprintf('Adaptive (bright, S=%.2f)', sensitivity));

subplot(2, 4, 5);
imshow(quantizedDisplay, []);
title(sprintf('Multi-level (%d levels)', numLevels));
colormap(gca, parula);

subplot(2, 4, 6);
imshow(bwLocalMean);
title('Local Mean Threshold');

subplot(2, 4, 7);
imshow(corrected, []);
title('Illumination Corrected');

subplot(2, 4, 8);
imshow(bwCorrected);
title('Corrected + Otsu');

sgtitle('Thresholding Methods for Tissue Segmentation');

%% Step 8: Multi-Level Region Visualization with Color Map
% Create colored overlay for multi-level segmentation
rgbQuantized = label2rgb(quantized, 'parula', 'k');

figure('Name', 'Multi-Level Tissue Regions');

subplot(1, 2, 1);
imshow(grayImg, []);
title('Original');

subplot(1, 2, 2);
imshow(rgbQuantized);
title(sprintf('%d-Level Tissue Segmentation', numLevels + 1));
% Add colorbar legend
fprintf('\nRegion labels: 1 to %d (background to densest tissue)\n', numLevels + 1);

%% Step 9: Region Statistics for Multi-Level Segmentation
fprintf('\n--- Multi-Level Region Statistics ---\n');
totalPixels = numel(quantized);
for r = 1:(numLevels + 1)
    regionPixels = sum(quantized(:) == r);
    fprintf('  Region %d: %6d pixels (%.1f%%)\n', r, regionPixels, ...
        100 * regionPixels / totalPixels);
end

%% Step 10: Save Results
if ~isempty(outputDir)
    if ~isfolder(outputDir), mkdir(outputDir); end
    imwrite(bwOtsu, fullfile(outputDir, 'thresh_otsu.png'));
    imwrite(bwAdaptive, fullfile(outputDir, 'thresh_adaptive.png'));
    imwrite(quantizedDisplay, fullfile(outputDir, 'thresh_multilevel.png'));
    imwrite(bwLocalMean, fullfile(outputDir, 'thresh_local_mean.png'));
    imwrite(bwCorrected, fullfile(outputDir, 'thresh_corrected.png'));
    imwrite(rgbQuantized, fullfile(outputDir, 'multilevel_colored.png'));
    fprintf('Results saved to: %s\n', outputDir);
end

%% Summary
fprintf('\n--- Thresholding Comparison Summary ---\n');
fprintf('Global Otsu foreground:     %.1f%%\n', 100 * sum(bwOtsu(:)) / numel(bwOtsu));
fprintf('Adaptive (dark) foreground: %.1f%%\n', 100 * sum(bwAdaptive(:)) / numel(bwAdaptive));
fprintf('Local mean foreground:      %.1f%%\n', 100 * sum(bwLocalMean(:)) / numel(bwLocalMean));
fprintf('Corrected Otsu foreground:  %.1f%%\n', 100 * sum(bwCorrected(:)) / numel(bwCorrected));
