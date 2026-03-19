%% Template: IBSI-Compliant Radiomics Feature Extraction
% Extract intensity, shape, and texture features from medical images using
% the radiomics object. Create radiomics(data, roi) FIRST, then call methods.
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
volumeFile = '';  % TODO: Path to volume data (NIfTI format)
maskFile = '';    % TODO: Path to ROI mask (same dimensions as volume)
outputDir = '';   % TODO: Path to save feature tables

%% Step 1: Load volume and ROI mask
V = niftiread(volumeFile);
info = niftiinfo(volumeFile);
voxelSize = info.PixelDimensions(1:3);
roi = logical(niftiread(maskFile));

assert(isequal(size(V), size(roi)), 'Volume and ROI dimensions must match.');
fprintf('Volume: [%s], ROI voxels: %d (%.1f%%)\n', ...
    num2str(size(V)), nnz(roi), 100 * nnz(roi) / numel(roi));

%% Step 2: Create the radiomics object
% R2025b: Create radiomics(data, roi) object FIRST, then call feature methods
radObj = radiomics(V, roi);
fprintf('Radiomics object created\n');

%% Step 3: Extract intensity (first-order) features
intensityFeats = intensityFeatures(radObj);
disp('=== Intensity Features ===');
disp(intensityFeats);

%% Step 4: Extract shape features
shapeFeats = shapeFeatures(radObj);
disp('=== Shape Features ===');
disp(shapeFeats);

%% Step 5: Extract texture features
textureFeats = textureFeatures(radObj);
disp('=== Texture Features ===');
disp(textureFeats);

%% Step 6: Combine all features into a single table
allFeatures = [intensityFeats, shapeFeats, textureFeats];
fprintf('Total features: %d (intensity: %d, shape: %d, texture: %d)\n', ...
    width(allFeatures), width(intensityFeats), width(shapeFeats), width(textureFeats));

%% Step 7: Add metadata columns for downstream analysis
% TODO: Customize metadata fields for your study
allFeatures.PatientID = "PATIENT_001";
allFeatures.Timepoint = "Baseline";
allFeatures.ROIName = "Tumor";
allFeatures.VoxelSize_mm = string(sprintf('[%.2f, %.2f, %.2f]', voxelSize));

metaCols = {'PatientID', 'Timepoint', 'ROIName', 'VoxelSize_mm'};
featureCols = setdiff(allFeatures.Properties.VariableNames, metaCols, 'stable');
allFeatures = allFeatures(:, [metaCols, featureCols]);

%% Step 8: Batch processing helper (multi-patient/multi-ROI)
% TODO: Uncomment and adapt for batch processing
% patientDirs = dir(fullfile(dataDir, 'Patient_*'));
% allPatientFeatures = table();
% for p = 1:length(patientDirs)
%     V_p = niftiread(fullfile(patientDirs(p).folder, patientDirs(p).name, 'volume.nii.gz'));
%     roi_p = logical(niftiread(fullfile(patientDirs(p).folder, patientDirs(p).name, 'mask.nii.gz')));
%     radObj_p = radiomics(V_p, roi_p);
%     feats_p = [intensityFeatures(radObj_p), shapeFeatures(radObj_p), textureFeatures(radObj_p)];
%     feats_p.PatientID = string(patientDirs(p).name);
%     allPatientFeatures = [allPatientFeatures; feats_p];
% end

%% Step 9: Visualize feature distributions
figure('Name', 'Radiomics Feature Overview');

subplot(1,3,1);
histogram(V(roi), 50); xlabel('Intensity'); ylabel('Count');
title('ROI Intensity Histogram');

subplot(1,3,2);
intNames = intensityFeats.Properties.VariableNames;
intVals = table2array(intensityFeats);
numShow = min(8, length(intNames));
barh(intVals(1:numShow));
set(gca, 'YTickLabel', intNames(1:numShow), 'YTick', 1:numShow);
title('Intensity Features');

subplot(1,3,3);
midSlice = round(size(V, 3) / 2);
imshow(V(:,:,midSlice), []); hold on;
contour(roi(:,:,midSlice), [0.5 0.5], 'r', 'LineWidth', 2); hold off;
title('ROI on Center Slice');

sgtitle('Radiomics Feature Extraction Summary');

%% Step 10: Export features for ML analysis
if ~isfolder(outputDir), mkdir(outputDir); end
writetable(allFeatures, fullfile(outputDir, 'radiomics_features.csv'));
save(fullfile(outputDir, 'radiomics_features.mat'), ...
    'allFeatures', 'intensityFeats', 'shapeFeats', 'textureFeats');
fprintf('Features saved to: %s\n', outputDir);
disp('=== Radiomics Feature Extraction Complete ===');
