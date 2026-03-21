%% Template: Deformable (Non-Rigid) Registration Pipeline
% Non-rigid registration for multi-timepoint studies (e.g., tumor monitoring).
% Computes and visualizes the deformation field.
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
fixedFile = '';    % TODO: Path to fixed/reference volume (e.g., baseline scan)
movingFile = '';   % TODO: Path to moving volume (e.g., follow-up scan)
outputDir = '';    % TODO: Path to save registration results
roiFile = '';      % TODO: (Optional) Path to ROI mask for focused analysis

%% Step 1: Load fixed and moving volumes
fixedVol = single(niftiread(fixedFile));
fixedInfo = niftiinfo(fixedFile);
fixedVoxel = fixedInfo.PixelDimensions(1:3);

movingVol = single(niftiread(movingFile));
movingVoxel = niftiinfo(movingFile).PixelDimensions(1:3);

fprintf('Fixed: [%s], Moving: [%s]\n', num2str(size(fixedVol)), num2str(size(movingVol)));

%% Step 2: Initial rigid alignment (recommended before deformable)
Rfixed3d = imref3d(size(fixedVol), fixedVoxel(2), fixedVoxel(1), fixedVoxel(3));
Rmoving3d = imref3d(size(movingVol), movingVoxel(2), movingVoxel(1), movingVoxel(3));

[optimizer, metric] = imregconfig('monomodal');
% TODO: For multimodal data, use imregconfig('multimodal')

tformRigid = imregtform(movingVol, Rmoving3d, fixedVol, Rfixed3d, ...
    'rigid', optimizer, metric);
movingRigid = imwarp(movingVol, Rmoving3d, tformRigid, ...
    'OutputView', Rfixed3d, 'InterpolationMethod', 'linear');
fprintf('Rigid pre-alignment complete\n');

%% Step 3: Deformable (non-rigid) registration
% TODO: Adjust GridRegularization (higher = smoother), GridSpacing, NumIterations
[D, registeredVol] = imregdeform(movingRigid, fixedVol, ...
    'GridRegularization', 0.4, 'GridSpacing', [4 4 4], 'NumIterations', 100);
fprintf('Deformable registration complete\n');

%% Step 4: Compute deformation field statistics
Dx = D(:,:,:,1); Dy = D(:,:,:,2); Dz = D(:,:,:,3);
magD = sqrt(Dx.^2 + Dy.^2 + Dz.^2);
magD_mm = magD .* mean(fixedVoxel);

fprintf('Max displacement: %.2f mm, Mean: %.2f mm\n', max(magD_mm(:)), mean(magD_mm(:)));

%% Step 5: Analyze deformation in ROI (e.g., tumor region)
if ~isempty(roiFile)
    roi = logical(niftiread(roiFile));
else
    roi = false(size(fixedVol));
    center = round(size(fixedVol) / 2);
    roi(center(1)-10:center(1)+10, center(2)-10:center(2)+10, ...
        center(3)-5:center(3)+5) = true;  % TODO: Replace with actual mask
end
fprintf('ROI mean displacement: %.2f mm (max: %.2f mm)\n', ...
    mean(magD_mm(roi)), max(magD_mm(roi)));

%% Step 6: Visualize registration results
midSlice = round(size(fixedVol, 3) / 2);
figure('Name', 'Deformable Registration Results');

subplot(2,3,1); imshow(fixedVol(:,:,midSlice), []); title('Fixed (Baseline)');
subplot(2,3,2); imshow(movingRigid(:,:,midSlice), []); title('After Rigid');
subplot(2,3,3); imshow(registeredVol(:,:,midSlice), []); title('After Deformable');

subplot(2,3,4);
imshow(imfuse(fixedVol(:,:,midSlice), registeredVol(:,:,midSlice), 'falsecolor'));
title('Overlay');

subplot(2,3,5);
imshow(magD_mm(:,:,midSlice), []); colormap(gca, 'jet'); colorbar;
title('Displacement (mm)');

subplot(2,3,6);
quiverStep = 4;
[X, Y] = meshgrid(1:quiverStep:size(fixedVol,2), 1:quiverStep:size(fixedVol,1));
imshow(fixedVol(:,:,midSlice), []); hold on;
quiver(X, Y, Dx(1:quiverStep:end,1:quiverStep:end,midSlice), ...
    Dy(1:quiverStep:end,1:quiverStep:end,midSlice), 'y', 'LineWidth', 0.5);
hold off; title('Deformation Vectors');

sgtitle('Deformable Registration: Multi-Timepoint Study');

%% Step 7: Save results
if ~isfolder(outputDir), mkdir(outputDir); end
outInfo = fixedInfo; outInfo.Datatype = 'single';
niftiwrite(single(registeredVol), ...
    fullfile(outputDir, 'deformable_registered.nii.gz'), outInfo, 'Compressed', true);
save(fullfile(outputDir, 'deformation_field.mat'), 'D', 'tformRigid', 'magD_mm');
fprintf('Results saved to: %s\n', outputDir);
disp('=== Deformable Registration Pipeline Complete ===');
