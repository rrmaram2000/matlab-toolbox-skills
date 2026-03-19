%% Template: Block Processing for Whole-Slide Images
% Process large images (e.g., whole-slide images) tile-by-tile using
% blockproc. Includes tissue detection, border handling, and result
% stitching for memory-efficient analysis.
% MATLAB R2025b | Image Processing Toolbox
%
% Usage:
%   1. Fill in all TODO sections with your data
%   2. Run section-by-section or as complete script
%
% Requirements:
%   - Image Processing Toolbox

%% TODO: Configure your data paths and parameters
inputPath   = '';         % TODO: Path to large image (TIFF, SVS, etc.)
outputDir   = '';         % TODO: Path to save results
blockSize   = [512 512];  % TODO: Block size in pixels [rows cols]
borderSize  = [16 16];    % TODO: Border overlap to handle edge effects [rows cols]
tissuePct   = 0.10;       % TODO: Minimum tissue fraction to process a block

%% Step 1: Inspect Image Without Loading Entire File
info = imfinfo(inputPath);
imgHeight = info(1).Height;
imgWidth  = info(1).Width;
imgBits   = info(1).BitDepth;
fprintf('Image size: %d x %d pixels, %d-bit\n', imgHeight, imgWidth, imgBits);
fprintf('Block size: %d x %d, border: %d x %d\n', ...
    blockSize(1), blockSize(2), borderSize(1), borderSize(2));

numBlocksR = ceil(imgHeight / blockSize(1));
numBlocksC = ceil(imgWidth / blockSize(2));
fprintf('Estimated blocks: %d x %d = %d total\n', numBlocksR, numBlocksC, numBlocksR * numBlocksC);

%% Step 2: Define Block Processing Function — Tissue Detection
% This function detects tissue regions within each block
% It returns a binary mask (same size as input block)
tissueDetectFcn = @(blockStruct) detectTissueBlock(blockStruct.data, tissuePct);

%% Step 3: Run Block Processing for Tissue Detection
fprintf('Running tissue detection with blockproc...\n');
tic;
tissueMask = blockproc(inputPath, blockSize, tissueDetectFcn, ...
    'BorderSize',       borderSize, ...
    'TrimBorder',       true, ...
    'PadPartialBlocks', true, ...
    'UseParallel',      false);  % TODO: Set true if Parallel Computing Toolbox available
elapsed = toc;
fprintf('Tissue detection complete in %.1f seconds\n', elapsed);

%% Step 4: Define Block Processing Function — Feature Extraction
% Extract mean intensity and texture per block (returns scalar features)
featureExtractFcn = @(blockStruct) extractBlockFeatures(blockStruct.data);

%% Step 5: Run Block Processing for Feature Maps
fprintf('Extracting feature maps...\n');
featureMap = blockproc(inputPath, blockSize, featureExtractFcn, ...
    'BorderSize',       [0 0], ...
    'TrimBorder',       false, ...
    'PadPartialBlocks', true);

%% Step 6: Define Block Processing Function — Enhancement
% Apply CLAHE enhancement to each block
enhanceFcn = @(blockStruct) enhanceBlock(blockStruct.data);

%% Step 7: Run Block Processing for Enhancement with Output to File
outputTiffPath = fullfile(outputDir, 'enhanced_wsi.tif');
if ~isempty(outputDir)
    if ~isfolder(outputDir), mkdir(outputDir); end
    fprintf('Enhancing image with blockproc (writing to file)...\n');
    tic;
    blockproc(inputPath, blockSize, enhanceFcn, ...
        'BorderSize',       borderSize, ...
        'TrimBorder',       true, ...
        'PadPartialBlocks', true, ...
        'Destination',      outputTiffPath);
    fprintf('Enhanced image saved in %.1f seconds\n', toc);
end

%% Step 8: Analyze Tissue Detection Results
% Trim mask to original image size (blockproc may pad)
tissueMask = tissueMask(1:min(imgHeight, size(tissueMask, 1)), ...
                        1:min(imgWidth, size(tissueMask, 2)));

tissueFraction = sum(tissueMask(:)) / numel(tissueMask);
fprintf('Tissue coverage: %.1f%% of image\n', 100 * tissueFraction);

%% Step 9: Generate Thumbnail with Tissue Overlay
% Read a low-resolution version for visualization
scaleFactor = max(1, floor(max(imgHeight, imgWidth) / 1024));
thumbnail = imread(inputPath);
if scaleFactor > 1
    thumbnail = imresize(thumbnail, 1 / scaleFactor);
end
maskThumbnail = imresize(tissueMask, [size(thumbnail, 1), size(thumbnail, 2)], 'nearest');

figure('Name', 'Whole-Slide Image Analysis');

subplot(1, 3, 1);
imshow(thumbnail);
title('WSI Thumbnail');

subplot(1, 3, 2);
imshow(maskThumbnail);
title(sprintf('Tissue Mask (%.1f%%)', 100 * tissueFraction));

subplot(1, 3, 3);
imshow(featureMap, []);
colorbar;
title('Feature Map (Mean Intensity)');

sgtitle('Block Processing Results');

%% Step 10: Save Results
if ~isempty(outputDir)
    imwrite(uint8(tissueMask * 255), fullfile(outputDir, 'tissue_mask.png'));
    imwrite(mat2gray(featureMap), fullfile(outputDir, 'feature_map.png'));
    fprintf('Results saved to: %s\n', outputDir);
end

%% Summary
fprintf('\n--- Block Processing Summary ---\n');
fprintf('Image size:       %d x %d\n', imgHeight, imgWidth);
fprintf('Block size:       %d x %d\n', blockSize(1), blockSize(2));
fprintf('Total blocks:     %d\n', numBlocksR * numBlocksC);
fprintf('Tissue coverage:  %.1f%%\n', 100 * tissueFraction);

%% =====================================================================
%  LOCAL FUNCTIONS — Block Processing Callbacks
%  =====================================================================

function mask = detectTissueBlock(blockData, minTissuePct)
%DETECTTISSUEBLOCK Detect tissue in a single image block
    if size(blockData, 3) == 3
        gray = rgb2gray(blockData);
    else
        gray = blockData;
    end
    gray = im2double(gray);

    % Tissue appears darker than white background
    bw = gray < 0.85;  % TODO: Adjust background threshold
    bw = bwareaopen(bw, 50);

    % Only keep block if sufficient tissue
    if sum(bw(:)) / numel(bw) < minTissuePct
        mask = false(size(gray));
    else
        mask = bw;
    end
end

function features = extractBlockFeatures(blockData)
%EXTRACTBLOCKFEATURES Compute scalar features for one block
    if size(blockData, 3) == 3
        gray = rgb2gray(blockData);
    else
        gray = blockData;
    end
    gray = im2double(gray);
    features = mean(gray(:));  % Mean intensity as simple feature
end

function enhanced = enhanceBlock(blockData)
%ENHANCEBLOCK Apply CLAHE enhancement to one block
    if size(blockData, 3) == 3
        lab = rgb2lab(blockData);
        L = lab(:, :, 1) / 100;
        L = adapthisteq(L, 'ClipLimit', 0.01, 'NumTiles', [4 4]);
        lab(:, :, 1) = L * 100;
        enhanced = lab2rgb(lab, 'OutputType', 'uint8');
    else
        enhanced = adapthisteq(im2uint8(blockData), 'ClipLimit', 0.01);
    end
end
