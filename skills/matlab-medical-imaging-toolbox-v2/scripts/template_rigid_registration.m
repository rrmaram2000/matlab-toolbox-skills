%% Template: Rigid Registration of Pre/Post Treatment Scans
% Align pre- and post-treatment scans using moment-based initialization
% followed by intensity-based rigid registration.
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
fixedFile = '';   % TODO: Path to fixed/reference volume (e.g., pre-treatment)
movingFile = '';  % TODO: Path to moving volume (e.g., post-treatment)
outputDir = '';   % TODO: Path to save registration results

%% Step 1: Load fixed and moving volumes
fixedVol = single(niftiread(fixedFile));
fixedInfo = niftiinfo(fixedFile);
fixedVoxel = fixedInfo.PixelDimensions(1:3);
Rfixed = medicalref3d(size(fixedVol), fixedVoxel);

movingVol = single(niftiread(movingFile));
movingVoxel = niftiinfo(movingFile).PixelDimensions(1:3);
Rmoving = medicalref3d(size(movingVol), movingVoxel);

fprintf('Fixed: [%s], Moving: [%s]\n', num2str(size(fixedVol)), num2str(size(movingVol)));

%% Step 2: Create spatial referencing for registration
Rfixed3d = imref3d(size(fixedVol), fixedVoxel(2), fixedVoxel(1), fixedVoxel(3));
Rmoving3d = imref3d(size(movingVol), movingVoxel(2), movingVoxel(1), movingVoxel(3));

%% Step 3: Initial alignment using moment-based registration
tformInit = imregmoment(movingVol, Rmoving3d, fixedVol, Rfixed3d);
fprintf('Initial alignment computed (moment-based)\n');

%% Step 4: Refined rigid registration using intensity-based optimization
% TODO: For multi-modal (CT-MRI), use imregconfig('multimodal')
[optimizer, metric] = imregconfig('monomodal');

tformRigid = imregtform(movingVol, Rmoving3d, fixedVol, Rfixed3d, ...
    'rigid', optimizer, metric, 'InitialTransformation', tformInit);
fprintf('Rigid registration complete\n');

%% Step 5: Apply the transform to the moving volume
registeredVol = imwarp(movingVol, Rmoving3d, tformRigid, ...
    'OutputView', Rfixed3d, 'InterpolationMethod', 'linear');

%% Step 6: Visualize registration results
midSlice = round(size(fixedVol, 3) / 2);
midMoving = round(size(movingVol, 3) / 2);
figure('Name', 'Rigid Registration Results');

subplot(2,3,1); imshow(fixedVol(:,:,midSlice), []); title('Fixed (Reference)');
subplot(2,3,2); imshow(movingVol(:,:,midMoving), []); title('Moving (Original)');
subplot(2,3,3); imshow(registeredVol(:,:,midSlice), []); title('Registered');

subplot(2,3,4);
imshow(imfuse(fixedVol(:,:,midSlice), ...
    imresize(movingVol(:,:,midMoving), [size(fixedVol,1), size(fixedVol,2)]), ...
    'checkerboard'));
title('Before Registration');

subplot(2,3,5);
imshow(imfuse(fixedVol(:,:,midSlice), registeredVol(:,:,midSlice), 'checkerboard'));
title('After Registration');

subplot(2,3,6);
imshow(abs(fixedVol(:,:,midSlice) - registeredVol(:,:,midSlice)), []);
title('Difference'); colorbar;

sgtitle('Rigid Registration: Pre vs Post Treatment');

%% Step 7: Save registration results
if ~isfolder(outputDir), mkdir(outputDir); end
outInfo = fixedInfo; outInfo.Datatype = 'single';
niftiwrite(single(registeredVol), ...
    fullfile(outputDir, 'registered_volume.nii.gz'), outInfo, 'Compressed', true);
save(fullfile(outputDir, 'rigid_transform.mat'), 'tformRigid', 'tformInit');
fprintf('Results saved to: %s\n', outputDir);
disp('=== Rigid Registration Complete ===');
