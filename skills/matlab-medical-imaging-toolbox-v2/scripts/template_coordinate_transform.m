%% Template: Patient/Voxel Coordinate Transforms
% Convert between voxel (intrinsic) and patient (world) coordinates.
% Uses medicalref3d with intrinsicToWorld and worldToIntrinsic.
% MATLAB R2025b | Medical Imaging Toolbox
%
% Usage:
%   1. Fill in all TODO sections with your data
%   2. Run section-by-section or as complete script
%
% Requirements:
%   - Medical Imaging Toolbox

%% TODO: Configure your data paths and parameters
volumeFile = '';   % TODO: Path to medical volume (NIfTI or DICOM)
outputDir = '';    % TODO: Path to save transformed coordinates

%% Step 1: Load volume and create spatial referencing
V = niftiread(volumeFile);
info = niftiinfo(volumeFile);
voxelSize = info.PixelDimensions(1:3);
R = medicalref3d(size(V), voxelSize);

fprintf('Volume: [%s] voxels, voxel size: [%.3f, %.3f, %.3f] mm\n', ...
    num2str(size(V)), voxelSize);

%% Step 2: Intrinsic (voxel) to world (patient) coordinate conversion
% R2025b: intrinsicToWorld(R, I, J, K) returns [X, Y, Z] as separate arrays
I_center = size(V, 1) / 2;
J_center = size(V, 2) / 2;
K_center = size(V, 3) / 2;

[X, Y, Z] = intrinsicToWorld(R, I_center, J_center, K_center);
fprintf('Center voxel [%.1f, %.1f, %.1f] -> World [%.2f, %.2f, %.2f] mm\n', ...
    I_center, J_center, K_center, X, Y, Z);

%% Step 3: Convert multiple voxel coordinates at once
% TODO: Replace with your coordinates of interest
I_pts = [1; 1; 1; size(V,1); size(V,1)];
J_pts = [1; 1; size(V,2); 1; size(V,2)];
K_pts = [1; size(V,3); 1; 1; size(V,3)];

[X_pts, Y_pts, Z_pts] = intrinsicToWorld(R, I_pts, J_pts, K_pts);
for p = 1:length(I_pts)
    fprintf('  Voxel [%6.1f, %6.1f, %6.1f] -> World [%8.2f, %8.2f, %8.2f] mm\n', ...
        I_pts(p), J_pts(p), K_pts(p), X_pts(p), Y_pts(p), Z_pts(p));
end

%% Step 4: World (patient) to intrinsic (voxel) conversion
[I_back, J_back, K_back] = worldToIntrinsic(R, X_pts, Y_pts, Z_pts);
maxError = max(abs([I_back - I_pts; J_back - J_pts; K_back - K_pts]));
fprintf('Round-trip error: %.2e (should be ~0)\n', maxError);

%% Step 5: Clinical coordinate mapping (e.g., tumor center)
% TODO: Replace with actual clinical coordinates (in mm)
tumorCenter_world_X = 50.0;  % TODO: X in mm
tumorCenter_world_Y = 75.0;  % TODO: Y in mm
tumorCenter_world_Z = 30.0;  % TODO: Z in mm

[tumorI, tumorJ, tumorK] = worldToIntrinsic(R, ...
    tumorCenter_world_X, tumorCenter_world_Y, tumorCenter_world_Z);
tumorVoxel = round([tumorI, tumorJ, tumorK]);

inBounds = all(tumorVoxel >= 1) && tumorVoxel(1) <= size(V,1) && ...
    tumorVoxel(2) <= size(V,2) && tumorVoxel(3) <= size(V,3);
fprintf('Tumor world [%.1f, %.1f, %.1f] -> voxel [%d, %d, %d], in bounds: %s\n', ...
    tumorCenter_world_X, tumorCenter_world_Y, tumorCenter_world_Z, ...
    tumorVoxel, string(inBounds));

%% Step 6: Physical distance measurement
% TODO: Define two points in voxel coordinates
I1 = 50; J1 = 60; K1 = 20;
I2 = 80; J2 = 90; K2 = 35;
[X1, Y1, Z1] = intrinsicToWorld(R, I1, J1, K1);
[X2, Y2, Z2] = intrinsicToWorld(R, I2, J2, K2);
physDist = sqrt((X2-X1)^2 + (Y2-Y1)^2 + (Z2-Z1)^2);
fprintf('Distance between points: %.2f mm\n', physDist);

%% Step 7: Orientation handling (RAS/LPS conventions)
% RAS (Right-Anterior-Superior) - NIfTI convention
% LPS (Left-Posterior-Superior) - DICOM convention
% RAS to LPS: flip X and Y axes
ras_to_lps = [-1 0 0; 0 -1 0; 0 0 1];
ras_point = [X, Y, Z];
lps_point = (ras_to_lps * ras_point')';
fprintf('RAS [%.2f, %.2f, %.2f] -> LPS [%.2f, %.2f, %.2f]\n', ras_point, lps_point);

%% Step 8: Visualize coordinate system
figure('Name', 'Coordinate System Visualization');
midSlice = round(size(V) / 2);

subplot(1,3,1);
imshow(squeeze(V(:,:,midSlice(3))), []);
hold on; plot(midSlice(2), midSlice(1), 'r+', 'MarkerSize', 20, 'LineWidth', 2); hold off;
title(sprintf('Axial (K=%d)', midSlice(3)));

subplot(1,3,2);
imshow(squeeze(V(:,midSlice(2),:)), []);
hold on; plot(midSlice(3), midSlice(1), 'r+', 'MarkerSize', 20, 'LineWidth', 2); hold off;
title(sprintf('Coronal (J=%d)', midSlice(2)));

subplot(1,3,3);
imshow(squeeze(V(midSlice(1),:,:)), []);
hold on; plot(midSlice(3), midSlice(2), 'r+', 'MarkerSize', 20, 'LineWidth', 2); hold off;
title(sprintf('Sagittal (I=%d)', midSlice(1)));

sgtitle('Coordinate System Reference');
disp('=== Coordinate Transform Template Complete ===');
