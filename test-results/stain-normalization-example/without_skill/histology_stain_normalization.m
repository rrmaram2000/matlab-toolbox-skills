%% H&E Stain Normalization for Histology Images
% Normalize staining variation between H&E histology images
% using histogram matching approach.
%
% MATLAB R2025b | Image Processing Toolbox

%% Step 1: Load images
inputPath = '';      % Path to source H&E image
referencePath = '';  % Path to reference H&E image
outputDir = '';

srcImg = imread(inputPath);
refImg = imread(referencePath);

fprintf("Source: %d x %d | Reference: %d x %d\n", ...
    size(srcImg,1), size(srcImg,2), size(refImg,1), size(refImg,2));

%% Step 2: Normalize using histogram matching per channel
% Match the color histogram of the source to the reference
% This is the simplest approach to stain normalization

normalizedImg = zeros(size(srcImg), 'uint8');
for ch = 1:3
    normalizedImg(:,:,ch) = imhistmatch(srcImg(:,:,ch), refImg(:,:,ch), 256);
end

%% Step 3: Alternative — Lab color space matching
% Convert to Lab, match L and a and b channels
srcLab = rgb2lab(srcImg);
refLab = rgb2lab(refImg);

% Match mean and standard deviation of each Lab channel
normalizedLab = srcLab;
for ch = 1:3
    srcCh = srcLab(:,:,ch);
    refCh = refLab(:,:,ch);

    % Z-score normalize source, then scale to reference stats
    normalizedLab(:,:,ch) = (srcCh - mean(srcCh(:))) / std(srcCh(:)) ...
        * std(refCh(:)) + mean(refCh(:));
end

normalizedLab_img = lab2rgb(normalizedLab);
normalizedLab_img = uint8(normalizedLab_img * 255);

%% Step 4: Visualize
figure;
subplot(2, 2, 1); imshow(srcImg);          title("Source");
subplot(2, 2, 2); imshow(refImg);          title("Reference");
subplot(2, 2, 3); imshow(normalizedImg);   title("Histogram Matched");
subplot(2, 2, 4); imshow(normalizedLab_img); title("Lab Normalized");
sgtitle("H&E Stain Normalization");

%% Step 5: Save
if ~isfolder(outputDir), mkdir(outputDir); end
imwrite(normalizedImg, fullfile(outputDir, "stain_normalized_hist.png"));
imwrite(normalizedLab_img, fullfile(outputDir, "stain_normalized_lab.png"));

fprintf("Results saved to: %s\n", outputDir);
