%% Template: H&E Stain Normalization via Color Deconvolution
% Normalize H&E stained histology images using optical density conversion
% and the Macenko method for stain separation and reconstruction.
% MATLAB R2025b | Image Processing Toolbox
%
% Usage:
%   1. Fill in all TODO sections with your data
%   2. Run section-by-section or as complete script
%
% Requirements:
%   - Image Processing Toolbox

%% TODO: Configure your data paths and parameters
inputPath     = '';  % TODO: Path to source H&E histology image
referencePath = '';  % TODO: Path to reference (target) H&E image for normalization
outputDir     = '';  % TODO: Path to save results
percentile    = 99;  % TODO: Percentile for robust stain vector estimation

%% Step 1: Load Source and Reference Images
srcImg = imread(inputPath);
refImg = imread(referencePath);
fprintf('Source image:    %d x %d\n', size(srcImg, 1), size(srcImg, 2));
fprintf('Reference image: %d x %d\n', size(refImg, 1), size(refImg, 2));

%% Step 2: Convert RGB to Optical Density (OD)
% OD = -log10(I / I0), where I0 = 255 (max intensity for 8-bit)
I0 = 255;
odThreshold = 0.15;  % TODO: Minimum OD to consider as tissue (not background)

srcOD = -log10(double(srcImg) / I0 + 1e-6);
refOD = -log10(double(refImg) / I0 + 1e-6);

%% Step 3: Extract Tissue Pixels (Exclude Background)
% Background pixels have low OD across all channels
srcMask = mean(srcOD, 3) > odThreshold;
refMask = mean(refOD, 3) > odThreshold;

srcPixels = reshape(srcOD, [], 3);
srcPixels = srcPixels(srcMask(:), :);

refPixels = reshape(refOD, [], 3);
refPixels = refPixels(refMask(:), :);

%% Step 4: Macenko Stain Vector Estimation
% Estimate stain vectors using SVD on OD space
[srcCoeff, srcScore] = pca(srcPixels);
[refCoeff, refScore] = pca(refPixels);

% Project onto first two principal components
srcProj = srcPixels * srcCoeff(:, 1:2);
refProj = refPixels * refCoeff(:, 1:2);

% Find extreme angles to identify pure stain vectors
srcAngles = atan2(srcProj(:, 2), srcProj(:, 1));
refAngles = atan2(refProj(:, 2), refProj(:, 1));

% Use percentile-based angle selection for robustness
srcMinAngle = prctile(srcAngles, 100 - percentile);
srcMaxAngle = prctile(srcAngles, percentile);
refMinAngle = prctile(refAngles, 100 - percentile);
refMaxAngle = prctile(refAngles, percentile);

% Reconstruct stain vectors from extreme angles
srcVec1 = srcCoeff(:, 1:2) * [cos(srcMinAngle); sin(srcMinAngle)];
srcVec2 = srcCoeff(:, 1:2) * [cos(srcMaxAngle); sin(srcMaxAngle)];
refVec1 = refCoeff(:, 1:2) * [cos(refMinAngle); sin(refMinAngle)];
refVec2 = refCoeff(:, 1:2) * [cos(refMaxAngle); sin(refMaxAngle)];

% Normalize stain vectors
srcStainMatrix = [srcVec1 / norm(srcVec1), srcVec2 / norm(srcVec2)];
refStainMatrix = [refVec1 / norm(refVec1), refVec2 / norm(refVec2)];

%% Step 5: Stain Separation — Deconvolve Source Image
% Solve for stain concentrations: OD = StainMatrix * Concentrations
srcAllPixels = reshape(srcOD, [], 3);
srcConcentrations = (srcStainMatrix' * srcStainMatrix) \ (srcStainMatrix' * srcAllPixels');

%% Step 6: Normalize Stain Concentrations
% Match concentration statistics to reference
refAllPixels = reshape(refOD, [], 3);
refConcentrations = (refStainMatrix' * refStainMatrix) \ (refStainMatrix' * refAllPixels');

for ch = 1:2
    srcC = srcConcentrations(ch, :);
    refC = refConcentrations(ch, :);

    % Robust normalization using percentiles
    srcP99 = prctile(srcC(srcC > 0), percentile);
    refP99 = prctile(refC(refC > 0), percentile);

    if srcP99 > 0 && refP99 > 0
        srcConcentrations(ch, :) = srcC * (refP99 / srcP99);
    end
end

%% Step 7: Reconstruct Normalized Image
% Reconstruct OD using reference stain matrix and normalized concentrations
normalizedOD = refStainMatrix * srcConcentrations;
normalizedOD = reshape(normalizedOD', size(srcOD));

% Convert back from OD to RGB
normalizedImg = uint8(I0 * 10.^(-normalizedOD));
normalizedImg = max(min(normalizedImg, 255), 0);

%% Step 8: Visualize Results
figure('Name', 'H&E Stain Normalization', 'Position', [50 50 1200 400]);

subplot(1, 3, 1);
imshow(srcImg);
title('Source Image');

subplot(1, 3, 2);
imshow(refImg);
title('Reference Image');

subplot(1, 3, 3);
imshow(normalizedImg);
title('Normalized Result');

sgtitle('Macenko Stain Normalization');

%% Step 9: Save Results
if ~isempty(outputDir)
    if ~isfolder(outputDir), mkdir(outputDir); end
    imwrite(normalizedImg, fullfile(outputDir, 'stain_normalized.png'));
    fprintf('Normalized image saved to: %s\n', outputDir);
end

%% Summary
fprintf('\n--- Stain Normalization Summary ---\n');
fprintf('Source tissue pixels:    %d (%.1f%%)\n', sum(srcMask(:)), ...
    100 * sum(srcMask(:)) / numel(srcMask));
fprintf('Reference tissue pixels: %d (%.1f%%)\n', sum(refMask(:)), ...
    100 * sum(refMask(:)) / numel(refMask));
