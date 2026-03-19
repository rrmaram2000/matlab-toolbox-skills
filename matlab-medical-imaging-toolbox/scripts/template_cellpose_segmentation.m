%% Template: Cellpose Cell/Nuclei Segmentation
% Segment cells and nuclei in 2D microscopy images using segmentCells2D.
% Extract cell properties and compute population statistics.
% MATLAB R2025b | Medical Imaging Toolbox
%
% Usage:
%   1. Fill in all TODO sections with your data
%   2. Run section-by-section or as complete script
%
% Requirements:
%   - Medical Imaging Toolbox
%   - Image Processing Toolbox
%   - Deep Learning Toolbox

%% TODO: Configure your data paths and parameters
imageFile = '';   % TODO: Path to microscopy image (fluorescence, H&E, etc.)
outputDir = '';   % TODO: Path to save segmentation results

%% Step 1: Load and prepare the microscopy image
img = imread(imageFile);
if size(img, 3) == 3
    imgGray = im2gray(img);
else
    imgGray = img;
end
imgGray = im2single(imgGray);
fprintf('Image loaded: [%d x %d], class: %s\n', size(img,1), size(img,2), class(img));

%% Step 2: Preprocess image for cell detection
% TODO: Adjust preprocessing based on your image type
imgEnhanced = adapthisteq(imgGray, 'NumTiles', [8 8], 'ClipLimit', 0.02);

%% Step 3: Segment cells using segmentCells2D
% TODO: Choose model type: 'cyto' for cytoplasm, 'nuclei' for nuclear
labels = segmentCells2D(imgEnhanced, 'ModelType', 'nuclei');
% TODO: If you know cell diameter, use: segmentCells2D(img, 'ModelType', 'nuclei', 'CellDiameter', 30)
numCells = max(labels(:));
fprintf('Detected %d cells/nuclei\n', numCells);

%% Step 4: Post-process segmentation
labels = imclearborder(labels);
minArea = 50;   % TODO: Minimum cell area in pixels
maxArea = 5000; % TODO: Maximum cell area in pixels

props = regionprops(labels, 'Area');
validIdx = find([props.Area] >= minArea & [props.Area] <= maxArea);
cleanLabels = zeros(size(labels), 'like', labels);
for i = 1:length(validIdx)
    cleanLabels(labels == validIdx(i)) = i;
end
labels = cleanLabels;
fprintf('After filtering: %d cells (removed %d)\n', max(labels(:)), numCells - max(labels(:)));

%% Step 5: Extract cell properties with regionprops
cellProps = regionprops('table', labels, imgGray, ...
    'Area', 'Centroid', 'Perimeter', 'Eccentricity', ...
    'MajorAxisLength', 'MinorAxisLength', ...
    'MeanIntensity', 'Solidity', 'EquivDiameter');
cellProps.Circularity = (4 * pi * cellProps.Area) ./ (cellProps.Perimeter.^2);

fprintf('\n=== Cell Summary: %d cells, mean area=%.1f px^2, mean diam=%.1f px ===\n', ...
    height(cellProps), mean(cellProps.Area), mean(cellProps.EquivDiameter));

%% Step 6: Visualize segmentation results
figure('Name', 'Cellpose Segmentation Results');

subplot(2,2,1);
imshow(img); title('Original Image');

subplot(2,2,2);
labelOverlay = labeloverlay(imgGray, labels, 'Transparency', 0.5);
imshow(labelOverlay); title(sprintf('Segmentation (%d cells)', height(cellProps)));

subplot(2,2,3);
imshow(imgGray, []); hold on;
boundaries = bwboundaries(labels > 0);
for b = 1:length(boundaries)
    plot(boundaries{b}(:,2), boundaries{b}(:,1), 'g', 'LineWidth', 0.5);
end
hold off; title('Cell Boundaries');

subplot(2,2,4);
histogram(cellProps.Area, 30, 'FaceColor', [0.2 0.6 0.8]);
xlabel('Area (px^2)'); ylabel('Count'); title('Cell Area Distribution');
xline(mean(cellProps.Area), 'r--', 'LineWidth', 1.5);

sgtitle('Cell Segmentation Analysis');

%% Step 7: Save results
if ~isfolder(outputDir), mkdir(outputDir); end
writetable(cellProps, fullfile(outputDir, 'cell_properties.csv'));
imwrite(uint16(labels), fullfile(outputDir, 'cell_labels.tif'));
save(fullfile(outputDir, 'population_stats.mat'), 'cellProps');
exportgraphics(gcf, fullfile(outputDir, 'segmentation_results.png'), 'Resolution', 300);

fprintf('Results saved to: %s\n', outputDir);
disp('=== Cellpose Segmentation Complete ===');
