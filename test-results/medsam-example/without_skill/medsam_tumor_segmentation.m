%% MedSAM Tumor Segmentation from CT Volume (MATLAB R2025b)
% This script demonstrates how to:
%   1. Load a NIfTI CT volume
%   2. Interactively select points on a tumor in one slice
%   3. Use MedSAM to segment the tumor in that slice
%   4. Propagate the segmentation to the full 3D volume
%
% Requirements:
%   - MATLAB R2025b
%   - Computer Vision Toolbox
%   - Medical Imaging Toolbox
%   - Deep Learning Toolbox
%   - MedSAM support package (install via Add-On Explorer)

%% Step 1: Load the NIfTI CT Volume
niftiFile = "path/to/your/ct_scan.nii.gz";  % <-- Update this path
V = niftiread(niftiFile);
info = niftiinfo(niftiFile);

% Convert to single precision for processing
V = single(V);

% Apply CT windowing for soft tissue (adjust for your use case)
windowCenter = 40;   % HU
windowWidth  = 400;  % HU
minHU = windowCenter - windowWidth/2;
maxHU = windowCenter + windowWidth/2;
Vwin = mat2clim(V, [minHU maxHU]);  % Normalize to [0,1]

fprintf("Volume loaded: %d x %d x %d\n", size(V,1), size(V,2), size(V,3));

%% Step 2: Select the Seed Slice and Mark Points Interactively
% Display the middle slice and let user pick a slice with the tumor
midSlice = round(size(Vwin, 3) / 2);

fig1 = figure("Name", "Select Seed Slice");
sliceViewer(Vwin);
title("Scroll to the slice with the tumor, then note the slice number");
disp("Use the slice viewer to find the tumor. Enter the slice number below:");
seedSlice = input("Enter seed slice number: ");
close(fig1);

% Display the seed slice for interactive point marking
seedImg = Vwin(:, :, seedSlice);

fig2 = figure("Name", "Mark Tumor Points");
imshow(seedImg, []);
title(sprintf("Slice %d - Click on tumor points (right-click to finish)", seedSlice));
hold on;

% Interactive point selection using ginput
disp("Click on several points INSIDE the tumor (at least 3-5 points).");
disp("Press Enter when done.");
[px, py] = ginput;  % User clicks points, presses Enter to finish
plot(px, py, 'r+', 'MarkerSize', 12, 'LineWidth', 2);
hold off;

fprintf("Selected %d seed points.\n", numel(px));

%% Step 3: Create Bounding Box from Selected Points
% Compute a bounding box around the selected points with padding
padPixels = 20;  % Padding around the points

xMin = max(1, floor(min(px)) - padPixels);
xMax = min(size(seedImg, 2), ceil(max(px)) + padPixels);
yMin = max(1, floor(min(py)) - padPixels);
yMax = min(size(seedImg, 1), ceil(max(py)) + padPixels);

bbox = [xMin, yMin, xMax - xMin, yMax - yMin];  % [x, y, width, height]
fprintf("Bounding box: [%d, %d, %d, %d]\n", bbox);

%% Step 4: Load MedSAM and Segment the Seed Slice
% Create the MedSAM model
medsam = medicalSAM;

% Prepare the seed slice as an RGB image (MedSAM expects 3-channel)
seedRGB = repmat(seedImg, [1, 1, 3]);

% Compute image embeddings for the seed slice
embeddings = imageEmbeddings(medsam, seedRGB);

% Segment using the bounding box prompt
seedMask = segmentObjectsFromEmbeddings(medsam, embeddings, ...
    size(seedRGB, [1 2]), BoundingBox=bbox);

% Display seed slice segmentation result
figure("Name", "Seed Slice Segmentation");
imshow(seedImg, []);
hold on;
visboundaries(seedMask, "Color", "r", "LineWidth", 1.5);
title(sprintf("MedSAM Segmentation - Slice %d", seedSlice));
hold off;

%% Step 5: Propagate Segmentation to Full 3D Volume
% Strategy: Starting from the seed slice, propagate the bounding box to
% adjacent slices. Use the mask from the previous slice to derive the
% bounding box for the next slice. Stop when no object is detected.

numSlices = size(Vwin, 3);
volumeMask = false(size(Vwin));

% Store the seed slice mask
volumeMask(:, :, seedSlice) = seedMask;
currentBBox = bbox;

fprintf("Propagating segmentation through %d slices...\n", numSlices);

% --- Propagate forward (seed+1 to end) ---
for s = (seedSlice + 1):numSlices
    sliceImg = Vwin(:, :, s);
    sliceRGB = repmat(sliceImg, [1, 1, 3]);

    % Get bounding box from previous slice mask
    prevMask = volumeMask(:, :, s - 1);
    currentBBox = maskToBoundingBox(prevMask, padPixels, size(sliceImg));

    if isempty(currentBBox)
        fprintf("  Forward propagation stopped at slice %d (no mask).\n", s);
        break;
    end

    % Compute embeddings and segment
    emb = imageEmbeddings(medsam, sliceRGB);
    mask = segmentObjectsFromEmbeddings(medsam, emb, ...
        size(sliceRGB, [1 2]), BoundingBox=currentBBox);

    % Check if the mask is reasonable (not too small / not empty)
    if sum(mask(:)) < 10
        fprintf("  Forward propagation stopped at slice %d (mask too small).\n", s);
        break;
    end

    volumeMask(:, :, s) = mask;

    if mod(s, 10) == 0
        fprintf("  Processed slice %d/%d (forward)\n", s, numSlices);
    end
end

% --- Propagate backward (seed-1 to 1) ---
for s = (seedSlice - 1):-1:1
    sliceImg = Vwin(:, :, s);
    sliceRGB = repmat(sliceImg, [1, 1, 3]);

    % Get bounding box from previous (s+1) slice mask
    prevMask = volumeMask(:, :, s + 1);
    currentBBox = maskToBoundingBox(prevMask, padPixels, size(sliceImg));

    if isempty(currentBBox)
        fprintf("  Backward propagation stopped at slice %d (no mask).\n", s);
        break;
    end

    % Compute embeddings and segment
    emb = imageEmbeddings(medsam, sliceRGB);
    mask = segmentObjectsFromEmbeddings(medsam, emb, ...
        size(sliceRGB, [1 2]), BoundingBox=currentBBox);

    if sum(mask(:)) < 10
        fprintf("  Backward propagation stopped at slice %d (mask too small).\n", s);
        break;
    end

    volumeMask(:, :, s) = mask;

    if mod(s, 10) == 0
        fprintf("  Processed slice %d/%d (backward)\n", s, numSlices);
    end
end

fprintf("Segmentation complete. %d slices contain tumor mask.\n", ...
    sum(any(any(volumeMask, 1), 2)));

%% Step 6: Post-Processing - Clean Up the 3D Mask
% Apply morphological operations for smoother segmentation
se = strel("sphere", 2);
volumeMask = imclose(volumeMask, se);
volumeMask = imopen(volumeMask, se);

% Keep only the largest connected component
CC = bwconncomp(volumeMask);
numPixels = cellfun(@numel, CC.PixelIdxList);
[~, idx] = max(numPixels);
cleanMask = false(size(volumeMask));
cleanMask(CC.PixelIdxList{idx}) = true;
volumeMask = cleanMask;

%% Step 7: Visualize the 3D Segmentation Result
figure("Name", "3D Tumor Segmentation Result");

% Show volume with overlay
volshow(V, OverlayData=volumeMask, ...
    OverlayAlphamap=[0, 0.6], ...
    RenderingStyle="GradientOpacity");
title("3D Tumor Segmentation (MedSAM)");

%% Step 8: Save the Segmentation Mask as NIfTI
outputFile = "tumor_segmentation_mask.nii.gz";
outInfo = info;
outInfo.Datatype = "uint8";
outInfo.BitsPerPixel = 8;
niftiwrite(uint8(volumeMask), outputFile, outInfo, "Compressed", true);
fprintf("Segmentation mask saved to: %s\n", outputFile);

%% Step 9: Compute Basic Tumor Metrics
voxelSize = info.PixelDimensions;  % [mm, mm, mm]
voxelVolume_mm3 = prod(voxelSize);
tumorVoxels = sum(volumeMask(:));
tumorVolume_mm3 = tumorVoxels * voxelVolume_mm3;
tumorVolume_cm3 = tumorVolume_mm3 / 1000;

fprintf("\n--- Tumor Metrics ---\n");
fprintf("Voxel dimensions: %.2f x %.2f x %.2f mm\n", voxelSize(1), voxelSize(2), voxelSize(3));
fprintf("Tumor voxels: %d\n", tumorVoxels);
fprintf("Tumor volume: %.2f mm^3 (%.2f cm^3)\n", tumorVolume_mm3, tumorVolume_cm3);

%% Helper Function: Convert Mask to Bounding Box
function bbox = maskToBoundingBox(mask, pad, imgSize)
    % MASKTOBOUNDINGBOX Derive a bounding box from a binary mask.
    %   bbox = maskToBoundingBox(mask, pad, imgSize) returns a bounding box
    %   [x, y, width, height] that encloses the mask with padding.
    %   Returns empty if the mask has no true pixels.

    if ~any(mask(:))
        bbox = [];
        return;
    end

    props = regionprops(mask, "BoundingBox");
    if isempty(props)
        bbox = [];
        return;
    end

    % Use the largest region's bounding box
    allBBox = vertcat(props.BoundingBox);
    areas = allBBox(:,3) .* allBBox(:,4);
    [~, maxIdx] = max(areas);
    bb = allBBox(maxIdx, :);

    % Add padding
    x = max(1, floor(bb(1)) - pad);
    y = max(1, floor(bb(2)) - pad);
    w = min(imgSize(2), ceil(bb(1) + bb(3)) + pad) - x;
    h = min(imgSize(1), ceil(bb(2) + bb(4)) + pad) - y;

    bbox = [x, y, w, h];
end
