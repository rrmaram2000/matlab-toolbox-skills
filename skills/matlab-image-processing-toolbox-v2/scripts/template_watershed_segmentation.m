%% Template: Watershed Segmentation for Touching Objects
% Marker-controlled watershed segmentation to separate touching cells or
% nuclei. Includes distance transform, h-minima suppression, and post-
% processing to handle over-segmentation.
% MATLAB R2025b | Image Processing Toolbox
%
% Usage:
%   1. Fill in all TODO sections with your data
%   2. Run section-by-section or as complete script
%
% Requirements:
%   - Image Processing Toolbox

%% TODO: Configure your data paths and parameters
inputPath   = '';    % TODO: Path to your microscopy image
outputDir   = '';    % TODO: Path to save results
minObjArea  = 150;   % TODO: Minimum object area in pixels
hMinDepth   = 2;     % TODO: H-minima depth (higher = fewer segments, less over-seg)
gaussSigma  = 1.5;   % TODO: Smoothing sigma before thresholding

%% Step 1: Load and Preprocess Image
img = imread(inputPath);
if size(img, 3) == 3
    grayImg = rgb2gray(img);
else
    grayImg = img;
end
grayImg = im2double(grayImg);

% Smooth to reduce noise (R2025b: 'replicate' padding by default)
smoothed = imgaussfilt(grayImg, gaussSigma);

%% Step 2: Create Initial Binary Mask
% Threshold using Otsu's method
bw = imbinarize(smoothed);

% TODO: Invert if objects are dark on bright background
% bw = ~bw;

% Basic cleanup
se = strel("disk", 2);
bw = imopen(bw, se);
bw = imfill(bw, 'holes');
bw = bwareaopen(bw, minObjArea);

fprintf('Initial binary mask: %d foreground pixels\n', sum(bw(:)));

%% Step 3: Standard Watershed (for comparison — often over-segments)
D_basic = -bwdist(~bw);
L_basic = watershed(D_basic);
L_basic(~bw) = 0;
nBasic = max(L_basic(:));
fprintf('Standard watershed: %d segments (often over-segmented)\n', nBasic);

%% Step 4: Marker-Controlled Watershed
% Distance transform to find object centers
D = bwdist(~bw);

% Suppress shallow local maxima to reduce over-segmentation
D_suppressed = imhmin(D, hMinDepth);

% Find foreground markers from regional maxima of distance transform
fgMarkers = imregionalmax(D_suppressed);

% Dilate markers slightly to ensure each object has a seed
fgMarkers = imdilate(fgMarkers, strel("disk", 1));

% Background markers from skeleton of background
bgDist = bwdist(bw);
bgMarkers = bgDist > 0 & bgDist < 3;  % Thin band around objects

% Combine markers
markers = uint8(fgMarkers) + 2 * uint8(bgMarkers);

% Impose minima on the gradient magnitude
gradMag = imgradient(smoothed);
gradMag = imimposemin(gradMag, fgMarkers | ~bw);

% Apply watershed on gradient with imposed minima
L_marker = watershed(gradMag);
L_marker(~bw) = 0;

%% Step 5: Post-Process — Remove Small and Merge Tiny Segments
% Relabel connected components
segMask = L_marker > 0;
ccSeg = bwconncomp(segMask);
stats = regionprops("table", ccSeg, "Area", "Centroid", "EquivDiameter");

% Filter by minimum area
validIdx = stats.Area >= minObjArea;
finalMask = false(size(bw));
validPixels = ccSeg.PixelIdxList(validIdx);
for k = 1:numel(validPixels)
    finalMask(validPixels{k}) = true;
end

% Final labeling
ccFinal = bwconncomp(finalMask);
finalLabel = labelmatrix(ccFinal);
finalStats = regionprops("table", ccFinal, ...
    "Area", "Centroid", "EquivDiameter", "Eccentricity", "Solidity");

nFinal = ccFinal.NumObjects;
fprintf('Marker-controlled watershed: %d objects (after filtering)\n', nFinal);

%% Step 6: Visualize Results
rgbBasic = label2rgb(L_basic, 'jet', 'k', 'shuffle');
rgbMarker = label2rgb(finalLabel, 'jet', 'k', 'shuffle');

figure('Name', 'Watershed Segmentation', 'Position', [50 50 1400 500]);

subplot(1, 4, 1);
imshow(img);
title('Original');

subplot(1, 4, 2);
imshow(bw);
title('Binary Mask');

subplot(1, 4, 3);
imshow(rgbBasic);
title(sprintf('Standard WS (%d)', nBasic));

subplot(1, 4, 4);
imshow(rgbMarker);
title(sprintf('Marker-Controlled (%d)', nFinal));

sgtitle('Watershed Segmentation Comparison');

%% Step 7: Overlay Centroids on Original
figure('Name', 'Detected Objects');
imshow(img); hold on;
centroids = finalStats.Centroid;
plot(centroids(:, 1), centroids(:, 2), 'r+', 'MarkerSize', 8, 'LineWidth', 1.5);
title(sprintf('%d Objects Detected', nFinal));
hold off;

%% Step 8: Save Results
if ~isempty(outputDir)
    if ~isfolder(outputDir), mkdir(outputDir); end
    imwrite(rgbMarker, fullfile(outputDir, 'watershed_labels.png'));
    imwrite(finalMask, fullfile(outputDir, 'watershed_mask.png'));
    writetable(finalStats, fullfile(outputDir, 'watershed_measurements.csv'));
    fprintf('Results saved to: %s\n', outputDir);
end

%% Summary
fprintf('\n--- Watershed Segmentation Summary ---\n');
fprintf('Standard watershed segments:  %d\n', nBasic);
fprintf('Marker-controlled segments:   %d\n', nFinal);
fprintf('Mean object area:             %.1f pixels\n', mean(finalStats.Area));
fprintf('Mean equivalent diameter:     %.1f pixels\n', mean(finalStats.EquivDiameter));
