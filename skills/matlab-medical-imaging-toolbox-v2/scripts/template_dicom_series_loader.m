%% Template: DICOM Series Loader
% Load and organize DICOM series from a directory using dicomCollection.
% Group by series, load selected series with dicomread, extract metadata.
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
dataDir = '';    % TODO: Path to your DICOM folder (e.g., '/data/patient001/')
outputDir = '';  % TODO: Path to save results (e.g., '/results/processed/')

%% Step 1: Scan the DICOM directory and build a collection
% dicomCollection recursively scans a folder and organizes all DICOM files
% into a structured table grouped by study and series.
collection = dicomCollection(dataDir);

% Display the collection summary
disp('=== DICOM Collection Summary ===');
disp(collection);
fprintf('Total series found: %d\n', height(collection));

%% Step 2: Inspect available series and select one to load
% Display key metadata columns for each series
seriesSummary = collection(:, {'PatientID', 'Modality', 'SeriesDescription', ...
    'SliceThickness', 'Rows', 'Columns', 'NumberOfFrames'});
disp('=== Series Summary ===');
disp(seriesSummary);

% TODO: Select the series index you want to load
seriesIdx = 1;  % TODO: Change to desired series index

%% Step 3: Load the selected DICOM series as a 3D volume
% Read pixel data from the selected series
V = dicomreadVolume(collection, seriesIdx);
V = squeeze(V);  % Remove singleton dimensions if present
fprintf('Volume size: [%s]\n', num2str(size(V)));

%% Step 4: Extract key metadata from the first file in the series
% Read DICOM header information
fileList = collection.Filenames{seriesIdx};
info = dicominfo(fileList{1});

% Extract clinically relevant metadata
metadata.PatientID = info.PatientID;
metadata.Modality = info.Modality;
metadata.StudyDate = info.StudyDate;
metadata.SeriesDescription = info.SeriesDescription;
metadata.SliceThickness = info.SliceThickness;
metadata.PixelSpacing = info.PixelSpacing;
metadata.Manufacturer = info.Manufacturer;
metadata.InstitutionName = info.InstitutionName;

disp('=== Extracted Metadata ===');
disp(metadata);

%% Step 5: Build spatial referencing and create medicalVolume
% Construct voxel spacing from metadata
voxelSpacing = [metadata.PixelSpacing(1), metadata.PixelSpacing(2), ...
    metadata.SliceThickness];

% Create spatial referencing object
R = medicalref3d(size(V), voxelSpacing);

% Create medicalVolume container for downstream processing
medVol = medicalVolume(V, R);
fprintf('Medical volume created with voxel size: [%.2f, %.2f, %.2f] mm\n', ...
    voxelSpacing(1), voxelSpacing(2), voxelSpacing(3));

%% Step 6: Quick visualization of loaded volume
% Display center slices along each axis
figure('Name', 'DICOM Volume - Center Slices');
centerSlice = round(size(V) / 2);

subplot(1,3,1);
imshow(squeeze(V(:,:,centerSlice(3))), []);
title('Axial');

subplot(1,3,2);
imshow(squeeze(V(:,centerSlice(2),:)), []);
title('Coronal');

subplot(1,3,3);
imshow(squeeze(V(centerSlice(1),:,:)), []);
title('Sagittal');

sgtitle(sprintf('Patient: %s | %s', metadata.PatientID, metadata.SeriesDescription));

%% Step 7: Save processed volume (optional)
% TODO: Uncomment to save the medicalVolume to a MAT file
% if ~isfolder(outputDir), mkdir(outputDir); end
% save(fullfile(outputDir, 'loaded_volume.mat'), 'medVol', 'metadata');
% fprintf('Volume saved to: %s\n', fullfile(outputDir, 'loaded_volume.mat'));

disp('=== DICOM Series Loading Complete ===');
