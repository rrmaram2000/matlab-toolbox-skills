%% Template: MedSAM Interactive Segmentation
% Segment medical images using the Medical Segment Anything Model (MedSAM).
% Load model, generate embeddings, define prompts, segment with imageSize.
% MATLAB R2025b | Medical Imaging Toolbox
%
% Usage:
%   1. Fill in all TODO sections with your data
%   2. Run section-by-section or as complete script
%
% Requirements:
%   - Medical Imaging Toolbox
%   - Deep Learning Toolbox
%   - Computer Vision Toolbox (for SAM support)

%% TODO: Configure your data paths and parameters
imageFile = '';   % TODO: Path to 2D medical image (e.g., X-ray, histology slice)
outputDir = '';   % TODO: Path to save segmentation results

%% Step 1: Load and prepare the medical image
img = imread(imageFile);
if size(img, 3) == 1
    img = repmat(img, [1, 1, 3]);  % MedSAM expects 3-channel input
end
img = im2single(img);
imageSize = size(img, [1, 2]);
fprintf('Image loaded: [%d x %d]\n', imageSize(1), imageSize(2));

%% Step 2: Load the MedSAM model
medsamModel = medicalSegmentAnythingModel;
fprintf('MedSAM model loaded\n');

%% Step 3: Generate image embeddings
embeddings = extractEmbeddings(medsamModel, img);
fprintf('Embeddings generated: [%s]\n', num2str(size(embeddings)));

%% Step 4: Define bounding box prompts
% TODO: Replace with your actual bounding box coordinates
% Format: [x_min, y_min, width, height]
bboxes = [
    100, 100, 200, 200;   % TODO: ROI 1 - e.g., lesion
    % 300, 250, 150, 180;  % TODO: ROI 2 - uncomment for more regions
];
fprintf('Defined %d bounding box prompt(s)\n', size(bboxes, 1));

%% Step 5: Segment objects from embeddings
% R2025b: segmentObjectsFromEmbeddings requires imageSize parameter
numROIs = size(bboxes, 1);
allMasks = false(imageSize(1), imageSize(2), numROIs);

for i = 1:numROIs
    mask = segmentObjectsFromEmbeddings(medsamModel, embeddings, ...
        imageSize, BoundingBox=bboxes(i,:));
    allMasks(:,:,i) = mask;
    fprintf('ROI %d segmented: %d pixels\n', i, nnz(mask));
end

%% Step 6: Post-process segmentation masks
se = strel('disk', 2);
for i = 1:numROIs
    mask_i = bwareaopen(allMasks(:,:,i), 50);  % Remove small regions
    mask_i = imfill(mask_i, 'holes');           % Fill holes
    allMasks(:,:,i) = imclose(mask_i, se);      % Smooth boundaries
end

%% Step 7: Extract region properties
for i = 1:numROIs
    props = regionprops(allMasks(:,:,i), 'Area', 'Centroid', 'Perimeter', 'Eccentricity');
    if ~isempty(props)
        fprintf('ROI %d: Area=%d px, Centroid=[%.1f, %.1f], Perimeter=%.1f\n', ...
            i, props(1).Area, props(1).Centroid, props(1).Perimeter);
    end
end

%% Step 8: Visualize segmentation results
figure('Name', 'MedSAM Segmentation Results');
colors = lines(numROIs);

subplot(1,3,1); imshow(img); title('Original Image');

subplot(1,3,2); imshow(img); hold on;
for i = 1:numROIs
    rectangle('Position', bboxes(i,:), 'EdgeColor', colors(i,:), ...
        'LineWidth', 2, 'LineStyle', '--');
end
hold off; title('Bounding Box Prompts');

subplot(1,3,3); imshow(img); hold on;
for i = 1:numROIs
    boundary = bwboundaries(allMasks(:,:,i));
    for b = 1:length(boundary)
        plot(boundary{b}(:,2), boundary{b}(:,1), 'Color', colors(i,:), 'LineWidth', 2);
    end
end
hold off; title('Segmentation Results');
sgtitle('MedSAM Interactive Segmentation');

%% Step 9: Save results
if ~isfolder(outputDir), mkdir(outputDir); end
for i = 1:numROIs
    imwrite(uint8(allMasks(:,:,i)) * 255, ...
        fullfile(outputDir, sprintf('medsam_mask_roi%d.png', i)));
end
labelMap = zeros(imageSize, 'uint8');
for i = 1:numROIs, labelMap(allMasks(:,:,i)) = i; end
imwrite(labelMap, fullfile(outputDir, 'medsam_labels.png'));
saveas(gcf, fullfile(outputDir, 'medsam_visualization.png'));
fprintf('Results saved to: %s\n', outputDir);
disp('=== MedSAM Segmentation Complete ===');
