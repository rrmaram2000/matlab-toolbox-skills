%% Template: Edge Detection Pipeline for Boundary Analysis
% Compare edge detection methods (Canny, Sobel, Prewitt), refine boundaries
% with active contours, and extract boundary properties.
% MATLAB R2025b | Image Processing Toolbox
%
% Usage:
%   1. Fill in all TODO sections with your data
%   2. Run section-by-section or as complete script
%
% Requirements:
%   - Image Processing Toolbox

%% TODO: Configure your data paths and parameters
inputPath       = '';    % TODO: Path to your biomedical image
outputDir       = '';    % TODO: Path to save results
cannyThreshLow  = 0.05;  % TODO: Canny lower threshold (0–1)
cannyThreshHigh = 0.15;  % TODO: Canny upper threshold (0–1)
cannySigma      = 1.5;   % TODO: Canny Gaussian sigma
acIterations    = 200;   % TODO: Active contour iterations

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

fprintf('Image loaded: %d x %d pixels\n', size(grayImg, 1), size(grayImg, 2));

%% Step 2: Edge Detection — Canny Method
edgeCanny = edge(smoothed, 'Canny', [cannyThreshLow cannyThreshHigh], cannySigma);
fprintf('Canny edges: %d edge pixels\n', sum(edgeCanny(:)));

%% Step 3: Edge Detection — Sobel Method
edgeSobel = edge(smoothed, 'Sobel');
fprintf('Sobel edges: %d edge pixels\n', sum(edgeSobel(:)));

%% Step 4: Edge Detection — Prewitt Method
edgePrewitt = edge(smoothed, 'Prewitt');
fprintf('Prewitt edges: %d edge pixels\n', sum(edgePrewitt(:)));

%% Step 5: Edge Detection — Log (Laplacian of Gaussian)
edgeLog = edge(smoothed, 'log', [], 2.0);  % TODO: Adjust sigma
fprintf('LoG edges: %d edge pixels\n', sum(edgeLog(:)));

%% Step 6: Gradient Magnitude Map
[gmag, gdir] = imgradient(smoothed, 'sobel');
gmagNorm = mat2gray(gmag);

%% Step 7: Create Initial Mask for Active Contour Refinement
% Use Canny edges + morphological operations as initialization
initMask = edgeCanny;
se = strel("disk", 3);
initMask = imdilate(initMask, se);
initMask = imfill(initMask, 'holes');
initMask = bwareaopen(initMask, 200);  % TODO: Adjust minimum area

%% Step 8: Active Contour Refinement (Chan-Vese)
% Refine boundaries using region-based active contours
refinedMask = activecontour(smoothed, initMask, acIterations, 'Chan-Vese', ...
    'SmoothFactor', 1.0, ...   % TODO: Adjust smoothness (higher = smoother)
    'ContractionBias', 0.0);   % TODO: Negative expands, positive contracts

% Cleanup the refined mask
refinedMask = imfill(refinedMask, 'holes');
refinedMask = bwareaopen(refinedMask, 100);

fprintf('Active contour: %d foreground pixels\n', sum(refinedMask(:)));

%% Step 9: Boundary Extraction and Smoothing
% Extract boundaries from refined mask
boundaries = bwboundaries(refinedMask, 'noholes');
fprintf('Extracted %d boundaries\n', numel(boundaries));

% Compute boundary perimeters on refined mask
refinedPerim = bwperim(refinedMask);

%% Step 10: Boundary Measurements
cc = bwconncomp(refinedMask);
stats = regionprops("table", cc, ...
    "Area", "Perimeter", "Centroid", "Circularity", ...
    "MajorAxisLength", "MinorAxisLength", "Orientation");

fprintf('\n--- Boundary Measurements ---\n');
for k = 1:min(height(stats), 10)  % Show first 10 objects
    fprintf('  Object %d: Area=%d, Perimeter=%.1f, Circularity=%.3f\n', ...
        k, stats.Area(k), stats.Perimeter(k), stats.Circularity(k));
end

%% Step 11: Visualize Edge Detection Comparison
figure('Name', 'Edge Detection Comparison', 'Position', [30 30 1400 500]);

subplot(2, 4, 1);
imshow(grayImg, []);
title('Original');

subplot(2, 4, 2);
imshow(edgeCanny);
title('Canny');

subplot(2, 4, 3);
imshow(edgeSobel);
title('Sobel');

subplot(2, 4, 4);
imshow(edgePrewitt);
title('Prewitt');

subplot(2, 4, 5);
imshow(edgeLog);
title('LoG');

subplot(2, 4, 6);
imshow(gmagNorm, []);
title('Gradient Magnitude');

subplot(2, 4, 7);
imshow(initMask);
title('Initial Mask');

subplot(2, 4, 8);
imshow(refinedMask);
title('Active Contour Refined');

sgtitle('Edge Detection & Boundary Refinement');

%% Step 12: Overlay Boundaries on Original
figure('Name', 'Boundary Overlay');
imshow(img); hold on;

for k = 1:numel(boundaries)
    b = boundaries{k};
    % Smooth boundary coordinates
    smoothX = smooth(b(:, 2), 5);  % TODO: Adjust smoothing window
    smoothY = smooth(b(:, 1), 5);
    plot(smoothX, smoothY, 'g-', 'LineWidth', 1.5);
end

% Mark centroids
if ~isempty(stats)
    centroids = stats.Centroid;
    plot(centroids(:, 1), centroids(:, 2), 'r+', 'MarkerSize', 10, 'LineWidth', 2);
end
title(sprintf('Detected Boundaries (%d objects)', numel(boundaries)));
hold off;

%% Step 13: Save Results
if ~isempty(outputDir)
    if ~isfolder(outputDir), mkdir(outputDir); end
    imwrite(edgeCanny, fullfile(outputDir, 'edges_canny.png'));
    imwrite(edgeSobel, fullfile(outputDir, 'edges_sobel.png'));
    imwrite(refinedMask, fullfile(outputDir, 'mask_active_contour.png'));
    imwrite(refinedPerim, fullfile(outputDir, 'boundaries.png'));
    writetable(stats, fullfile(outputDir, 'boundary_measurements.csv'));
    fprintf('Results saved to: %s\n', outputDir);
end

%% Summary
fprintf('\n--- Edge Detection Summary ---\n');
fprintf('Canny edge pixels:   %d\n', sum(edgeCanny(:)));
fprintf('Sobel edge pixels:   %d\n', sum(edgeSobel(:)));
fprintf('Prewitt edge pixels: %d\n', sum(edgePrewitt(:)));
fprintf('LoG edge pixels:     %d\n', sum(edgeLog(:)));
fprintf('Refined objects:     %d\n', cc.NumObjects);
