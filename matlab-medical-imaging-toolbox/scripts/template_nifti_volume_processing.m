%% Template: NIfTI Volume Processing Pipeline
% Load NIfTI volumes, apply processing (normalization, resampling), and save.
% Preserves spatial reference information throughout the pipeline.
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
inputFile = '';   % TODO: Path to input NIfTI file (e.g., '/data/brain_t1.nii.gz')
outputDir = '';   % TODO: Path to save processed output (e.g., '/results/')

%% Step 1: Load NIfTI volume and header information
% Read the volume data and metadata
V = niftiread(inputFile);
info = niftiinfo(inputFile);

fprintf('=== NIfTI Volume Info ===\n');
fprintf('Dimensions: [%s]\n', num2str(size(V)));
fprintf('Data type: %s\n', info.Datatype);
fprintf('Voxel size: [%.3f, %.3f, %.3f] mm\n', info.PixelDimensions(1:3));
fprintf('Intensity range: [%.1f, %.1f]\n', min(V(:)), max(V(:)));

%% Step 2: Create spatial referencing from NIfTI header
voxelSize = info.PixelDimensions(1:3);
R = medicalref3d(size(V), voxelSize);

% Create medicalVolume for toolbox interoperability
medVol = medicalVolume(V, R);

%% Step 3: Intensity normalization
% TODO: Choose normalization method (uncomment one)

% Method A: Min-max normalization to [0, 1]
Vnorm = double(V);
Vnorm = (Vnorm - min(Vnorm(:))) / (max(Vnorm(:)) - min(Vnorm(:)));

% Method B: Z-score normalization (zero mean, unit variance)
% Vnorm = double(V);
% brainMask = Vnorm > prctile(Vnorm(:), 5);  % Simple background removal
% mu = mean(Vnorm(brainMask));
% sigma = std(Vnorm(brainMask));
% Vnorm = (Vnorm - mu) / sigma;

% Method C: Percentile clipping + rescaling
% Vnorm = double(V);
% pLow = prctile(Vnorm(:), 1);
% pHigh = prctile(Vnorm(:), 99);
% Vnorm = (Vnorm - pLow) / (pHigh - pLow);
% Vnorm = max(0, min(1, Vnorm));

fprintf('Normalized range: [%.4f, %.4f]\n', min(Vnorm(:)), max(Vnorm(:)));

%% Step 4: Volume resampling to isotropic resolution
% TODO: Set target isotropic voxel size (mm)
targetVoxelSize = 1.0;  % TODO: Target resolution in mm

% Compute scale factors for resampling
scaleFactors = voxelSize / targetVoxelSize;
newSize = round(size(V) .* scaleFactors);

% Resample using interpolation
Vresampled = imresize3(Vnorm, newSize, 'Method', 'linear');
Rnew = medicalref3d(size(Vresampled), [targetVoxelSize, targetVoxelSize, targetVoxelSize]);

fprintf('Resampled volume: [%s] at %.1f mm isotropic\n', ...
    num2str(size(Vresampled)), targetVoxelSize);

%% Step 5: Optional smoothing (noise reduction)
% TODO: Uncomment to apply Gaussian smoothing
% sigma = 1.0;  % Smoothing kernel width in voxels
% Vsmooth = imgaussfilt3(Vresampled, sigma);
% fprintf('Smoothing applied with sigma = %.1f voxels\n', sigma);
Vprocessed = Vresampled;  % Use resampled volume as final

%% Step 6: Visualize original vs processed
figure('Name', 'NIfTI Processing Comparison');
midSlice_orig = round(size(V, 3) / 2);
midSlice_proc = round(size(Vprocessed, 3) / 2);

subplot(1,2,1);
imshow(V(:,:,midSlice_orig), []);
title(sprintf('Original (%.1fx%.1fx%.1f mm)', voxelSize));

subplot(1,2,2);
imshow(Vprocessed(:,:,midSlice_proc), []);
title(sprintf('Processed (%.1f mm iso)', targetVoxelSize));

sgtitle('NIfTI Volume Processing Result');

%% Step 7: Save processed NIfTI with updated header
if ~isfolder(outputDir), mkdir(outputDir); end

% Update NIfTI header for the processed volume
infoOut = info;
infoOut.ImageSize = size(Vprocessed);
infoOut.PixelDimensions = [targetVoxelSize, targetVoxelSize, targetVoxelSize];
infoOut.Datatype = 'single';

outputFile = fullfile(outputDir, 'processed_volume.nii.gz');
niftiwrite(single(Vprocessed), outputFile, infoOut, 'Compressed', true);
fprintf('Processed volume saved to: %s\n', outputFile);

%% Step 8: Save processing log
logFile = fullfile(outputDir, 'processing_log.txt');
fid = fopen(logFile, 'w');
fprintf(fid, 'NIfTI Processing Log\n');
fprintf(fid, 'Date: %s\n', datetime('now'));
fprintf(fid, 'Input: %s\n', inputFile);
fprintf(fid, 'Original size: [%s]\n', num2str(size(V)));
fprintf(fid, 'Original voxel: [%.3f, %.3f, %.3f] mm\n', voxelSize);
fprintf(fid, 'Output size: [%s]\n', num2str(size(Vprocessed)));
fprintf(fid, 'Output voxel: %.3f mm isotropic\n', targetVoxelSize);
fprintf(fid, 'Normalization: min-max\n');
fclose(fid);

disp('=== NIfTI Processing Pipeline Complete ===');
