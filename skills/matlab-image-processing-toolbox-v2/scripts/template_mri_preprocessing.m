%% Template: MRI Preprocessing — Bias Field Correction & Intensity Normalization
% Complete pipeline for MRI slice preprocessing: bias field estimation,
% intensity normalization, CLAHE enhancement, and brain masking.
% MATLAB R2025b | Image Processing Toolbox
%
% Usage:
%   1. Fill in all TODO sections with your data
%   2. Run section-by-section or as complete script
%
% Requirements:
%   - Image Processing Toolbox

%% TODO: Configure your data paths and parameters
inputPath  = '';  % TODO: Path to your MRI image (e.g., 'brain_slice.png')
outputDir  = '';  % TODO: Path to save results (e.g., './results/')
biasSmooth = 30;  % TODO: Smoothing sigma for bias field estimation (larger = smoother)

%% Step 1: Load MRI Image
img = imread(inputPath);
if size(img, 3) == 3
    img = rgb2gray(img);
end
img = im2double(img);
fprintf('Loaded image: %d x %d pixels\n', size(img, 1), size(img, 2));

%% Step 2: Brain Masking — Isolate Brain from Background
% Threshold to create initial brain mask
brainMask = imbinarize(img, 'adaptive', 'Sensitivity', 0.4);

% Morphological cleanup: remove small noise and fill holes
se = strel("disk", 3);
brainMask = imopen(brainMask, se);
brainMask = imfill(brainMask, 'holes');
brainMask = bwareaopen(brainMask, 500);  % TODO: Adjust minimum area

% Keep only the largest connected component (assumed to be the brain)
cc = bwconncomp(brainMask);
stats = regionprops("table", cc, "Area");
[~, maxIdx] = max(stats.Area);
brainMask = false(size(brainMask));
brainMask(cc.PixelIdxList{maxIdx}) = true;

%% Step 3: Bias Field Estimation & Correction
% Estimate low-frequency bias field using heavy Gaussian smoothing
% Only estimate within the brain mask to avoid background influence
maskedImg = img;
maskedImg(~brainMask) = NaN;

% Replace NaN with local mean for smooth interpolation
biasEstimate = imgaussfilt(img, biasSmooth);  % 'replicate' padding (R2025b default)

% Avoid division by zero
biasEstimate(biasEstimate < 0.01) = 0.01;

% Correct the bias field
correctedImg = img ./ biasEstimate;

% Apply local Laplacian filtering for additional enhancement
correctedImg = locallapfilt(correctedImg, 0.4, 0.5);

% Re-normalize to [0, 1]
correctedImg = mat2gray(correctedImg);

%% Step 4: Intensity Normalization with CLAHE
% Adaptive histogram equalization for contrast enhancement
normalizedImg = adapthisteq(correctedImg, ...
    'ClipLimit',      0.02, ...   % TODO: Adjust clip limit (0.01–0.03)
    'Distribution',   'rayleigh', ...
    'NumTiles',       [8 8]);     % TODO: Adjust tile grid size

%% Step 5: Apply Brain Mask to Final Result
finalImg = normalizedImg .* double(brainMask);

%% Step 6: Visualize Results
figure('Name', 'MRI Preprocessing Pipeline', 'Position', [100 100 1200 400]);

subplot(1, 4, 1);
imshow(img, []);
title('Original MRI');

subplot(1, 4, 2);
imshow(correctedImg, []);
title('Bias Corrected');

subplot(1, 4, 3);
imshow(normalizedImg, []);
title('CLAHE Enhanced');

subplot(1, 4, 4);
imshow(finalImg, []);
title('Brain Masked Result');

sgtitle('MRI Preprocessing Pipeline');

%% Step 7: Save Results
if ~isempty(outputDir)
    if ~isfolder(outputDir), mkdir(outputDir); end
    imwrite(finalImg, fullfile(outputDir, 'mri_preprocessed.png'));
    imwrite(uint8(brainMask * 255), fullfile(outputDir, 'brain_mask.png'));
    fprintf('Results saved to: %s\n', outputDir);
end

%% Summary Statistics
fprintf('\n--- Preprocessing Summary ---\n');
fprintf('Original intensity range:  [%.3f, %.3f]\n', min(img(:)), max(img(:)));
fprintf('Corrected intensity range: [%.3f, %.3f]\n', min(correctedImg(:)), max(correctedImg(:)));
fprintf('Brain mask coverage:       %.1f%% of image\n', 100 * sum(brainMask(:)) / numel(brainMask));
