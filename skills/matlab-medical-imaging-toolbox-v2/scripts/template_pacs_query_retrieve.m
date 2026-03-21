%% Template: PACS Server Query and Retrieve
% Connect to a PACS server, query studies, and retrieve DICOM data.
% Uses dicomConnection, dicomquery, and dicomget for PACS integration.
% MATLAB R2025b | Medical Imaging Toolbox
%
% Usage:
%   1. Fill in all TODO sections with your PACS server details
%   2. Run section-by-section or as complete script
%
% Requirements:
%   - Medical Imaging Toolbox
%   - Network access to PACS server

%% TODO: Configure PACS connection and storage parameters
pacsHost = '';       % TODO: PACS server hostname or IP (e.g., '192.168.1.100')
pacsPort = 104;      % TODO: PACS server port (default: 104)
callingAET = '';     % TODO: Your local AE Title (e.g., 'MATLAB_SCU')
calledAET = '';      % TODO: PACS server AE Title (e.g., 'PACS_SCP')
outputDir = '';      % TODO: Local directory to store retrieved DICOM files

%% Step 1: Establish connection to PACS server
try
    conn = dicomConnection(pacsHost, pacsPort, ...
        'CallingAETitle', callingAET, 'CalledAETitle', calledAET);
    fprintf('Connected to PACS: %s:%d (AET: %s)\n', pacsHost, pacsPort, calledAET);
catch ME
    fprintf('ERROR: %s\nVerify hostname, port, AE Titles, and network access.\n', ME.message);
    return;
end

%% Step 2: Query at STUDY level
% TODO: Define search criteria (use '*' for wildcard, '' for any)
studyDate = '';        % TODO: e.g., '20240101-20241231' for date range
patientID = '';        % TODO: e.g., 'PATIENT001'
modality = '';         % TODO: e.g., 'CT', 'MR', 'PT'

queryAttrs = struct();
if ~isempty(studyDate), queryAttrs.StudyDate = studyDate; end
if ~isempty(patientID), queryAttrs.PatientID = patientID; end
if ~isempty(modality),  queryAttrs.ModalitiesInStudy = modality; end

try
    studyResults = dicomquery(conn, 'STUDY', queryAttrs);
    fprintf('Found %d studies\n', height(studyResults));
catch ME
    fprintf('Query failed: %s\n', ME.message); return;
end

if isempty(studyResults) || height(studyResults) == 0
    fprintf('No studies found. Adjust search criteria.\n'); return;
end
disp(studyResults(:, intersect(studyResults.Properties.VariableNames, ...
    {'PatientID', 'StudyDate', 'StudyDescription', 'ModalitiesInStudy'})));

%% Step 3: Query at SERIES level for a selected study
studyIdx = 1;  % TODO: Change to desired study index
seriesQuery = struct('StudyInstanceUID', studyResults.StudyInstanceUID{studyIdx});

try
    seriesResults = dicomquery(conn, 'SERIES', seriesQuery);
    fprintf('Found %d series in study %d\n', height(seriesResults), studyIdx);
catch ME
    fprintf('Series query failed: %s\n', ME.message); return;
end
disp(seriesResults(:, intersect(seriesResults.Properties.VariableNames, ...
    {'SeriesNumber', 'SeriesDescription', 'Modality'})));

%% Step 4: Retrieve selected series from PACS
seriesIdx = 1;  % TODO: Change to desired series index
retrieveDir = fullfile(outputDir, sprintf('study_%d_series_%d', studyIdx, seriesIdx));
if ~isfolder(retrieveDir), mkdir(retrieveDir); end

try
    dicomget(conn, seriesResults(seriesIdx, :), retrieveDir);
    fprintf('Retrieval complete to: %s\n', retrieveDir);
catch ME
    fprintf('Retrieval failed: %s\n', ME.message); return;
end

%% Step 5: Verify and load retrieved data
retrievedCollection = dicomCollection(retrieveDir);
fprintf('Retrieved %d file(s)\n', height(retrievedCollection));

if height(retrievedCollection) > 0
    V = squeeze(dicomreadVolume(retrievedCollection, 1));
    fprintf('Volume loaded: [%s]\n', num2str(size(V)));

    figure('Name', 'Retrieved PACS Data');
    midSlice = round(size(V, 3) / 2);
    imshow(V(:,:,midSlice), []);
    title(sprintf('Retrieved: %s (slice %d/%d)', ...
        seriesResults.SeriesDescription{seriesIdx}, midSlice, size(V, 3)));
end

%% Step 6: Batch query helper (multiple patients)
% TODO: Uncomment for batch querying
% patientList = {'PATIENT001', 'PATIENT002', 'PATIENT003'};
% allStudies = table();
% for p = 1:length(patientList)
%     try
%         results = dicomquery(conn, 'STUDY', struct('PatientID', patientList{p}));
%         allStudies = [allStudies; results];
%     catch ME
%         fprintf('Query failed for %s: %s\n', patientList{p}, ME.message);
%     end
% end

disp('=== PACS Query & Retrieve Complete ===');
