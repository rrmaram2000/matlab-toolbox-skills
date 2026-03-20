%% Macenko Stain Normalization for H&E Histology Images
% Implement the Macenko method for normalizing H&E-stained histology
% images: OD-space conversion, SVD-based stain vector estimation with
% angle-based extraction, background masking, and concentration normalization.
%
% MATLAB R2025b | Image Processing Toolbox
%
% Workflow:
%   1. Load source and reference H&E images
%   2. Convert RGB to Optical Density (OD) space using log10
%   3. Mask background pixels using OD threshold
%   4. Estimate stain vectors via PCA + percentile angle extraction
%   5. Deconvolve (separate) stain channels
%   6. Normalize concentrations to match reference statistics
%   7. Reconstruct normalized RGB image
%   8. Visualize with separated stain channels

%% ---- USER CONFIGURATION ----
inputPath     = '';   % TODO: Path to source H&E histology image
referencePath = '';   % TODO: Path to reference (target) H&E image
outputDir     = '';   % TODO: Path to save results
percentile    = 99;   % Percentile for robust stain vector estimation
odThreshold   = 0.15; % Minimum OD to consider as tissue (not background)

%% Step 1: Load source and reference images
srcImg = imread(inputPath);
refImg = imread(referencePath);

fprintf('Source image:    [%d x %d x %d]\n', size(srcImg));
fprintf('Reference image: [%d x %d x %d]\n', size(refImg));

%% Step 2: Convert RGB to Optical Density (OD) space
% Beer-Lambert law: OD = -log10(I / I0)
% I0 = 255 for 8-bit images (transmitted light intensity)
% Add small epsilon to avoid log(0)
I0 = 255;

srcOD = -log10(double(srcImg) / I0 + 1e-6);
refOD = -log10(double(refImg) / I0 + 1e-6);

fprintf('OD range (source): [%.3f, %.3f]\n', min(srcOD(:)), max(srcOD(:)));

%% Step 3: Extract tissue pixels (exclude background)
% Background pixels have low OD across all channels.
% This masking step is critical — including background pixels
% would skew the PCA-based stain vector estimation.
srcMask = mean(srcOD, 3) > odThreshold;
refMask = mean(refOD, 3) > odThreshold;

srcPixels = reshape(srcOD, [], 3);
srcPixels = srcPixels(srcMask(:), :);

refPixels = reshape(refOD, [], 3);
refPixels = refPixels(refMask(:), :);

fprintf('Tissue pixels: source=%d (%.1f%%), reference=%d (%.1f%%)\n', ...
    size(srcPixels, 1), 100*mean(srcMask(:)), ...
    size(refPixels, 1), 100*mean(refMask(:)));

%% Step 4: Macenko stain vector estimation via PCA + angle extraction
% The Macenko method projects tissue OD values onto the first two
% principal components, then identifies pure stain vectors as the
% extreme angles in this 2D projection space.

% PCA on tissue pixels
[srcCoeff, ~] = pca(srcPixels);
[refCoeff, ~] = pca(refPixels);

% Project onto first two principal components (the "stain plane")
srcProj = srcPixels * srcCoeff(:, 1:2);
refProj = refPixels * refCoeff(:, 1:2);

% Compute angles of each tissue pixel in the projected 2D space
srcAngles = atan2(srcProj(:, 2), srcProj(:, 1));
refAngles = atan2(refProj(:, 2), refProj(:, 1));

% Use robust percentile-based angle selection
% The 1st and 99th percentile angles correspond to the two pure stains
% (Hematoxylin and Eosin have the most extreme angular positions)
srcMinAngle = prctile(srcAngles, 100 - percentile);
srcMaxAngle = prctile(srcAngles, percentile);
refMinAngle = prctile(refAngles, 100 - percentile);
refMaxAngle = prctile(refAngles, percentile);

% Reconstruct 3D stain vectors from the extreme angles
% Map 2D angle back through PCA coefficients to get 3D OD-space vectors
srcVec1 = srcCoeff(:, 1:2) * [cos(srcMinAngle); sin(srcMinAngle)];
srcVec2 = srcCoeff(:, 1:2) * [cos(srcMaxAngle); sin(srcMaxAngle)];
refVec1 = refCoeff(:, 1:2) * [cos(refMinAngle); sin(refMinAngle)];
refVec2 = refCoeff(:, 1:2) * [cos(refMaxAngle); sin(refMaxAngle)];

% Normalize stain vectors to unit length
srcStainMatrix = [srcVec1 / norm(srcVec1), srcVec2 / norm(srcVec2)];
refStainMatrix = [refVec1 / norm(refVec1), refVec2 / norm(refVec2)];

fprintf('Source stain vectors estimated:\n');
fprintf('  Vec1 (H): [%.3f, %.3f, %.3f]\n', srcStainMatrix(:,1));
fprintf('  Vec2 (E): [%.3f, %.3f, %.3f]\n', srcStainMatrix(:,2));

%% Step 5: Stain separation — deconvolve source image
% Solve: OD = StainMatrix * Concentrations
% This gives per-pixel concentrations of Hematoxylin and Eosin
srcAllPixels = reshape(srcOD, [], 3);
srcConcentrations = (srcStainMatrix' * srcStainMatrix) \ ...
    (srcStainMatrix' * srcAllPixels');

%% Step 6: Normalize stain concentrations to match reference
% Match the concentration distribution of the source to the reference
refAllPixels = reshape(refOD, [], 3);
refConcentrations = (refStainMatrix' * refStainMatrix) \ ...
    (refStainMatrix' * refAllPixels');

for ch = 1:2
    srcC = srcConcentrations(ch, :);
    refC = refConcentrations(ch, :);

    % Robust normalization using percentiles (not mean/std)
    % This avoids sensitivity to outliers
    srcP99 = prctile(srcC(srcC > 0), percentile);
    refP99 = prctile(refC(refC > 0), percentile);

    if srcP99 > 0 && refP99 > 0
        srcConcentrations(ch, :) = srcC * (refP99 / srcP99);
    end
end

%% Step 7: Reconstruct normalized RGB image
% Reconstruct OD using REFERENCE stain matrix + normalized concentrations
normalizedOD = refStainMatrix * srcConcentrations;
normalizedOD = reshape(normalizedOD', size(srcOD));

% Convert back from OD to RGB intensity
% Inverse of Beer-Lambert: I = I0 * 10^(-OD)
normalizedImg = uint8(I0 * 10.^(-normalizedOD));
normalizedImg = max(min(normalizedImg, 255), 0);

%% Step 8: Visualize results with stain separation
figure('Name', 'Macenko Stain Normalization', 'Position', [50 50 1400 700]);

% Row 1: Source, Reference, Normalized
subplot(2, 4, 1); imshow(srcImg); title('Source');
subplot(2, 4, 2); imshow(refImg); title('Reference');
subplot(2, 4, 3); imshow(normalizedImg); title('Normalized');

% Row 1, panel 4: Color distribution comparison
subplot(2, 4, 4);
srcR = srcImg(:,:,1); refR = refImg(:,:,1); normR = normalizedImg(:,:,1);
histogram(srcR(srcMask), 50, 'FaceColor', [0.8 0.2 0.2], 'FaceAlpha', 0.4); hold on;
histogram(refR(refMask), 50, 'FaceColor', [0.2 0.2 0.8], 'FaceAlpha', 0.4);
histogram(normR(srcMask), 50, 'FaceColor', [0.2 0.8 0.2], 'FaceAlpha', 0.4); hold off;
legend('Source', 'Reference', 'Normalized');
title('Red Channel Distribution');

% Row 2: Separated stain channels
% Hematoxylin channel (from source)
hemaConc = srcConcentrations(1, :);
hemaImg = reshape(hemaConc, size(srcOD, 1), size(srcOD, 2));

% Eosin channel (from source)
eosinConc = srcConcentrations(2, :);
eosinImg = reshape(eosinConc, size(srcOD, 1), size(srcOD, 2));

subplot(2, 4, 5); imshow(hemaImg, []); colormap(gca, 'parula'); colorbar;
title('Hematoxylin Concentration');
subplot(2, 4, 6); imshow(eosinImg, []); colormap(gca, 'parula'); colorbar;
title('Eosin Concentration');

% Reconstruct individual stain images
hemaOD = refStainMatrix(:,1) * srcConcentrations(1,:);
hemaRGB = uint8(I0 * 10.^(-reshape(hemaOD', size(srcOD))));
eosinOD = refStainMatrix(:,2) * srcConcentrations(2,:);
eosinRGB = uint8(I0 * 10.^(-reshape(eosinOD', size(srcOD))));

subplot(2, 4, 7); imshow(hemaRGB); title('Hematoxylin Only');
subplot(2, 4, 8); imshow(eosinRGB); title('Eosin Only');

sgtitle('Macenko Stain Normalization with Color Deconvolution');

%% Step 9: Save results
if ~isempty(outputDir)
    if ~isfolder(outputDir), mkdir(outputDir); end
    imwrite(normalizedImg, fullfile(outputDir, 'stain_normalized.png'));
    imwrite(hemaRGB, fullfile(outputDir, 'hematoxylin_channel.png'));
    imwrite(eosinRGB, fullfile(outputDir, 'eosin_channel.png'));
    fprintf('\nResults saved to: %s\n', outputDir);
end

%% Summary statistics
fprintf('\n--- Stain Normalization Summary ---\n');
fprintf('Source tissue:    %d pixels (%.1f%%)\n', ...
    sum(srcMask(:)), 100*mean(srcMask(:)));
fprintf('Reference tissue: %d pixels (%.1f%%)\n', ...
    sum(refMask(:)), 100*mean(refMask(:)));
fprintf('OD threshold:     %.2f\n', odThreshold);
fprintf('Percentile:       %dth\n', percentile);

% Compute color distance improvement
srcMeanColor = mean(reshape(double(srcImg), [], 3), 1);
refMeanColor = mean(reshape(double(refImg), [], 3), 1);
normMeanColor = mean(reshape(double(normalizedImg), [], 3), 1);

distBefore = norm(srcMeanColor - refMeanColor);
distAfter  = norm(normMeanColor - refMeanColor);
fprintf('Color distance to reference: %.2f -> %.2f (%.1f%% improvement)\n', ...
    distBefore, distAfter, 100*(1 - distAfter/distBefore));

fprintf('\n=== Macenko Stain Normalization Complete ===\n');
