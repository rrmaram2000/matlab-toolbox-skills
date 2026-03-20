%% MedSAM Tumor Segmentation from CT NIfTI Volume
% Interactively mark foreground/background points on a seed slice, then
% propagate MedSAM segmentation to the full 3D volume.
%
% MATLAB R2025b | Medical Imaging Toolbox + Image Processing Toolbox
%
% Requirements:
%   - Medical Imaging Toolbox
%   - Deep Learning Toolbox
%   - Medical Imaging Toolbox Model for Segment Anything (add-on)
%
% Workflow:
%   1. Load NIfTI CT volume as medicalVolume (preserves spatial referencing)
%   2. Display a transverse slice and interactively select foreground/background points
%   3. Segment the seed slice with MedSAM using point prompts
%   4. Propagate segmentation to all adjacent slices (up and down)
%   5. Post-process the 3D mask (morphological cleanup)
%   6. Visualize and save results

%% ---- USER CONFIGURATION ----
niftiFile   = '';  % TODO: Path to your NIfTI CT file, e.g., '/data/patient01/ct_scan.nii.gz'
outputDir   = '';  % TODO: Path to save results, e.g., '/data/patient01/segmentation'
seedSlice   = []; % TODO: (Optional) Slice index where tumor is most visible.
                   %       Leave empty [] to use the middle transverse slice.
useGPU      = true;  % Set false to force CPU execution

%% Step 1: Load the CT volume with spatial referencing
% Always use medicalVolume to preserve geometry (Critical Rule 2 from skill).
V = medicalVolume(niftiFile);

fprintf('Loaded: %s\n', niftiFile);
fprintf('  Volume size   : [%d x %d x %d]\n', size(V.Voxels));
fprintf('  Voxel spacing : [%.2f x %.2f x %.2f] mm\n', V.VoxelSpacing);
fprintf('  Orientation   : %s\n', V.Orientation);
fprintf('  Num transverse: %d slices\n', V.NumTransverseSlices);

%% Step 2: Load MedSAM model (with GPU if available)
if useGPU && canUseGPU()
    model = medicalSegmentAnythingModel('ExecutionEnvironment', 'gpu');
    fprintf('MedSAM loaded on GPU: %s\n', gpuDevice().Name);
else
    model = medicalSegmentAnythingModel('ExecutionEnvironment', 'cpu');
    fprintf('MedSAM loaded on CPU\n');
end

%% Step 3: Select seed slice and display it
if isempty(seedSlice)
    seedSlice = round(V.NumTransverseSlices / 2);
    fprintf('Using middle transverse slice: %d\n', seedSlice);
end

% Extract slice and normalize to [0, 1] for MedSAM
seedImg = double(extractSlice(V, seedSlice, 'transverse'));
seedImg = mat2gray(seedImg);  % Normalize to [0, 1]
imageSize = size(seedImg, [1, 2]);

fprintf('Seed slice %d extracted: [%d x %d]\n', seedSlice, imageSize);

%% Step 4: Interactive point selection on seed slice
% Left-click  = foreground (tumor)
% Right-click = background (non-tumor)
% Press Enter  = finalize selection

fig = figure('Name', 'MedSAM - Mark Tumor Points', ...
    'NumberTitle', 'off', 'Position', [100, 100, 800, 700]);
imshow(seedImg, []);
title(sprintf('Slice %d  |  LEFT-click: tumor  |  RIGHT-click: background  |  ENTER: done', ...
    seedSlice), 'FontSize', 12);

fgPoints = [];  % Foreground (tumor) points [x, y] per row
bgPoints = [];  % Background points [x, y] per row

fprintf('\nMark points on the tumor:\n');
fprintf('  Left-click  inside the tumor (foreground)\n');
fprintf('  Right-click outside the tumor (background)\n');
fprintf('  Press Enter when done\n\n');

while true
    [x, y, button] = ginput(1);

    if isempty(button)
        break;  % Enter pressed - done selecting
    end

    if button == 1  % Left click -> foreground
        fgPoints = [fgPoints; x, y]; %#ok<AGROW>
        hold on;
        plot(x, y, 'go', 'MarkerSize', 12, 'LineWidth', 3, 'MarkerFaceColor', 'g');
        text(x + 5, y, sprintf('FG%d', size(fgPoints, 1)), 'Color', 'g', 'FontSize', 10);
    elseif button == 3  % Right click -> background
        bgPoints = [bgPoints; x, y]; %#ok<AGROW>
        hold on;
        plot(x, y, 'rx', 'MarkerSize', 12, 'LineWidth', 3);
        text(x + 5, y, sprintf('BG%d', size(bgPoints, 1)), 'Color', 'r', 'FontSize', 10);
    end
end
hold off;

fprintf('Selected %d foreground and %d background points\n', ...
    size(fgPoints, 1), size(bgPoints, 1));

if isempty(fgPoints)
    error('No foreground points selected. At least one is required.');
end

%% Step 5: Segment the seed slice with MedSAM
% Extract embeddings (slow step -- cached for this slice)
fprintf('Computing embeddings for seed slice...\n');
embeddings = extractEmbeddings(model, seedImg);

% Segment using point prompts
% R2025b signature: segmentObjectsFromEmbeddings(model, embeddings, imageSize, ...)
if isempty(bgPoints)
    seedMask = segmentObjectsFromEmbeddings(model, embeddings, imageSize, ...
        ForegroundPoints=fgPoints);
else
    seedMask = segmentObjectsFromEmbeddings(model, embeddings, imageSize, ...
        ForegroundPoints=fgPoints, ...
        BackgroundPoints=bgPoints);
end

fprintf('Seed slice segmented: %d tumor pixels\n', nnz(seedMask));

% Show seed segmentation result
figure('Name', 'Seed Slice Segmentation', 'NumberTitle', 'off');
imshow(seedImg, []);
hold on;
contour(seedMask, [0.5 0.5], 'r', 'LineWidth', 2);
if ~isempty(fgPoints)
    plot(fgPoints(:,1), fgPoints(:,2), 'go', 'MarkerSize', 10, 'LineWidth', 2, 'MarkerFaceColor', 'g');
end
if ~isempty(bgPoints)
    plot(bgPoints(:,1), bgPoints(:,2), 'rx', 'MarkerSize', 10, 'LineWidth', 2);
end
hold off;
title(sprintf('Seed Segmentation (slice %d) - %d pixels', seedSlice, nnz(seedMask)));

%% Step 6: Propagate segmentation to entire volume (slice-by-slice)
% MedSAM is a 2D model. We propagate by using the centroid and bounding box
% of the previous slice's mask as the prompt for the next slice.

volumeMask = false(size(V.Voxels));
volumeMask(:,:,seedSlice) = seedMask;

fprintf('\nPropagating segmentation through volume...\n');

% --- Propagate UPWARD (seed+1 to last slice) ---
fprintf('  Upward:   slice %d -> %d\n', seedSlice + 1, V.NumTransverseSlices);
for k = (seedSlice + 1):V.NumTransverseSlices
    prevMask = volumeMask(:,:,k-1);
    if ~any(prevMask(:))
        fprintf('  Stopped upward at slice %d (no object in previous slice)\n', k);
        break;
    end

    % Derive prompt from previous mask: centroid as foreground point
    props = regionprops(prevMask, 'Centroid', 'BoundingBox');
    if isempty(props)
        break;
    end
    fg = props(1).Centroid;  % [x, y]

    % Extract current slice and compute embeddings
    sliceImg = mat2gray(double(extractSlice(V, k, 'transverse')));
    sliceImageSize = size(sliceImg, [1, 2]);
    emb = extractEmbeddings(model, sliceImg);

    % Segment with centroid prompt
    mask = segmentObjectsFromEmbeddings(model, emb, sliceImageSize, ...
        ForegroundPoints=fg);

    % Sanity check: if segmented area is wildly different, stop
    prevArea = nnz(prevMask);
    currArea = nnz(mask);
    if currArea < 0.05 * prevArea || currArea > 5 * prevArea
        fprintf('  Stopped upward at slice %d (area ratio %.2f)\n', k, currArea/prevArea);
        break;
    end

    volumeMask(:,:,k) = mask;

    if mod(k, 10) == 0
        fprintf('    Slice %d: %d pixels\n', k, nnz(mask));
    end
end

% --- Propagate DOWNWARD (seed-1 to first slice) ---
fprintf('  Downward: slice %d -> 1\n', seedSlice - 1);
for k = (seedSlice - 1):-1:1
    prevMask = volumeMask(:,:,k+1);
    if ~any(prevMask(:))
        fprintf('  Stopped downward at slice %d (no object in previous slice)\n', k);
        break;
    end

    props = regionprops(prevMask, 'Centroid', 'BoundingBox');
    if isempty(props)
        break;
    end
    fg = props(1).Centroid;

    sliceImg = mat2gray(double(extractSlice(V, k, 'transverse')));
    sliceImageSize = size(sliceImg, [1, 2]);
    emb = extractEmbeddings(model, sliceImg);

    mask = segmentObjectsFromEmbeddings(model, emb, sliceImageSize, ...
        ForegroundPoints=fg);

    prevArea = nnz(prevMask);
    currArea = nnz(mask);
    if currArea < 0.05 * prevArea || currArea > 5 * prevArea
        fprintf('  Stopped downward at slice %d (area ratio %.2f)\n', k, currArea/prevArea);
        break;
    end

    volumeMask(:,:,k) = mask;

    if mod(k, 10) == 0
        fprintf('    Slice %d: %d pixels\n', k, nnz(mask));
    end
end

numSegSlices = sum(any(any(volumeMask, 1), 2));
fprintf('Propagation complete: %d slices contain tumor\n', numSegSlices);

%% Step 7: Post-process the 3D mask with morphological operations (IPT)
% Clean up noise, fill holes, and smooth boundaries.

fprintf('Post-processing 3D mask...\n');

% Remove small connected components (< 100 voxels)
cc = bwconncomp(volumeMask);
numPixels = cellfun(@numel, cc.PixelIdxList);
smallIdx = numPixels < 100;
for i = find(smallIdx)
    volumeMask(cc.PixelIdxList{i}) = false;
end
fprintf('  Removed %d small components (< 100 voxels)\n', sum(smallIdx));

% Fill holes slice-by-slice
for k = 1:size(volumeMask, 3)
    volumeMask(:,:,k) = imfill(volumeMask(:,:,k), 'holes');
end

% Morphological closing to smooth boundaries
se = strel('sphere', 2);
volumeMask = imclose(volumeMask, se);

% Keep only the largest connected component (the tumor)
cc = bwconncomp(volumeMask);
if cc.NumObjects > 1
    [~, maxIdx] = max(cellfun(@numel, cc.PixelIdxList));
    cleanMask = false(size(volumeMask));
    cleanMask(cc.PixelIdxList{maxIdx}) = true;
    volumeMask = cleanMask;
    fprintf('  Kept largest component (%d voxels)\n', nnz(volumeMask));
end

fprintf('Final tumor mask: %d voxels\n', nnz(volumeMask));

%% Step 8: Compute tumor volume in physical units
% Use voxel spacing from the medicalVolume to convert voxels to mm^3 / cm^3.
voxelVol_mm3 = prod(V.VoxelSpacing);  % Volume of one voxel in mm^3
tumorVol_mm3 = nnz(volumeMask) * voxelVol_mm3;
tumorVol_cm3 = tumorVol_mm3 / 1000;

fprintf('\nTumor Volume Measurement:\n');
fprintf('  Voxel count : %d\n', nnz(volumeMask));
fprintf('  Voxel size  : %.2f x %.2f x %.2f mm\n', V.VoxelSpacing);
fprintf('  Volume      : %.2f mm^3 (%.2f cm^3 = %.2f mL)\n', ...
    tumorVol_mm3, tumorVol_cm3, tumorVol_cm3);

%% Step 9: Visualize results

% --- 9a: Overlay on seed slice ---
figure('Name', 'Tumor Segmentation - Seed Slice', 'NumberTitle', 'off');
imshow(seedImg, []);
hold on;
contour(volumeMask(:,:,seedSlice), [0.5 0.5], 'r', 'LineWidth', 2);
hold off;
title(sprintf('Tumor Segmentation - Slice %d', seedSlice));

% --- 9b: Montage of segmented slices ---
segSliceIdx = find(squeeze(any(any(volumeMask, 1), 2)));
if ~isempty(segSliceIdx)
    % Show up to 20 representative segmented slices
    step = max(1, floor(numel(segSliceIdx) / 20));
    showIdx = segSliceIdx(1:step:end);

    figure('Name', 'Tumor Segmentation - Slice Montage', ...
        'NumberTitle', 'off', 'Position', [50, 50, 1400, 800]);
    nShow = numel(showIdx);
    nCols = ceil(sqrt(nShow));
    nRows = ceil(nShow / nCols);

    for i = 1:nShow
        k = showIdx(i);
        sliceImg = mat2gray(double(extractSlice(V, k, 'transverse')));
        subplot(nRows, nCols, i);
        imshow(sliceImg, []);
        hold on;
        contour(volumeMask(:,:,k), [0.5 0.5], 'r', 'LineWidth', 1.5);
        hold off;
        title(sprintf('Slice %d', k), 'FontSize', 8);
    end
    sgtitle('Tumor Segmentation Across Slices');
end

% --- 9c: 3D volume rendering with segmentation overlay ---
% R2025b: use volshow with OverlayData (labelvolshow was removed)
figure('Name', '3D Tumor Visualization', 'NumberTitle', 'off');
volshow(V.Voxels, OverlayData=uint8(volumeMask), ...
    OverlayColormap=[1, 0, 0], ...     % Red for tumor
    OverlayAlphamap=[0, 0.6], ...       % Background transparent, tumor semi-opaque
    BackgroundColor='black');
title('3D CT with Tumor Overlay');

%% Step 10: Save segmentation results
if ~isfolder(outputDir)
    mkdir(outputDir);
end

% Save as NIfTI with original spatial referencing (Critical Rule 2)
segVol = medicalVolume(uint8(volumeMask), V.VolumeGeometry);
segVol.Modality = 'SEG';
outputNifti = fullfile(outputDir, 'tumor_segmentation.nii.gz');
write(segVol, outputNifti);
fprintf('\nSaved segmentation NIfTI: %s\n', outputNifti);

% Save tumor measurements to a text file
statsFile = fullfile(outputDir, 'tumor_stats.txt');
fid = fopen(statsFile, 'w');
fprintf(fid, 'Tumor Segmentation Report\n');
fprintf(fid, '=========================\n');
fprintf(fid, 'Source file   : %s\n', niftiFile);
fprintf(fid, 'Date          : %s\n', datetime('now'));
fprintf(fid, 'Seed slice    : %d\n', seedSlice);
fprintf(fid, 'FG points     : %d\n', size(fgPoints, 1));
fprintf(fid, 'BG points     : %d\n', size(bgPoints, 1));
fprintf(fid, 'Slices w/tumor: %d / %d\n', numSegSlices, V.NumTransverseSlices);
fprintf(fid, 'Voxel count   : %d\n', nnz(volumeMask));
fprintf(fid, 'Voxel spacing : %.2f x %.2f x %.2f mm\n', V.VoxelSpacing);
fprintf(fid, 'Tumor volume  : %.2f mm^3 (%.2f cm^3)\n', tumorVol_mm3, tumorVol_cm3);
fclose(fid);
fprintf('Saved tumor stats: %s\n', statsFile);

% Save seed slice overlay as PNG
seedOverlayFile = fullfile(outputDir, 'seed_slice_overlay.png');
figSeed = figure('Visible', 'off');
imshow(seedImg, []);
hold on;
contour(volumeMask(:,:,seedSlice), [0.5 0.5], 'r', 'LineWidth', 2);
if ~isempty(fgPoints)
    plot(fgPoints(:,1), fgPoints(:,2), 'go', 'MarkerSize', 10, 'LineWidth', 2, 'MarkerFaceColor', 'g');
end
if ~isempty(bgPoints)
    plot(bgPoints(:,1), bgPoints(:,2), 'rx', 'MarkerSize', 10, 'LineWidth', 2);
end
hold off;
title(sprintf('Seed Slice %d | Volume = %.2f cm^3', seedSlice, tumorVol_cm3));
exportgraphics(figSeed, seedOverlayFile, 'Resolution', 150);
close(figSeed);
fprintf('Saved seed overlay: %s\n', seedOverlayFile);

fprintf('\n=== MedSAM Tumor Segmentation Complete ===\n');
