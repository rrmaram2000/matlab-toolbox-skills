%% Template: Multimodal Image Fusion (PET/CT or Multi-Sequence MRI)
% Register two imaging modalities and create fused visualizations.
% Supports PET/CT overlay and multi-sequence MRI fusion.
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
structuralFile = '';   % TODO: Path to structural volume (CT or T1-MRI)
functionalFile = '';   % TODO: Path to functional volume (PET, fMRI, or other MRI seq)
outputDir = '';        % TODO: Path to save fusion results
fusionType = 'PET_CT'; % TODO: Options: 'PET_CT', 'MRI_multisequence'

%% Step 1: Load both volumes
structVol = single(niftiread(structuralFile));
structInfo = niftiinfo(structuralFile);
structVoxel = structInfo.PixelDimensions(1:3);
Rstruct = medicalref3d(size(structVol), structVoxel);

funcVol = single(niftiread(functionalFile));
funcVoxel = niftiinfo(functionalFile).PixelDimensions(1:3);

fprintf('Structural: [%s], Functional: [%s]\n', ...
    num2str(size(structVol)), num2str(size(funcVol)));

%% Step 2: Register functional to structural space
Rstruct3d = imref3d(size(structVol), structVoxel(2), structVoxel(1), structVoxel(3));
Rfunc3d = imref3d(size(funcVol), funcVoxel(2), funcVoxel(1), funcVoxel(3));

[optimizer, metric] = imregconfig('multimodal');
optimizer.InitialRadius = 0.004;
optimizer.MaximumIterations = 300;

tform = imregtform(funcVol, Rfunc3d, structVol, Rstruct3d, 'affine', optimizer, metric);
funcRegistered = imwarp(funcVol, Rfunc3d, tform, ...
    'OutputView', Rstruct3d, 'InterpolationMethod', 'linear');
fprintf('Registration complete\n');

%% Step 3: Normalize volumes for visualization
structNorm = (structVol - min(structVol(:))) / (max(structVol(:)) - min(structVol(:)));
funcNorm = funcRegistered;
if strcmp(fusionType, 'PET_CT')
    funcNorm(funcNorm < prctile(funcNorm(:), 60)) = 0;  % TODO: Adjust threshold
end
funcNorm = funcNorm / max(funcNorm(:));

%% Step 4: Create color-coded fusion
midSlice = round(size(structVol, 3) / 2);
structSlice = structNorm(:,:,midSlice);
funcSlice = funcNorm(:,:,midSlice);

cmap = hot(256);  % TODO: Use jet(256) for MRI fusion
funcIdx = max(1, min(256, round(funcSlice * 255) + 1));
funcRGB = ind2rgb(funcIdx, cmap);
structRGB = repmat(structSlice, [1, 1, 3]);

alpha = 0.4;  % TODO: Overlay transparency (0=transparent, 1=opaque)
alphaMask = repmat(funcSlice > 0, [1, 1, 3]);
fusedRGB = structRGB .* (1 - alpha * alphaMask) + funcRGB .* (alpha * alphaMask);
fusedRGB = max(0, min(1, fusedRGB));

%% Step 5: 3D volume rendering with volshow
figure('Name', '3D Volume Rendering');
volshow(structVol);
title('Structural Volume');

%% Step 6: Visualize fusion results
figure('Name', 'Multimodal Fusion Results');

subplot(2,3,1); imshow(structSlice, []); title('Structural');
subplot(2,3,2); imshow(funcSlice, []); colormap(gca, cmap); title('Functional');
subplot(2,3,3); imshow(fusedRGB); title(sprintf('Fused (alpha=%.1f)', alpha));

subplot(2,3,4);
imshow(imfuse(structSlice, funcSlice, 'falsecolor')); title('False Color');

subplot(2,3,5);
imshow(imfuse(structSlice, funcSlice, 'checkerboard')); title('Checkerboard');

subplot(2,3,6);
imshow(abs(structSlice - funcSlice), []); colorbar; title('Difference');

sgtitle(sprintf('Multimodal Fusion: %s', strrep(fusionType, '_', '/')));

%% Step 7: Save fusion results
if ~isfolder(outputDir), mkdir(outputDir); end
outInfo = structInfo; outInfo.Datatype = 'single';
niftiwrite(single(funcRegistered), ...
    fullfile(outputDir, 'functional_registered.nii.gz'), outInfo, 'Compressed', true);
imwrite(fusedRGB, fullfile(outputDir, 'fusion_overlay.png'));
save(fullfile(outputDir, 'registration_transform.mat'), 'tform');
fprintf('Fusion results saved to: %s\n', outputDir);
disp('=== Multimodal Fusion Complete ===');
