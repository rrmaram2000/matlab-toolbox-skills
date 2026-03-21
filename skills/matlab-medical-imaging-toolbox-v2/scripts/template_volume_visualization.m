%% Template: 3D Volume Visualization with Overlays
% Volume rendering with volshow, segmentation overlays, and slice browsing.
% Uses R2025b-compliant volshow with OverlayData (NOT labelvolshow).
% MATLAB R2025b | Medical Imaging Toolbox
%
% Usage:
%   1. Fill in all TODO sections with your data
%   2. Run section-by-section or as complete script
%
% Requirements:
%   - Medical Imaging Toolbox
%   - Image Processing Toolbox

%% TODO: Configure your data paths and parameters
volumeFile = '';  % TODO: Path to volume data (NIfTI, MAT, or DICOM folder)
labelFile = '';   % TODO: Path to segmentation labels (optional, same size as volume)
outputDir = '';   % TODO: Path to save rendered images

%% Step 1: Load volume data
V = single(niftiread(volumeFile));
info = niftiinfo(volumeFile);
voxelSize = info.PixelDimensions(1:3);
R = medicalref3d(size(V), voxelSize);
fprintf('Volume loaded: [%s], voxel: [%.2f, %.2f, %.2f] mm\n', ...
    num2str(size(V)), voxelSize);

%% Step 2: Basic volume rendering with volshow
figure('Name', 'Volume Rendering - Basic');
viewer1 = volshow(V);

%% Step 3: Volume rendering with custom configuration
% TODO: RenderingStyle options: 'VolumeRendering', 'MaximumIntensityProjection',
%   'MinimumIntensityProjection', 'Isosurface', 'SlicePlane'
figure('Name', 'Volume Rendering - Custom');
viewer2 = volshow(V, 'RenderingStyle', 'VolumeRendering', ...
    'Alphamap', linspace(0, 0.3, 256)');

%% Step 4: Segmentation overlay visualization
% R2025b: Use volshow with OverlayData parameter (NOT labelvolshow!)
if ~isempty(labelFile)
    labels = niftiread(labelFile);
else
    % TODO: Remove demo labels when using real data
    labels = zeros(size(V), 'uint8');
    labels(V > prctile(V(:), 70)) = 1;
    labels(V > prctile(V(:), 90)) = 2;
end

figure('Name', 'Volume with Segmentation Overlay');
viewer3 = volshow(V, 'OverlayData', labels);

%% Step 5: Maximum Intensity Projections (MIP)
figure('Name', 'MIP Comparison');
subplot(1,3,1); imshow(squeeze(max(V,[],3)), []); title('MIP - Axial');
subplot(1,3,2); imshow(squeeze(max(V,[],2)), []); title('MIP - Coronal');
subplot(1,3,3); imshow(squeeze(max(V,[],1)), []); title('MIP - Sagittal');
sgtitle('Maximum Intensity Projections');

%% Step 6: Interactive slice browsing with sliceViewer
figure('Name', 'Interactive Slice Browser');
sliceViewer(V);

%% Step 7: Orthogonal slice montage with segmentation contour
figure('Name', 'Orthogonal Slices');
center = round(size(V) / 2);

subplot(2,2,1); imshow(squeeze(V(:,:,center(3))), []);
title(sprintf('Axial (slice %d)', center(3)));

subplot(2,2,2); imshow(squeeze(V(:,center(2),:)), []);
title(sprintf('Coronal (slice %d)', center(2)));

subplot(2,2,3); imshow(squeeze(V(center(1),:,:)), []);
title(sprintf('Sagittal (slice %d)', center(1)));

subplot(2,2,4);
imshow(squeeze(V(:,:,center(3))), []); hold on;
contour(squeeze(labels(:,:,center(3))), [0.5 1.5], 'r', 'LineWidth', 1.5);
hold off; title('Axial + Segmentation');

sgtitle('Orthogonal Views');

%% Step 8: Save rendered images (optional)
% TODO: Uncomment to save figures
% if ~isfolder(outputDir), mkdir(outputDir); end
% exportgraphics(gcf, fullfile(outputDir, 'orthogonal_views.png'), 'Resolution', 300);

disp('=== Volume Visualization Complete ===');
